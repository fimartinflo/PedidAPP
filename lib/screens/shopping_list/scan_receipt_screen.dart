import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/shopping_list_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/receipt_parser_service.dart';
import '../../utils/app_theme.dart';

class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  final ReceiptParserService _parser = ReceiptParserService();
  final TextEditingController _listNameController = TextEditingController();

  File? _imageFile;
  ReceiptParseResult? _result;
  bool _isProcessing = false;
  String? _error;

  // Track which items are selected for the list
  late List<bool> _selectedItems;
  // Editable items
  late List<ReceiptItem> _editableItems;

  @override
  void dispose() {
    _listNameController.dispose();
    _parser.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() {
        _imageFile = File(picked.path);
        _isProcessing = true;
        _error = null;
        _result = null;
      });

      final result = await _parser.parseReceipt(_imageFile!);

      setState(() {
        _result = result;
        _editableItems = List.from(result.items);
        _selectedItems = List.filled(result.items.length, true);
        _isProcessing = false;
      });

      if (result.items.isEmpty) {
        setState(() {
          _error = 'No se encontraron productos en la boleta. '
              'Intenta con una foto mas clara o agrega items manualmente.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Error al procesar la imagen: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Boleta'),
        actions: [
          if (_result != null && _editableItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.visibility),
              tooltip: 'Ver texto completo',
              onPressed: () => _showRawText(context),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _result != null && _editableItems.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Procesando boleta...'),
            SizedBox(height: 8),
            Text(
              'Reconociendo texto y extrayendo productos',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return _buildImagePickerView();
    }

    return _buildResultsView();
  }

  Widget _buildImagePickerView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'Escanea una boleta de compra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Toma una foto de tu boleta o selecciona una imagen '
              'para crear una lista de compras automaticamente.',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: AppTheme.errorColor.withAlpha(25),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ImageSourceButton(
                  icon: Icons.camera_alt,
                  label: 'Camara',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 24),
                _ImageSourceButton(
                  icon: Icons.photo_library,
                  label: 'Galeria',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final selectedCount = _selectedItems.where((s) => s).length;

    return Column(
      children: [
        // Image preview
        if (_imageFile != null)
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.black12,
            child: Stack(
              children: [
                Center(
                  child: Image.file(_imageFile!, height: 120, fit: BoxFit.cover),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _result = null;
                      _imageFile = null;
                      _error = null;
                    }),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Otra foto'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppTheme.primaryColor.withAlpha(25),
          child: Row(
            children: [
              Text(
                '$selectedCount de ${_editableItems.length} productos seleccionados',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_result?.total != null)
                Text(
                  'Total boleta: \$${_result!.total!.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
            ],
          ),
        ),

        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _error!,
              style: const TextStyle(color: AppTheme.warningColor),
            ),
          ),

        // List name input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _listNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la lista',
              hintText: 'Ej: Compras supermercado',
              isDense: true,
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),

        // Items list
        Expanded(
          child: _editableItems.isEmpty
              ? Center(
                  child: Text(
                    'No se detectaron productos',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _editableItems.length,
                  itemBuilder: (context, index) {
                    final item = _editableItems[index];
                    return Card(
                      child: CheckboxListTile(
                        value: _selectedItems[index],
                        onChanged: (value) {
                          setState(() => _selectedItems[index] = value ?? false);
                        },
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: _selectedItems[index]
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Text(
                          '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} '
                          '${item.unit}'
                          '${item.price != null ? '  •  \$${item.price!.toStringAsFixed(2)}' : ''}',
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editItem(index),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = _selectedItems.where((s) => s).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: selectedCount > 0 ? _createList : null,
          icon: const Icon(Icons.shopping_cart),
          label: Text('Crear lista con $selectedCount productos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
    );
  }

  Future<void> _createList() async {
    final shopping = context.read<ShoppingListProvider>();
    final inventory = context.read<InventoryProvider>();

    final listName = _listNameController.text.trim().isEmpty
        ? 'Boleta escaneada'
        : _listNameController.text.trim();

    // Create the shopping list
    final list = await shopping.createShoppingList(
      name: listName,
      budgetLimit: _result?.total,
    );

    // Add selected items
    for (int i = 0; i < _editableItems.length; i++) {
      if (!_selectedItems[i]) continue;

      final item = _editableItems[i];

      // Try to match with existing product
      final matchedProduct = _findMatchingProduct(item.name, inventory);

      await shopping.addItemToList(
        listId: list.id,
        productId: matchedProduct?.id ?? 'scanned_${list.id}_$i',
        productName: item.name,
        categoryId: matchedProduct?.categoryId ?? inventory.categories.last.id,
        quantity: item.quantity,
        unit: matchedProduct?.unit ?? item.unit,
        estimatedPrice: item.price,
      );
    }

    if (mounted) {
      final selectedCount = _selectedItems.where((s) => s).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lista "$listName" creada con $selectedCount productos',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  /// Tries to match a scanned product name with existing inventory products.
  Product? _findMatchingProduct(String scannedName, InventoryProvider inventory) {
    final lower = scannedName.toLowerCase();
    for (final product in inventory.products) {
      final productLower = product.name.toLowerCase();
      if (productLower == lower ||
          productLower.contains(lower) ||
          lower.contains(productLower)) {
        return product;
      }
    }
    return null;
  }

  void _editItem(int index) {
    final item = _editableItems[index];
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(
      text: item.quantity.toStringAsFixed(
        item.quantity == item.quantity.roundToDouble() ? 0 : 1,
      ),
    );
    final priceController = TextEditingController(
      text: item.price?.toStringAsFixed(2) ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      prefixText: '\$ ',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Delete item
              setState(() {
                _editableItems.removeAt(index);
                _selectedItems.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              setState(() {
                _editableItems[index] = ReceiptItem(
                  name: newName,
                  quantity: double.tryParse(qtyController.text) ?? 1,
                  unit: item.unit,
                  price: double.tryParse(priceController.text),
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      qtyController.dispose();
      priceController.dispose();
    });
  }

  void _showRawText(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Texto reconocido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _result?.rawText ?? '',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
