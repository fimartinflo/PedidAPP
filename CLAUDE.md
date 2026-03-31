# CLAUDE.md - PedidAPP

> Este archivo es la referencia principal del proyecto. Léelo antes de hacer cualquier cambio.

## Descripción

**PedidAPP** es una aplicación móvil multiplataforma (Android/iOS) construida con Flutter para la organización de compras del hogar y control de stock. Permite gestionar la despensa, generar listas de compras automáticas, recibir alertas de stock bajo y controlar el presupuesto mensual.

## Stack Técnico

| Tecnología | Propósito |
|---|---|
| **Flutter 3.6+** / **Dart 3.6+** | Framework multiplataforma |
| **Provider** (ChangeNotifier) | Gestión de estado |
| **sqflite** | Base de datos local SQLite |
| **flutter_local_notifications** | Notificaciones locales (stock bajo, presupuesto) |
| **fl_chart** | Gráficos de presupuesto (pendiente de implementar) |
| **intl** | Formato de fechas |
| **uuid** | Generación de IDs (UUID v4) |
| **shared_preferences** | Configuración de usuario |
| **permission_handler** | Permisos del sistema |

## Arquitectura

```
┌──────────────┐
│   Screens    │  ← UI (Material 3, Spanish)
├──────────────┤
│  Providers   │  ← Estado (ChangeNotifier + Consumer)
├──────────────┤
│  Services    │  ← Lógica de negocio (Singletons)
├──────────────┤
│   Models     │  ← Datos (toMap/fromMap/copyWith)
└──────────────┘
```

- **Patrón:** Provider con ChangeNotifier (NO Riverpod, NO BLoC)
- **Base de datos:** Singleton `DatabaseService` con sqflite
- **Notificaciones:** Singleton `NotificationService` con flutter_local_notifications
- **IDs:** UUID v4 para todas las entidades
- **Idioma UI:** Español (strings hardcodeados, sin i18n)
- **Tema:** Material Design 3 con soporte light/dark

## Estructura de Carpetas

```
lib/
├── main.dart                          # Punto de entrada, inicialización y MultiProvider
├── models/                            # Modelos de datos (clases Dart puras)
│   ├── budget.dart                    # MonthlyBudget - presupuesto mensual
│   ├── category.dart                  # Category - categorías (10 predefinidas)
│   ├── product.dart                   # Product - productos con stock
│   ├── shopping_item.dart             # ShoppingItem - item dentro de lista
│   └── shopping_list.dart             # ShoppingList - lista de compras
├── providers/                         # Gestión de estado
│   ├── budget_provider.dart           # BudgetProvider - presupuesto y gastos
│   ├── inventory_provider.dart        # InventoryProvider - productos y categorías
│   └── shopping_list_provider.dart    # ShoppingListProvider - listas de compras
├── screens/                           # Pantallas organizadas por feature
│   ├── budget/
│   │   └── budget_screen.dart         # Control de presupuesto mensual
│   ├── categories/
│   │   └── categories_screen.dart     # CRUD de categorías
│   ├── home/
│   │   └── home_screen.dart           # Dashboard + navegación bottom tabs
│   ├── inventory/
│   │   ├── add_product_screen.dart    # Formulario agregar producto
│   │   ├── inventory_screen.dart      # Lista de productos con filtros
│   │   └── product_detail_screen.dart # Detalle y edición de producto
│   ├── history/                       # (VACÍO - pendiente de implementar)
│   ├── settings/
│   │   └── settings_screen.dart       # Ajustes (notificaciones, tema)
│   └── shopping_list/
│       ├── shopping_list_detail_screen.dart  # Items de una lista
│       └── shopping_lists_screen.dart        # Listas activas/completadas
├── services/                          # Servicios singleton
│   ├── database_service.dart          # SQLite CRUD completo (5 tablas)
│   └── notification_service.dart      # Notificaciones locales
├── utils/                             # Utilidades
│   ├── app_theme.dart                 # Tema Material 3, colores, mapeo de íconos
│   └── constants.dart                 # Constantes, unidades, labels
├── widgets/                           # (VACÍO - pendiente de extraer widgets)
└── l10n/                              # (VACÍO - pendiente de internacionalización)
```

