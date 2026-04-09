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
| **share_plus** | Compartir listas por WhatsApp/SMS |
| **image_picker** | Captura/selección de imágenes (cámara/galería) |
| **google_mlkit_text_recognition** | OCR on-device para lectura de boletas |

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
│   ├── list_template.dart             # ListTemplate + TemplateItem - plantillas reutilizables
│   ├── price_record.dart              # PriceRecord - historial de precios por producto
│   ├── product.dart                   # Product - productos con stock
│   ├── shopping_item.dart             # ShoppingItem - item dentro de lista
│   └── shopping_list.dart             # ShoppingList - lista de compras
├── providers/                         # Gestión de estado
│   ├── budget_provider.dart           # BudgetProvider - presupuesto y gastos
│   ├── inventory_provider.dart        # InventoryProvider - productos y categorías
│   ├── shopping_list_provider.dart    # ShoppingListProvider - listas de compras
│   └── theme_provider.dart            # ThemeProvider - modo oscuro persistente
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
│   ├── consumption/
│   │   └── consumption_screen.dart    # Predicción y analytics de consumo
│   ├── history/
│   │   └── history_screen.dart        # Historial de compras completadas
│   ├── settings/
│   │   └── settings_screen.dart       # Ajustes (notificaciones, tema, recordatorios)
│   └── shopping_list/
│       ├── scan_receipt_screen.dart          # Escaneo de boletas con OCR
│       ├── shopping_list_detail_screen.dart  # Items de una lista, guardar plantilla
│       └── shopping_lists_screen.dart        # Listas activas/completadas/plantillas
├── services/                          # Servicios singleton
│   ├── database_service.dart          # SQLite CRUD completo (8 tablas)
│   ├── notification_service.dart      # Notificaciones locales + recordatorios programados
│   └── receipt_parser_service.dart    # OCR y parseo de boletas de compra
├── utils/                             # Utilidades
│   ├── app_theme.dart                 # Tema Material 3, colores, mapeo de íconos
│   └── constants.dart                 # Constantes, unidades, labels
│   ├── onboarding/
│   │   └── onboarding_screen.dart     # Pantalla de bienvenida (primera vez)
├── widgets/                           # Widgets reutilizables
│   ├── category_avatar.dart           # Avatar circular de categoría
│   ├── empty_state.dart               # Estado vacío genérico
│   ├── global_search.dart             # Búsqueda global (SearchDelegate)
│   ├── product_card.dart              # Card de producto reutilizable
│   ├── section_header.dart            # Encabezado de sección
│   ├── stat_card.dart                 # Card de estadística
│   └── stock_indicator.dart           # Indicador visual de stock
└── l10n/                              # (VACÍO - pendiente de internacionalización)

test/
├── helpers/
│   ├── fake_database_service.dart     # Fake in-memory de DatabaseService
│   └── fake_notification_service.dart # Fake de NotificationService
├── models/
│   ├── budget_test.dart               # Tests MonthlyBudget
│   ├── category_test.dart             # Tests Category
│   ├── consumption_log_test.dart      # Tests ConsumptionLog
│   ├── list_template_test.dart        # Tests ListTemplate y TemplateItem
│   ├── price_record_test.dart         # Tests PriceRecord
│   ├── product_test.dart              # Tests Product
│   └── shopping_list_test.dart        # Tests ShoppingItem y ShoppingList
└── providers/
    ├── budget_provider_test.dart       # Tests BudgetProvider
    ├── inventory_provider_test.dart    # Tests InventoryProvider
    └── shopping_list_provider_test.dart # Tests ShoppingListProvider
```

## Esquema de Base de Datos (SQLite v4)

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

-- Logs de consumo (para predicción)
consumption_logs (id TEXT PK, productId TEXT FK→products,
                  quantity REAL, timestamp TEXT)

-- Historial de precios por producto (v3)
price_history (id TEXT PK, productId TEXT FK→products,
               price REAL, date TEXT, source TEXT)

-- Plantillas de listas reutilizables (v4)
list_templates (id TEXT PK, name TEXT, createdAt TEXT)

-- Items de plantilla (v4)
template_items (id TEXT PK, templateId TEXT FK→list_templates,
                productId TEXT, productName TEXT, categoryId TEXT,
                quantity REAL, unit TEXT, estimatedPrice REAL)
```

## Navegación

