class AppConstants {
  static const String appName = 'PedidAPP';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Organiza tus compras del hogar y controla tu stock';

  static const List<String> units = [
    'unidad',
    'kg',
    'g',
    'litro',
    'ml',
    'paquete',
    'caja',
    'docena',
    'lata',
    'botella',
    'bolsa',
    'rollo',
    'sobre',
  ];

  static const Map<String, String> stockStatusLabels = {
    'ok': 'Suficiente',
    'low': 'Stock Bajo',
    'out': 'Agotado',
  };

  static String getStockStatus(double current, double minimum) {
    if (current <= 0) return 'out';
    if (current <= minimum) return 'low';
    return 'ok';
  }
}