## Esquema de Base de Datos (SQLite v1)

```sql
-- Categorías de productos (10 predefinidas al crear BD)
categories (id TEXT PK, name TEXT, icon TEXT, color TEXT, sortOrder INTEGER)

-- Productos del inventario/despensa
products (id TEXT PK, name TEXT, categoryId TEXT FK→categories,
          unit TEXT, currentStock REAL, minimumStock REAL,
          estimatedPrice REAL, notes TEXT, barcode TEXT,
          createdAt TEXT, updatedAt TEXT)

-- Listas de compras
shopping_lists (id TEXT PK, name TEXT, createdAt TEXT,
                completedAt TEXT, status TEXT, budgetLimit REAL)

-- Items dentro de una lista
shopping_items (id TEXT PK, shoppingListId TEXT FK→shopping_lists,
                productId TEXT FK→products, productName TEXT,
                categoryId TEXT, quantity REAL, unit TEXT,
                estimatedPrice REAL, isPurchased INTEGER, actualPrice REAL,
                notes TEXT)

-- Presupuesto mensual
monthly_budgets (id TEXT PK, year INTEGER, month INTEGER,
                 budgetAmount REAL, spentAmount REAL, UNIQUE(year, month))
```

## Navegación

```
HomeScreen (Scaffold + BottomNavigationBar)
├── Tab 0: Dashboard (_DashboardView)
│   ├── Stats cards (productos, stock bajo, listas)
│   ├── Sección stock bajo → puede generar lista automática
│   ├── Listas activas con progreso
│   └── Presupuesto del mes
├── Tab 1: Despensa (InventoryScreen)
│   ├── Búsqueda + filtros categoría/estado
│   ├── ProductDetailScreen → editar/eliminar
│   └── AddProductScreen → formulario
├── Tab 2: Compras (ShoppingListsScreen)
│   ├── Tab Activas / Tab Completadas
│   └── ShoppingListDetailScreen → marcar items, compartir
├── Tab 3: Presupuesto (BudgetScreen)
│   ├── Presupuesto actual con indicador circular
│   └── Historial de meses anteriores
└── Tab 4: Ajustes (SettingsScreen)
    ├── Toggle notificaciones
    ├── Toggle modo oscuro
    └── Gestionar Categorías → CategoriesScreen
```

## Convenciones de Código

- **Comillas simples** para strings (enforced en `analysis_options.yaml`)
- **const constructors** preferidos donde sea posible
- **Archivos de pantalla** en `lib/screens/<feature>/<nombre>_screen.dart`
- **Modelos** con `toMap()`, `fromMap()` factory, `copyWith()`
- **IDs** con `Uuid().v4()` (nunca auto-increment)
- **Nombres** en inglés para código, español para UI
- **Moneda** con `\$` y `toStringAsFixed(2)`

## Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Hot reload (en terminal mientras corre)
r

# Hot restart
R

# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Compilar APK debug
flutter build apk --debug

# Compilar APK release
flutter build apk --release

# Compilar App Bundle (Google Play)
flutter build appbundle --release

# Compilar para iOS (requiere macOS)
flutter build ipa --release

# Verificar entorno
flutter doctor

