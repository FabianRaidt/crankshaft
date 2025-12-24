# Crankshaft DevContainer

Dieser DevContainer bietet eine vollständige Entwicklungsumgebung für das Bauen und Entwickeln von Crankshaft.

## Features

- **Debian Buster Base**: Gleiche Umgebung wie für den Build
- **pi-gen Tools**: Alle notwendigen Dependencies für das Bauen von Raspberry Pi Images
- **ARM Emulation**: QEMU mit binfmt-support für ARM-Builds
- **Docker-in-Docker**: Docker-Socket gemountet für Image-Builds
- **apt-cacher-ng**: Paket-Cache für schnellere Builds
- **VS Code Extensions**: Shell-Script Entwicklung, Docker Support

## Voraussetzungen

1. Docker installiert
2. VS Code mit "Dev Containers" Extension
3. binfmt-support auf dem Host (für ARM-Emulation):
   ```bash
   sudo apt-get install binfmt-support qemu-user-static
   ```

## Verwendung

1. Repository in VS Code öffnen
2. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Warten bis der Container gebaut ist

### Crankshaft bauen

```bash
# Config erstellen (falls noch nicht vorhanden)
cp config.example config

# Direkter Build
sudo ./build.sh

# Oder Docker Build
./build-docker.sh
```

### Volumes

- `pi-gen-work`: Build-Artefakte (persistent)
- `pi-gen-deploy`: Fertige Images (persistent)
- `apt-cacher-data`: Paket-Cache (persistent)

## Ports

- **3142**: apt-cacher-ng (Paket-Cache)

## Troubleshooting

### ARM-Emulation funktioniert nicht

Auf dem Host ausführen:
```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Permission-Fehler

Der Container läuft als root, da pi-gen privilegierte Operationen benötigt.
