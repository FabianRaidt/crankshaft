#!/bin/bash -eu

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_OPTS="$*"

DOCKER="docker"
if ! ${DOCKER} ps >/dev/null 2>&1; then
    DOCKER="sudo docker"
fi
if ! ${DOCKER} ps >/dev/null; then
    echo "error connecting to docker:"
    ${DOCKER} ps
    exit 1
fi

echo "Ensuring binfmt_misc and QEMU multiarch support..."

# Try without sudo first
if [ -w /proc/sys/fs/binfmt_misc ] || sudo -n true 2>/dev/null; then
    sudo modprobe binfmt_misc 2>/dev/null || true
    sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
fi

# Always reset qemu-user-static to ensure binfmt handlers are registered
${DOCKER} run --rm --privileged multiarch/qemu-user-static --reset -p yes >/dev/null

# Ensure work/deploy directories exist on host for bind mounts
mkdir -p "${DIR}/work" "${DIR}/deploy"

CONFIG_FILE=""
if [ -f "${DIR}/config" ]; then
    CONFIG_FILE="${DIR}/config"
fi

while getopts "c:" flag; do
    case "${flag}" in
        c) CONFIG_FILE="${OPTARG}" ;;
    esac
done

if command -v realpath >/dev/null 2>&1; then
    CONFIG_FILE=$(realpath -s "$CONFIG_FILE")
fi

if [ -z "${CONFIG_FILE}" ]; then
    echo "Configuration file must be present"
    exit 1
fi

source "${CONFIG_FILE}"

CONTAINER_NAME=${CONTAINER_NAME:-pigen_work}
CONTINUE=${CONTINUE:-0}
PRESERVE_CONTAINER=${PRESERVE_CONTAINER:-0}

# Remove stale container to avoid name conflicts
${DOCKER} rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

if [ -z "${IMG_NAME}" ]; then
    echo "IMG_NAME not set in config"
    exit 1
fi

GIT_HASH=$(git rev-parse HEAD)
GIT_BRANCH=$(git branch --show-current)

# ------------------------------------------------------------
# Build Image - Files mounted as volume, not copied
if ! ${DOCKER} image inspect pi-gen >/dev/null 2>&1; then
    ${DOCKER} build -t pi-gen "${DIR}"
else
    echo "pi-gen image already exists"
fi

# ------------------------------------------------------------
# RUN PI-GEN
# ------------------------------------------------------------
cleanup() {
    ${DOCKER} stop -t 5 "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}
trap cleanup SIGINT SIGTERM

time ${DOCKER} run --name "${CONTAINER_NAME}" --privileged \
    --volume "${CONFIG_FILE}":/config:ro \
    --volume "${DIR}/work":/pi-gen/work:rw \
    --volume "${DIR}/deploy":/pi-gen/deploy:rw \
    -e "GIT_HASH=${GIT_HASH}" \
    -e "GIT_BRANCH=${GIT_BRANCH}" \
    -e "CONTINUE=${CONTINUE}" \
    pi-gen \
    bash -e -o pipefail -c "
        mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc 2>/dev/null || true
        cd /pi-gen
        git config --global --add safe.directory '*'
        bash build.sh ${BUILD_OPTS}
    "

BUILD_EXIT=$?

if [ $BUILD_EXIT -eq 0 ]; then
    echo "✓ Build completed successfully"
    sudo chown -R $(id -u):$(id -g) deploy work 2>/dev/null || true
    ls -lh deploy/ 2>/dev/null
    find deploy work -name "*.img" -o -name "*.zip" 2>/dev/null | head -5
else
    echo "⚠ Build failed with exit code $BUILD_EXIT"
fi

${DOCKER} rm -v "${CONTAINER_NAME}" >/dev/null 2>&1 || true

exit $BUILD_EXIT