# Generar configs nativos faltantes
flutter create --org com.fimartinflo --project-name pedidapp .
```

---

## Guía: Probar PedidAPP en Android (Emulador en PC)

### Prerrequisitos

1. **Sistema operativo:** Windows 10/11, macOS, o Linux
2. **RAM mínima:** 8 GB (16 GB recomendado para emulador fluido)
3. **Espacio en disco:** ~10 GB para Android Studio + SDK + emulador

### Opción A: Android Studio (Recomendado)

#### Paso 1: Instalar Android Studio
1. Descarga Android Studio desde https://developer.android.com/studio
2. Ejecuta el instalador y sigue el asistente
3. En la pantalla de componentes, asegúrate de seleccionar:
   - Android SDK
   - Android SDK Platform
   - Android Virtual Device (AVD)
4. Completa la instalación

#### Paso 2: Instalar Flutter SDK
1. Descarga Flutter SDK desde https://docs.flutter.dev/get-started/install
2. Extrae el archivo en una carpeta (ej: `C:\flutter` en Windows o `~/flutter` en Linux/Mac)
3. Agrega Flutter al PATH del sistema:
   - **Windows:** Configuración > Sistema > Variables de entorno > PATH > agregar `C:\flutter\bin`
   - **Linux/Mac:** Agrega a `~/.bashrc` o `~/.zshrc`:
     ```bash
     export PATH="$HOME/flutter/bin:$PATH"
     ```
4. Abre terminal y verifica:
   ```bash
   flutter --version
   ```

#### Paso 3: Configurar Android SDK
1. Abre Android Studio
2. Ve a **Settings/Preferences > Languages & Frameworks > Android SDK**
3. En la pestaña **SDK Platforms**: instala **Android 14 (API 34)** o superior
4. En la pestaña **SDK Tools**: instala:
   - Android SDK Build-Tools
   - Android SDK Command-line Tools
   - Android Emulator
   - Android SDK Platform-Tools
5. Acepta las licencias:
   ```bash
   flutter doctor --android-licenses
   ```

#### Paso 4: Crear Dispositivo Virtual (Emulador)
1. En Android Studio, abre **Device Manager** (icono de celular en la barra lateral)
2. Click en **Create Virtual Device**
3. Selecciona un dispositivo: **Pixel 7** (recomendado)
4. Selecciona imagen del sistema: **API 34** (o la más reciente con Play Store)
   - Si no aparece, click en **Download** junto a la imagen
5. Configura el nombre del AVD y click en **Finish**
6. Click en el botón **Play** (triangulo) para iniciar el emulador

#### Paso 5: Preparar el Proyecto
```bash
# Navega al directorio del proyecto
cd /ruta/a/PedidAPP

# IMPORTANTE: Genera los archivos nativos de Android/iOS
# (el proyecto actualmente solo tiene stubs)
flutter create --org com.fimartinflo --project-name pedidapp .

# Instala dependencias
flutter pub get

