# Qt5 EGLFS Fix für Raspberry Pi 5

## Problem
Qt5 5.15.18 EGLFS wählt automatisch `/dev/dri/card0` (v3d 3D GPU), das kein KMS unterstützt.
Das führt zu: `drmModeGetResources failed (Operation not supported)`

## Root Cause
1. **Falsches DRM-Device**: Qt5 EGLFS nutzt card0 (v3d) statt card1 (vc4-drm Display Controller)
2. **DRM Master Lock**: Framebuffer Console blockiert DRM Master-Zugriff

## Lösung

### 1. Qt5 KMS Config-Datei
**Datei**: `/opt/crankshaft/qt5kms.json`
```json
{
  "device": "/dev/dri/card1",
  "hwcursor": false,
  "pbuffers": true,
  "separateScreens": true
}
```

**Integration**: 
- Kopiert via `stage3/03-crankshaft-base/01-run.sh`
- Environment Variable in `service_openauto.sh`: `export QT_QPA_EGLFS_KMS_CONFIG=/opt/crankshaft/qt5kms.json`

### 2. Kernel cmdline Parameter
**Datei**: `stage1/00-boot-files/files/cmdline.txt`

**Zusätzliche Parameter**:
```
video=HDMI-A-1:1920x1080@60 fbcon=map:0
```

**Zweck**:
- `video=HDMI-A-1:1920x1080@60`: Erzwingt explizite Modesetting für HDMI
- `fbcon=map:0`: Bindet fbcon an tty0, gibt card1 für Qt5 frei

### 3. DRM Render Node Permissions
**In service_openauto.sh**:
```bash
# Fix DRM render node permissions
if [ -e /dev/dri/renderD128 ]; then
    sudo chmod 666 /dev/dri/renderD128
fi
```

## Getestet
- ✅ Qt5 EGLFS findet jetzt card1 (vc4-drm)
- ✅ drmModeGetResources funktioniert
- ✅ HDMI1 Display erkannt (1920x1080)
- ✅ OpenAuto startet und erkennt Hardware
- ⚠️  DRM Master Permission noch zu lösen (benötigt Kernel cmdline Parameter)

## Nächster Build
Ein kompletter Build mit diesen Änderungen sollte das Problem vollständig lösen.

## Alternative: Atomic Modesetting
Falls DRM Master Problem persistiert, kann in `qt5kms.json` folgendes hinzugefügt werden:
```json
{
  "device": "/dev/dri/card1",
  "hwcursor": false,
  "pbuffers": true,
  "separateScreens": true,
  "useAtomicMode": false
}
```

## Debugging
```bash
# Qt5 mit vollem Debug:
QT_LOGGING_RULES='qt.qpa.*=true' QT_QPA_EGLFS_DEBUG=1 QT_QPA_EGLFS_KMS_CONFIG=/opt/crankshaft/qt5kms.json autoapp

# Teste drmModeGetResources direkt:
python3 -c "
import os, fcntl
DRM_IOCTL_MODE_GETRESOURCES = 0xC04064A0
fd = os.open('/dev/dri/card1', os.O_RDWR)
buf = bytearray(100)
fcntl.ioctl(fd, DRM_IOCTL_MODE_GETRESOURCES, buf)
print(f'Success: {buf[:50].hex()}')
"
```

## Status: 29. Dezember 2025
Änderungen committed und bereit für nächsten Build-Test.
