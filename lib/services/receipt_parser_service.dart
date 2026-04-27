import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf_text_extract/pdf_text_extract.dart' show PDFDoc;

/// Represents a single item parsed from a receipt.
class ReceiptItem {
  final String name;
  final double quantity;
  final String unit;
  final double? price;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    this.unit = 'unidad',
    this.price,
  });

  @override
  String toString() => '$name x$quantity ${price != null ? '\$$price' : ''}';
}

/// Result of parsing a receipt image.
class ReceiptParseResult {
  final List<ReceiptItem> items;
  final String rawText;
  final double? total;

  const ReceiptParseResult({
    required this.items,
    required this.rawText,
    this.total,
  });
}

/// Service that extracts text from receipt images and parses product lines.
class ReceiptParserService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Extracts text from an image file and parses receipt items.
  Future<ReceiptParseResult> parseReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final rawText = recognizedText.text;
    final items = _parseLines(recognizedText);
    final total = _extractTotal(rawText);

    return ReceiptParseResult(
      items: items,
      rawText: rawText,
      total: total,
    );
  }

  /// Parses recognized text blocks into receipt items.
  List<ReceiptItem> _parseLines(RecognizedText recognizedText) {
    final items = <ReceiptItem>[];

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        // Skip header/footer lines
        if (_isHeaderOrFooter(text)) continue;

        final item = _parseLine(text);
        if (item != null) {
          items.add(item);
        }
      }
    }

    return items;
  }

  /// Tries to parse a single line into a ReceiptItem.
  @visibleForTesting
  ReceiptItem? parseLine(String line) => _parseLine(line);

  ReceiptItem? _parseLine(String line) {
    // Normalize whitespace
    line = line.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Skip very short lines (likely not products)
    if (line.length < 3) return null;

    // Skip header/footer lines (RFC, dates, cajero, IVA, etc.)
    if (_isHeaderOrFooter(line)) return null;

    // Pattern 1: "PRODUCT NAME    $123.45" or "PRODUCT NAME   123.45"
    // Pattern 2: "2 x PRODUCT NAME    $123.45"
    // Pattern 3: "PRODUCT NAME  2x  $123.45"
    // Pattern 4: "PRODUCT NAME  2 UN  $123.45"

    double quantity = 1;
    String? unit;
    double? price;
    String name = line;

    // Extract price from end of line (with or without $ sign)
    final priceMatch = RegExp(
      r'[\$]?\s*(\d+[.,]\d{2})\s*$',
    ).firstMatch(name);
    if (priceMatch != null) {
      price = double.tryParse(
        priceMatch.group(1)!.replaceAll(',', '.'),
      );
      name = name.substring(0, priceMatch.start).trim();
    }

    // Extract quantity patterns: "2x", "2 x", "2 UN", "2 KG", etc.
    final qtyPrefixMatch = RegExp(
      r'^(\d+(?:[.,]\d+)?)\s*[xX×]\s*',
    ).firstMatch(name);
    if (qtyPrefixMatch != null) {
      quantity = double.tryParse(
            qtyPrefixMatch.group(1)!.replaceAll(',', '.'),
          ) ??
          1;
      name = name.substring(qtyPrefixMatch.end).trim();
    } else {
      // Check for quantity with unit at end: "PRODUCT 2 KG", "PRODUCT 500 GR"
      final qtySuffixMatch = RegExp(
        r'\s+(\d+(?:[.,]\d+)?)\s*(UN|KG|GR|LT|ML|PZ|PAQ|MT)\.?\s*$',
        caseSensitive: false,
      ).firstMatch(name);
      if (qtySuffixMatch != null) {
        quantity = double.tryParse(
              qtySuffixMatch.group(1)!.replaceAll(',', '.'),
            ) ??
            1;
        unit = _normalizeUnit(qtySuffixMatch.group(2)!);
        name = name.substring(0, qtySuffixMatch.start).trim();
      }
    }

    // Clean up name
    name = _cleanProductName(name);

    // Skip if name is empty or looks like a non-product line
    if (name.isEmpty || name.length < 2) return null;
    if (_looksLikeNonProduct(name)) return null;

    return ReceiptItem(
      name: name,
      quantity: quantity,
      unit: unit ?? 'unidad',
      price: price,
    );
  }

  /// Checks if a line is a receipt header/footer (store name, date, etc.)
  bool _isHeaderOrFooter(String text) {
    final lower = text.toLowerCase();
    final patterns = [
      RegExp(r'rfc\s*:', caseSensitive: false),
      RegExp(r'r\.?u\.?t\.?\s*:', caseSensitive: false),
      RegExp(r'tel[eé]?fono|tel\.?\s*:', caseSensitive: false),
      RegExp(r'direcci[oó]n|domicilio', caseSensitive: false),
      RegExp(r'factura|boleta|ticket|recibo|comprobante', caseSensitive: false),
      RegExp(r'\d{2}[/-]\d{2}[/-]\d{2,4}'), // dates
      RegExp(r'cajero|caja\s*\d', caseSensitive: false),
      RegExp(r'sucursal|tienda|local', caseSensitive: false),
      RegExp(r'gracias|vuelva', caseSensitive: false),
      RegExp(r'iva|impuesto|i\.v\.a', caseSensitive: false),
      RegExp(r'forma\s*de\s*pago|efectivo|tarjeta|cambio\s*:', caseSensitive: false),
      RegExp(r'^\*+$|^-+$|^=+$'), // separator lines
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(lower)) return true;
    }

    // Lines that are all numbers (receipt number, date codes, etc.)
    if (RegExp(r'^\d[\d\s\-/:.]+$').hasMatch(text)) return true;

    return false;
  }

  /// Checks if a cleaned name looks like a non-product line.
  bool _looksLikeNonProduct(String name) {
    final lower = name.toLowerCase();
    const skipWords = [
      'subtotal', 'total', 'descuento', 'vuelto', 'cambio',
      'efectivo', 'tarjeta', 'debito', 'credito', 'pago',
      'iva', 'impuesto', 'neto', 'bruto', 'redondeo',
      'gracias', 'vuelva',
    ];
    for (final word in skipWords) {
      if (lower == word || lower.startsWith('$word ')) return true;
    }
    return false;
  }

  /// Normalizes unit abbreviations to standard names.
  String _normalizeUnit(String raw) {
    switch (raw.toUpperCase()) {
      case 'KG':
        return 'kg';
      case 'GR':
        return 'gramo';
      case 'LT':
        return 'litro';
      case 'ML':
        return 'ml';
      case 'UN':
        return 'unidad';
      case 'PZ':
        return 'pieza';
      case 'PAQ':
        return 'paquete';
      case 'MT':
        return 'metro';
      default:
        return 'unidad';
    }
  }

  /// Cleans up a product name removing common noise.
  String _cleanProductName(String name) {
    // Remove leading/trailing special characters
    name = name.replaceAll(RegExp(r'^[\-\*\#\.\s]+|[\-\*\#\.\s]+$'), '');

    // Remove product codes (series of digits at start)
    name = name.replaceAll(RegExp(r'^\d{4,}\s*'), '');

    // Capitalize first letter of each word
    if (name.isNotEmpty) {
      name = name
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
          .join(' ');
    }

    return name.trim();
  }

  /// Extracts the total amount from receipt text.
  @visibleForTesting
  double? extractTotal(String text) => _extractTotal(text);

  double? _extractTotal(String text) {
    final totalMatch = RegExp(
      r'\btotal\s*[\$:]?\s*(\d+[.,]\d{2})',
      caseSensitive: false,
    ).firstMatch(text);

    if (totalMatch != null) {
      return double.tryParse(
        totalMatch.group(1)!.replaceAll(',', '.'),
      );
    }
    return null;
  }

  /// Parses a PDF receipt file by extracting its text content.
  Future<ReceiptParseResult> parsePdfReceipt(File pdfFile) async {
    final doc = await PDFDoc.fromFile(pdfFile);
    final rawText = await doc.text;

    final lines = rawText.split('\n');
    final items = <ReceiptItem>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_isHeaderOrFooter(trimmed)) continue;
      final item = _parseLine(trimmed);
      if (item != null) items.add(item);
    }

    final total = _extractTotal(rawText);
    return ReceiptParseResult(items: items, rawText: rawText, total: total);
  }

  /// Releases resources.
  void dispose() {
    _textRecognizer.close();
  }
}