# Verifica que todo está configurado
flutter doctor
```

`flutter doctor` debe mostrar checkmarks verdes en:
- Flutter (el SDK)
- Android toolchain
- Android Studio
- Connected device (el emulador corriendo)

#### Paso 6: Ejecutar la App
```bash
# Con el emulador corriendo:
flutter run
```

La app se compilará y se instalará automáticamente en el emulador. Verás el Dashboard de PedidAPP.

#### Paso 7: Desarrollo con Hot Reload
- Presiona `r` en la terminal para **Hot Reload** (cambios instantáneos sin perder estado)
- Presiona `R` para **Hot Restart** (reinicia la app completa)
- Presiona `q` para detener la app

### Opción B: VS Code + Emulador

#### Paso 1: Instalar VS Code
1. Descarga VS Code desde https://code.visualstudio.com
2. Instala las extensiones:
   - **Flutter** (de Dart Code)
   - **Dart** (de Dart Code)

#### Paso 2: Configurar (mismo que Opción A, pasos 2-4)
Necesitas Flutter SDK, Android SDK y un emulador creado.

#### Paso 3: Ejecutar
1. Abre la carpeta del proyecto en VS Code
2. En la barra inferior, selecciona el dispositivo (emulador)
3. Presiona **F5** o ve a **Run > Start Debugging**
4. VS Code muestra logs en el panel de Debug Console

### Opción C: Dispositivo Físico Android

#### Paso 1: Preparar el Celular
1. Ve a **Configuración > Acerca del teléfono**
2. Toca **Número de compilación** 7 veces (activa Opciones de Desarrollador)
3. Ve a **Configuración > Opciones de desarrollador**
4. Activa **Depuración USB**

#### Paso 2: Conectar y Ejecutar
1. Conecta el celular por USB al PC
2. Acepta el diálogo de "Permitir depuración USB" en el celular
3. Verifica la conexión:
   ```bash
   flutter devices
   ```
4. Ejecuta:
   ```bash
   flutter run
   ```

### Solución de Problemas Comunes

| Problema | Solución |
|----------|----------|
| `flutter doctor` muestra X roja en Android | Instalar Android SDK y aceptar licencias con `flutter doctor --android-licenses` |
| Emulador muy lento | Habilitar aceleración por hardware (HAXM en Intel, Hyper-V en Windows) |
| "No connected devices" | Verificar que el emulador esté corriendo o el USB esté conectado |
| Error de Gradle al compilar | Ejecutar `flutter clean` y luego `flutter run` |
| Error de permisos en Linux | Agregar usuario al grupo `kvm`: `sudo adduser $USER kvm` |

---

## Roadmap de Mejoras

### Fase 1 - Funcionalidades Faltantes (Prioridad Alta)
- [ ] Pantalla de historial de compras (`lib/screens/history/history_screen.dart`)
- [ ] Widgets reutilizables (`lib/widgets/stock_indicator.dart`, `product_card.dart`, `empty_state.dart`, `category_avatar.dart`)
- [ ] Gráficos de presupuesto con fl_chart (barras mensuales, pastel por categoría)
- [ ] Conectar botón de notificaciones del Dashboard al historial

### Fase 2 - Mejoras de UX (Prioridad Media)
- [ ] Pantalla de onboarding para primera vez
- [ ] Compartir lista de compras por WhatsApp/SMS (share_plus)
- [ ] Búsqueda global en Dashboard
- [ ] Predicción de consumo (estimar cuándo se agotará un producto)

### Fase 3 - Testing (Prioridad Media)
- [ ] Tests unitarios para modelos (toMap, fromMap, copyWith, getters)
- [ ] Tests unitarios para providers (con inyección de dependencias)
- [ ] Tests de widgets para pantallas principales
- [ ] Refactorizar providers para aceptar servicios por constructor

### Fase 4 - Publicación (Prioridad Futura)
- [ ] Generar configs nativos con `flutter create .`
- [ ] Configurar AndroidManifest.xml (permisos de notificaciones)
- [ ] Configurar Info.plist para iOS
- [ ] Ícono de app con flutter_launcher_icons
- [ ] Splash screen con flutter_native_splash
- [ ] Política de privacidad (PRIVACY_POLICY.md)
- [ ] Firmar APK/AAB con keystore
- [ ] Screenshots y descripción para tiendas
- [ ] Publicar en Google Play Store
- [ ] Publicar en Apple App Store (requiere cuenta Developer $99/año)

---

## Changelog

### v1.0.0 (2026-03-31) - Initial Release
- Estructura completa del proyecto Flutter
- 5 modelos de datos: Product, Category, ShoppingList, ShoppingItem, MonthlyBudget
- Base de datos SQLite con 5 tablas y CRUD completo
- Notificaciones locales para stock bajo y alertas de presupuesto
- 3 providers: InventoryProvider, ShoppingListProvider, BudgetProvider
- 9 pantallas: Dashboard, Despensa, Agregar Producto, Detalle Producto, Listas de Compras, Detalle Lista, Presupuesto, Categorías, Ajustes
- Tema Material Design 3 con soporte light/dark
- 10 categorías predefinidas
- Generación automática de listas desde stock bajo
- Al completar compra: actualización automática de stock y registro de gasto
- Interfaz en español

### v1.0.1 (2026-03-31) - Documentation
- Creado CLAUDE.md con documentación completa del proyecto
- Guía paso a paso para probar en Android (emulador y dispositivo físico)
- Roadmap de mejoras organizado en 4 fases
