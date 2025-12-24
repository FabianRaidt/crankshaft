# Raspberry Pi 5 Migration Roadmap

Um Crankshaft auf Pi 5 lauffähig zu machen, sind **umfangreiche Änderungen** notwendig:

## Erforderliche Änderungen

### 1. Basis-System Migration
- [ ] **Debian Buster → Bookworm** (oder Bullseye als Zwischenschritt)
- [ ] **32-bit ARMv7 → 64-bit ARM64** komplett umstellen
- [ ] Kernel 6.1+ (für Pi 5 Support)
- [ ] Neue Firmware (rpi-eeprom, Bootloader)

### 2. Build-System
- [ ] `Dockerfile`: Debian Bookworm arm64
- [ ] `stage0-4`: Alle Stages für arm64 anpassen
- [ ] `bootstrap`: arm64 statt armhf
- [ ] QEMU: aarch64 statt arm

### 3. Dependencies neu kompilieren
- [ ] **Qt5 für ARM64**: Komplett neu bauen
  - Aktuell: `Qt_5151_armv7l_OpenGLES2.tar.xz`
  - Benötigt: `Qt_5151_aarch64_OpenGLES2.tar.xz`
- [ ] **OpenAuto**: Für ARM64 kompilieren
- [ ] **Prebuilts**: Alle Binaries für ARM64
  - `gpio2kbd`
  - `cam_overlay`
  - `csmt` (Crankshaft Tool)

### 4. Hardware-Anpassungen
- [ ] `config.txt`: [pi5] Section hinzufügen
- [ ] Device-Tree-Overlays für Pi 5
- [ ] GPU-Treiber: VideoCore VII Support
- [ ] Audio: Neue ALSA-Konfiguration
- [ ] Bluetooth: Neue Firmware

### 5. Kernel-Module
- [ ] DKMS-Pakete für Kernel 6.1+
- [ ] USB-Gadget-Mode (für Android Auto)
- [ ] V4L2-Treiber (Kamera)

## Alternatives Vorgehen

### Option A: Pi 4 verwenden (empfohlen)
Crankshaft läuft **stabil auf Pi 4** - das ist aktuell die beste Wahl.

### Option B: Warten auf Community-Port
Das OpenCarDev-Projekt könnte Pi 5 Support hinzufügen.
Repository beobachten: https://github.com/opencardev/crankshaft

### Option C: Andere Android Auto Lösung
- **OpenAuto Pro**: Kommerzielle Lösung mit Pi 5 Support
- **Android Auto Wireless Adapter**: Fertige Hardware-Lösung

## Aufwandsschätzung

**~200-400 Entwicklungsstunden**:
- Basis-Migration: ~80h
- Qt5/Dependencies: ~120h
- Hardware/Treiber: ~80h
- Testing/Bugfixes: ~120h

## Technische Details

### ARM64 vs ARMv7
```bash
# Aktuell (ARMv7 32-bit)
debootstrap --arch armhf buster

# Benötigt (ARM64 64-bit)
debootstrap --arch arm64 bookworm
```

### Qt5 Build
```bash
# Neu kompilieren mit:
./configure -platform linux-g++ -device linux-rasp-pi5-v3d-g++ \
  -opengl es2 -optimize-size -release -prefix /usr/local/qt5
```

### config.txt Pi 5 Section
```ini
[pi5]
# Pi 5 spezifisch
kernel=kernel_2712.img
dtoverlay=vc4-kms-v3d-pi5
# Kein FKMS mehr, nur KMS
gpu_mem=128
```

## Fazit

**Aktuell nicht empfehlenswert** - zu großer Aufwand.
Nutze **Raspberry Pi 4** für Crankshaft.