```
HomeScreen (Scaffold + BottomNavigationBar)
├── Tab 0: Dashboard (_DashboardView)
│   ├── Búsqueda global (SearchDelegate)
│   ├── Acceso a ConsumptionScreen (botón predicción)
│   ├── Acceso a HistoryScreen (botón historial)
│   ├── Stats cards (productos, stock bajo, listas)
│   ├── Sección stock bajo → puede generar lista automática
│   ├── Listas activas con progreso
│   └── Presupuesto del mes
├── Tab 1: Despensa (InventoryScreen)
│   ├── Búsqueda + filtros categoría/estado
│   ├── ProductDetailScreen → editar/eliminar
│   └── AddProductScreen → formulario
├── Tab 2: Compras (ShoppingListsScreen)
│   ├── Tab Activas / Tab Completadas / Tab Plantillas
│   ├── ScanReceiptScreen → escanear boleta con OCR, crear lista automática
│   └── ShoppingListDetailScreen → marcar items, compartir, guardar plantilla
├── Tab 3: Presupuesto (BudgetScreen)
│   ├── Presupuesto actual con indicador circular
│   └── Historial de meses anteriores
└── Tab 4: Ajustes (SettingsScreen)
    ├── Toggle notificaciones
    ├── Toggle modo oscuro
    ├── Recordatorio semanal (día + hora)
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

### Fase 1 - Funcionalidades Faltantes (Completada v1.1.0)
- [x] Pantalla de historial de compras (`lib/screens/history/history_screen.dart`)
- [x] Widgets reutilizables (`lib/widgets/stock_indicator.dart`, `product_card.dart`, `empty_state.dart`, `category_avatar.dart`, `stat_card.dart`, `section_header.dart`)
- [x] Gráficos de presupuesto con fl_chart (barras mensuales, pastel por categoría)
- [x] Conectar botón del Dashboard al historial de compras

### Fase 2 - Mejoras de UX (Completada v1.1.0)
- [x] Pantalla de onboarding para primera vez
- [x] Compartir lista de compras por WhatsApp/SMS (share_plus)
- [x] Búsqueda global en Dashboard (productos y listas)
- [x] Predicción de consumo (estimar cuándo se agotará un producto)

### Fase 3 - Testing (Completada v1.2.0)
- [x] Tests unitarios para modelos (toMap, fromMap, copyWith, getters)
- [x] Tests unitarios para providers (con inyección de dependencias)
- [x] Refactorizar providers para aceptar servicios por constructor
- [x] Fakes de DatabaseService y NotificationService para testing
- [x] Política de privacidad (PRIVACY_POLICY.md)
- [ ] Tests de widgets para pantallas principales (requiere entorno Flutter)

### Fase 3.5 - Funcionalidades Avanzadas (Completada v1.5.0)
- [x] Historial de precios por producto con tendencias
- [x] Plantillas de listas reutilizables
- [x] Recordatorios semanales programados
- [x] Tests unitarios para nuevos modelos (PriceRecord, ListTemplate, TemplateItem)

### Fase 4 - Publicación (Prioridad Futura)
- [ ] Generar configs nativos con `flutter create .`
- [ ] Configurar AndroidManifest.xml (permisos de notificaciones)
- [ ] Configurar Info.plist para iOS
- [ ] Ícono de app con flutter_launcher_icons
- [ ] Splash screen con flutter_native_splash
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

### v1.1.0 (2026-03-31) - Fase 1 y 2: Features y UX
**Fase 1 - Funcionalidades Faltantes:**
- Pantalla de historial de compras con filtros (este mes, mes pasado, todas)
- 7 widgets reutilizables: StockIndicator, ProductCard, EmptyState, CategoryAvatar, StatCard, SectionHeader, GlobalSearch
- Gráficos de presupuesto con fl_chart: barras comparativas mensuales y pastel por categoría
- Botón de historial en Dashboard conectado a HistoryScreen
- Query `getSpendingByCategory()` en DatabaseService para gráficos

**Fase 2 - Mejoras de UX:**
- Pantalla de onboarding (4 slides) para primera vez, con SharedPreferences
- Compartir lista de compras formateada por WhatsApp/SMS/etc (share_plus)
- Búsqueda global en Dashboard (SearchDelegate) buscando en productos y listas
- Predicción de consumo: tabla consumption_logs, consumo diario promedio, estimación días hasta agotamiento
- DB migrada a v2 con tabla consumption_logs
- Refactorizado home_screen.dart para usar widgets reutilizables

### v1.2.0 (2026-04-01) - Fase 3: Testing y Preparación
**Testing:**
- Tests unitarios para 5 modelos: Product, Category, MonthlyBudget, ShoppingItem/ShoppingList, ConsumptionLog
- Tests unitarios para 3 providers: InventoryProvider, ShoppingListProvider, BudgetProvider
- Refactorización de providers para inyección de dependencias (constructor injection)
- Servicios testables: DatabaseService.forTesting() y NotificationService.forTesting()
- FakeDatabaseService (in-memory) y FakeNotificationService para tests

**Preparación para publicación:**
- Política de privacidad (PRIVACY_POLICY.md)

### v1.3.0 (2026-04-07) - Correcciones y Analytics
**Correcciones de prioridad alta:**
- Modo oscuro funcional con ThemeProvider y persistencia en SharedPreferences
- Presupuesto conectado automáticamente al completar listas de compras
- Diálogo de precio real al marcar item como comprado
- Resumen de lista muestra "Gastado" en tiempo real
- SnackBar de confirmación al completar lista con monto registrado

**Nuevas funcionalidades:**
- Pantalla de predicción de consumo (ConsumptionScreen) accesible desde Dashboard
- Cards por producto con: consumo diario, días hasta agotarse, barra de stock
- Chips de estado: OK, Bajo, Pronto, Critico, Agotado
- Resumen general: total productos, stock bajo, agotados

### v1.4.0 (2026-04-08) - Escaneo de Boletas
**Nueva funcionalidad:**
- Escaneo de boletas de compra con OCR (Google ML Kit, on-device)
- Captura desde cámara o selección de galería (image_picker)
- ReceiptParserService: extrae productos, cantidades, precios y total
- Reconoce formatos comunes: "2x Producto $123.45", unidades (KG, LT, UN, etc.)
- Filtrado inteligente de headers/footers de boleta (RFC, fecha, cajero, etc.)
- Pantalla de revisión: seleccionar/deseleccionar items, editar nombre/cantidad/precio
- Vista del texto OCR completo para referencia
- Matching automático con productos existentes en inventario
- Botón de escaneo en pantalla de Listas de Compras (FAB secundario)

### v1.4.1 (2026-04-08) - Plan de Pruebas y Correcciones
**Bugs corregidos:**
- updateItemActualPrice: eliminado acceso raw DB en provider, movido a DatabaseService.updateShoppingItemActualPrice()
- Race condition en _onToggleItem: precio real ahora se persiste antes de marcar item como comprado

**Nuevos tests (plan de pruebas):**
- 35 tests para ReceiptParserService: extracción de precios, cantidades, unidades, filtrado de headers/footers, extractTotal
- Tests para updateItemActualPrice en ShoppingListProvider (precio real → totalActual)
- Tests para generateFromLowStock (lista vacía, nombre personalizado)
- Tests para completeList (completedAt timestamp)
- Tests para updateProduct, getProductsByCategory, outOfStockProducts, decrementStock+consumptionLog en InventoryProvider

### v1.5.0 (2026-04-09) - Historial de Precios, Plantillas y Recordatorios
**Historial de precios por producto:**
- Modelo PriceRecord con source tracking (manual, shopping_list, receipt)
- DB v3→v4 con tabla price_history
- InventoryProvider.recordPrice() auto-actualiza estimatedPrice
- Detalle de producto muestra últimos 5 precios con indicador de tendencia (↑↓→)
- Al completar lista de compras se registran precios en historial
- Tests unitarios para PriceRecord (8 tests)

**Plantillas de listas reutilizables:**
- Modelos ListTemplate y TemplateItem
- DB v4 con tablas list_templates y template_items
- Tab "Plantillas" en pantalla de Listas de Compras
- Guardar cualquier lista como plantilla (botón bookmark en detalle)
- Crear nueva lista desde plantilla con nombre y presupuesto personalizable
- Preview de plantilla: productos, total estimado, items destacados
- Tests unitarios para ListTemplate y TemplateItem (15 tests)

**Recordatorios semanales programados:**
- ShoppingReminder modelo con día de semana y hora
- NotificationService: schedule/cancel weekly reminders (periodicallyShow)
- Sección de recordatorios en pantalla de Ajustes
- Selector de día (Lunes-Domingo) y selector de hora
- Config persistida en SharedPreferences
- Se deshabilita automáticamente si notificaciones están apagadas
