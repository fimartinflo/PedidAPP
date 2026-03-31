# PedidAPP

Aplicación móvil para la organización de compras del hogar y control de stock.

## Funcionalidades

- **Despensa/Inventario**: Gestión completa de productos con niveles de stock
- **Alertas de Stock Bajo**: Notificaciones automáticas cuando un producto está por agotarse
- **Lista de Compras**: Generación automática desde productos con stock bajo
- **Categorías**: Organización de productos por tipo (alimentos, limpieza, higiene, etc.)
- **Presupuesto Mensual**: Control de gastos con alertas al acercarse al límite
- **Historial**: Registro de compras completadas

## Tecnologías

- **Flutter** (Dart) - Framework multiplataforma
- **SQLite** (sqflite) - Base de datos local
- **Provider** - Gestión de estado
- **flutter_local_notifications** - Notificaciones locales
- **fl_chart** - Gráficos para presupuesto

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── models/                      # Modelos de datos
│   ├── budget.dart
│   ├── category.dart
│   ├── product.dart
│   ├── shopping_item.dart
│   └── shopping_list.dart
├── providers/                   # Gestión de estado
│   ├── budget_provider.dart
│   ├── inventory_provider.dart
│   └── shopping_list_provider.dart
├── screens/                     # Pantallas
│   ├── budget/
│   ├── categories/
│   ├── home/
│   ├── inventory/
│   ├── settings/
│   └── shopping_list/
├── services/                    # Servicios
│   ├── database_service.dart
│   └── notification_service.dart
├── utils/                       # Utilidades
│   ├── app_theme.dart
│   └── constants.dart
└── widgets/                     # Widgets reutilizables
```

## Requisitos

- Flutter SDK >= 3.6.0
- Dart SDK >= 3.6.0
- Android Studio / Xcode

## Instalación

```bash
# Clonar el repositorio
git clone https://github.com/fimartinflo/pedidapp.git
cd pedidapp

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Compilar APK para Android
flutter build apk --release

# Compilar para iOS
flutter build ios --release
```

## Publicación

### Google Play Store
```bash
flutter build appbundle --release
```

### Apple App Store
```bash
flutter build ipa --release
```

## Licencia

MIT
