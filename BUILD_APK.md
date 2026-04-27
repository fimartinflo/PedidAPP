# Guía para Compilar el APK de PedidAPP

> Proyecto preparado al 100% con archivos nativos Android generados, permisos configurados y todas las dependencias listas.
> Solo falta compilar el APK, lo cual requiere un entorno con acceso a `dl.google.com` y `maven.google.com`.

---

## Opción 1: Build Rápido (Local en tu PC)

### Prerequisitos
- **Flutter SDK 3.27+** (Dart 3.6+ requerido por pubspec.yaml)
- **Android SDK** con platform-34 y build-tools 34.0.0
- **Java JDK 17** (recomendado para Android Gradle Plugin 8.1.0)

### Instalación rápida de Flutter
```bash
# Linux/Mac:
cd $HOME
curl -L -o flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.4-stable.tar.xz
tar xf flutter.tar.xz
export PATH="$HOME/flutter/bin:$PATH"
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc

# Windows: descarga desde https://docs.flutter.dev/get-started/install/windows
# Mac: brew install --cask flutter
```

### Configurar Android SDK
```bash
# Opción A - Android Studio (recomendado):
# Descarga desde https://developer.android.com/studio
# Al instalar acepta SDK Platform 34 y Build Tools 34.0.0

# Opción B - Línea de comandos:
cd $HOME
mkdir -p android-sdk/cmdline-tools
cd android-sdk/cmdline-tools
curl -L -o tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip tools.zip && mv cmdline-tools latest && rm tools.zip

export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

### Compilar el APK
```bash
cd /ruta/a/PedidAPP

# Verifica entorno
flutter doctor

# Descarga dependencias
flutter pub get

# APK debug (para desarrollo y pruebas)
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk

# APK release (optimizado, más pequeño)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# APK release separado por arquitectura (más pequeños)
flutter build apk --split-per-abi --release
# → app-armeabi-v7a-release.apk (ARM 32-bit)
# → app-arm64-v8a-release.apk   (ARM 64-bit - recomendado para móviles modernos)
# → app-x86_64-release.apk       (emuladores x64)
```

### Instalar en tu dispositivo Android
```bash
# Habilita "Depuración USB" en tu celular (ver CLAUDE.md)
# Conecta por USB y acepta el diálogo

# Verifica que detecta el dispositivo
flutter devices

# Instala directamente
flutter install

# O pasa el APK al celular (por USB, Drive, WhatsApp, etc.)
# y ábrelo desde el celular para instalar
# NOTA: el celular pedirá activar "Instalar fuentes desconocidas" la primera vez
```

---

## Opción 2: GitHub Actions (Build en la Nube)

Si no quieres instalar Flutter localmente, puedes usar el workflow de GitHub Actions que construye el APK automáticamente en cada push.

### Cómo usar
1. Ve al repo en GitHub → **Actions**
2. Ejecuta el workflow "Build Android APK"
3. Descarga el artefacto "pedidapp-apk" cuando termine (~5 minutos)

> Workflow ya incluido en `.github/workflows/build-apk.yml`

---

## Configuración Actual del Proyecto

| Componente | Valor |
|---|---|
| Package ID | `com.fimartinflo.pedidapp` |
| Version | `1.0.0+1` (de `pubspec.yaml`) |
| Min SDK | 21 (Android 5.0 Lollipop) |
| Target SDK | 34 (Android 14) |
| Android Gradle Plugin | 8.1.0 |
| Kotlin | 1.8.22 |
| Gradle | 8.3 |

### Permisos Configurados en AndroidManifest.xml
- `POST_NOTIFICATIONS` - Alertas de stock bajo y recordatorios
- `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` - Recordatorios semanales programados
- `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE` - Notificaciones confiables
- `CAMERA` - Escaneo de boletas con OCR
- `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES` - Seleccionar imagen de boleta desde galería

---

## Firma Release (Producción)

Para publicar en Play Store o distribuir el APK oficialmente, debes firmarlo con tu propia llave:

```bash
# 1. Genera tu keystore (una sola vez)
keytool -genkey -v -keystore ~/pedidapp-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pedidapp

# 2. Crea android/key.properties (NO lo commitees)
cat > android/key.properties <<EOF
storePassword=TU_PASSWORD
keyPassword=TU_PASSWORD
keyAlias=pedidapp
storeFile=$HOME/pedidapp-release.jks
EOF

# 3. Edita android/app/build.gradle para usar tu keystore
# (Ver https://docs.flutter.dev/deployment/android#signing-the-app)

# 4. Compila firmado
flutter build apk --release
```

---

## Troubleshooting

| Problema | Solución |
|---|---|
| `flutter.sdk not set in local.properties` | Ejecuta `flutter pub get` primero |
| `cmdline-tools component is missing` | Instala Android SDK cmdline-tools |
| `Plugin [id: com.android.application] was not found` | Verifica acceso a internet y que Android SDK esté en PATH |
| `JAVA_HOME is not set` | `export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))` |
| Error NDK en primera build | Deja que descargue automáticamente (~500MB) |
| Build tarda mucho | Primera build ~10 min; siguientes ~1 min con hot reload |

Si persisten problemas, consulta `CLAUDE.md` sección "Solución de Problemas Comunes" o ejecuta `flutter doctor -v`.
