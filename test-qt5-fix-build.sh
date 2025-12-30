#!/bin/bash
# Quick test build für Qt5 EGLFS Fix Validierung

set -e

echo "=========================================="
echo "Qt5 EGLFS Fix Test Build"
echo "=========================================="
echo ""
echo "Dieser Build testet:"
echo "  1. qt5kms.json Installation nach /opt/crankshaft/"
echo "  2. QT_QPA_EGLFS_KMS_CONFIG Environment Variable"
echo "  3. cmdline.txt Parameter: video= und fbcon="
echo "  4. renderD128 Permissions Fix"
echo ""
echo "Erwartetes Ergebnis:"
echo "  - OpenAuto startet ohne 'drmModeGetResources failed'"
echo "  - HDMI Display wird erkannt"
echo "  - Qt5 nutzt /dev/dri/card1 (vc4-drm)"
echo ""

# Prüfe ob bereits ein Build läuft
if pgrep -f "build-docker.sh" > /dev/null; then
    echo "FEHLER: Ein Build läuft bereits!"
    exit 1
fi

# Cleanup
echo "Cleanup vorheriger Build-Artefakte..."
sudo rm -rf work deploy build-run.log
docker rm -f pigen_work 2>/dev/null || true
docker rmi pi-gen 2>/dev/null || true

# Starte Build
echo ""
echo "Starte Build..."
echo "Log: build-run-qt5-fix-test.log"
echo ""

bash build-docker.sh 2>&1 | tee build-run-qt5-fix-test.log

echo ""
echo "=========================================="
echo "Build abgeschlossen!"
echo "=========================================="
echo ""
echo "Nächste Schritte:"
echo "  1. Image flashen: deploy/*.img"
echo "  2. Pi 5 booten"
echo "  3. SSH verbinden"
echo "  4. Logs prüfen: /tmp/openauto.log"
echo "  5. Validation:"
echo "     - Kein 'drmModeGetResources failed' in Logs"
echo "     - 'Screen name: HDMI1' in Logs sichtbar"
echo "     - 'Screen geometry: 1920' in Logs sichtbar"
echo ""
echo "Debug Commands:"
echo "  cat /opt/crankshaft/qt5kms.json"
echo "  cat /boot/cmdline.txt | grep fbcon"
echo "  ls -la /dev/dri/"
echo "  dmesg | grep -E 'drm|vc4'"
echo ""
