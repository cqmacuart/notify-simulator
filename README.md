# NotiSim — Simulador de Notificaciones Programadas

App Android en Flutter que dispara notificaciones locales programadas con la app **completamente cerrada**, sin internet y sin servidor.

---

## Requisitos

- Flutter 3.x, Dart 3.x
- Android SDK 21+
- Dispositivo o emulador Android (foco: **Xiaomi MIUI / HyperOS**)

## Dependencias clave

| Paquete | Uso |
|---|---|
| `flutter_local_notifications` | Núcleo de notificaciones y `zonedSchedule` |
| `timezone` | Zonas horarias correctas en `zonedSchedule` |
| `permission_handler` | Permisos de notificación y alarma exacta |
| `shared_preferences` | Persistencia de plantillas, variables y programadas |
| `path_provider` | Almacenamiento de imágenes/íconos |
| `image_picker` | Selección de imágenes del usuario |
| `device_info_plus` | Detección de fabricante para el banner MIUI |

---

## ⚠️ GUÍA CRÍTICA: Configuración en MIUI / HyperOS (Xiaomi)

> **Sin estos pasos, las notificaciones programadas NO llegarán con la app cerrada en Xiaomi.**
> Esto es una limitación del sistema operativo (MIUI mata procesos agresivamente), no un bug de la app.

### Paso 1 — Inicio automático (Autostart) [OBLIGATORIO]

1. Abre **Seguridad** (app del sistema de Xiaomi).
2. Ve a **Permisos** → **Inicio automático**.
3. Busca **NotiSim** y actívalo.

Sin este permiso, Android no puede despertar a la app para disparar alarmas en frío.

### Paso 2 — Batería sin restricciones [OBLIGATORIO]

1. Ve a **Ajustes** → **Batería y rendimiento** (o **Batería**).
2. Encuentra **NotiSim** en la lista de apps.
3. Selecciona **Sin restricciones**.

### Paso 3 — Bloquear en recientes [recomendado]

1. Abre el menú de apps recientes (botón cuadrado).
2. Mantén pulsada la tarjeta de NotiSim.
3. Toca el icono de **candado** (bloquear).

### Paso 4 — Permiso de alarma exacta (Android 12+)

La app solicita este permiso automáticamente. Si no aparece el diálogo:
- Ve a **Ajustes** → **Aplicaciones** → **NotiSim** → **Alarmas y recordatorios** → activar.

> La app intenta abrir automáticamente las pantallas de Autostart y Batería mediante
> botones en el banner naranja. Si el intent no funciona, sigue los pasos manuales de arriba.

---

## Cómo usar la app

### Crear variables

Las variables generan valores aleatorios **en el momento de programar** cada notificación (no al dispararse). Dos tipos:

**Dinero**: configura símbolo (`$`, `€`, `USD`…), rango (mín-máx), decimales y separador de miles.
`{valorMonetario}` → `$1,250.00`

**Serial**: configura prefijo, longitud y si es alfanumérico o solo numérico.
`{miSerial}` → `INV-A7K2`

### Crear plantillas

Una plantilla tiene:
- **Título** y **cuerpo** — soportan `{nombreVariable}` para insertar valores.
- **Ícono grande** (largeIcon) — imagen a color visible a la derecha de la notificación.
- **Imagen expandida** (bigPicture) — imagen grande al expandir la notificación (BigPictureStyle).
- **Nombre de app** — texto en el campo `subText` bajo el nombre de la notificación.

Ejemplo de cuerpo: `Your earnings: {valorMonetario} - {miSerial}`

### Botones de acción

- **Probar** — Envía una notificación inmediata (preview, app abierta).
- **Generar** — Abre el selector de cuándo enviar:
  - **Ahora**: notificación inmediata.
  - **Hora fija**: selecciona fecha y hora local; se agenda con `zonedSchedule + exactAllowWhileIdle`. Sobrevive a app cerrada (con config MIUI activa).
  - **Aleatorias**: define ventana de tiempo y cantidad. La app pre-calcula N instantes aleatorios y registra N alarmas exactas individuales. Sin timers, sin procesos vivos — la app puede cerrarse inmediatamente.

### Ver y cancelar programadas

Toca el icono de reloj en la barra superior. Muestra pendientes y pasadas. Puedes cancelar individualmente o todas.

---

## Restricciones de plataforma — límites del OS

### El ícono pequeño de la barra de estado no se puede personalizar a color

El pequeño ícono que aparece en la barra de estado es un recurso monocromático compilado en el APK. No es posible inyectar un PNG a color en runtime ni suplantar el aspecto de otra app en la barra de estado. Lo que SÍ es personalizable a color:
- **Ícono grande** (derecha de la notificación) → `largeIcon` con `FilePathAndroidBitmap`.
- **Imagen expandida** → `BigPictureStyle`.

### El valor de las variables se congela al programar

Como la notificación se construye antes de que el sistema la dispare (la app está cerrada cuando dispara), el valor de cada variable se genera y se fija en el momento de programar. Si programas 10 aleatorias, cada una recibe su propio valor generado al agendar.

### Las alarmas no sobreviven a un reinicio del teléfono sin Autostart

Android elimina todas las alarmas al reiniciar. La app registra un `ScheduledNotificationBootReceiver` que re-programa automáticamente al arrancar — pero solo funciona si el **Autostart está activo** en MIUI.

### Sin internet ni servidor

Todo funciona mediante `flutter_local_notifications` + `timezone` de forma completamente local. No se usa FCM, VAPID, ni ningún push remoto.

---

## Compilar y ejecutar

```bash
cd noti_sim
flutter pub get
flutter run            # dispositivo Android conectado
flutter build apk --release
```

---

## Estructura del proyecto

```
lib/
  main.dart                       # Init de timezone / storage / notifications
  models/
    variable_model.dart           # VariableModel (money/serial) + generación
    template_model.dart           # TemplateModel con paths de imagen
    scheduled_notification.dart   # ScheduledNotification persistida
    schedule_result.dart          # Resultado del diálogo de programación
  services/
    notification_service.dart     # zonedSchedule, exactAllowWhileIdle, aleatorias
    storage_service.dart          # shared_preferences CRUD
    miui_service.dart             # Detección MIUI + intents a ajustes del fabricante
  screens/
    home_screen.dart              # Pantalla principal
    template_editor_screen.dart
    variable_editor_screen.dart
    scheduled_list_screen.dart
  widgets/
    miui_banner.dart              # Banner naranja de configuración MIUI
    permission_card.dart          # Estado de permisos del sistema
    template_card.dart            # Tarjeta con Probar / Generar
    variable_chip.dart            # Chip editable de variable
    schedule_dialog.dart          # Diálogo ahora / hora fija / aleatorias
android/app/src/main/
  AndroidManifest.xml             # POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM,
                                  # USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED
  kotlin/.../MainActivity.kt      # MethodChannel para intents MIUI
```
