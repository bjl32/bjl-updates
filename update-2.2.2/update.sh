#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

die() {
    echo "Error occurred. Check log file for details." >&2
    exit 1
}

log_and_run() {
    echo "Running: $@" >> "$LOG_FILE"
    "$@" >> "$LOG_FILE" 2>&1 || die
}

# Set up logging
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="/BJLetc/logs/log-${TIMESTAMP}.log"
mkdir -p /BJLetc/logs

echo "Starting update script at $(date)" > "$LOG_FILE"

mkdir /sources
cd /sources
# Cleaning Up will Happen in the end of the script!

log_and_run wget https://www.x.org/pub/individual/util/util-macros-1.20.1.tar.xz
tar xf util-macros-1.20.1.tar.xz
cd util-macros-1.20.1
log_and_run ./configure $XORG_CONFIG
log_and_run make install
cd /sources

log_and_run wget https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2024.1.tar.xz
tar xf xorgproto-2024.1.tar.xz
cd xorgproto-2024.1
mkdir build &&
cd    build &&
log_and_run meson setup --prefix=$XORG_PREFIX ..
log_and_run ninja
log_and_run ninja install
mv -v $XORG_PREFIX/share/doc/xorgproto{,-2024.1}
cd /sources

log_and_run wget https://www.x.org/pub/individual/lib/libXau-1.0.11.tar.xz
tar xf libXau-1.0.11.tar.xz
cd libXau-1.0.11
log_and_run ./configure $XORG_CONFIG
log_and_run make
log_and_run make install
cd /sources

log_and_run wget https://xorg.freedesktop.org/archive/individual/proto/xcb-proto-1.17.0.tar.xz
tar xf xcb-proto-1.17.0.tar.xz
cd xcb-proto-1.17.0
log_and_run PYTHON=python3 ./configure $XORG_CONFIG
log_and_run make install
cd /sources

log_and_run wget https://www.x.org/pub/individual/lib/libXdmcp-1.1.5.tar.xz
tar xf libXdmcp-1.1.5.tar.xz
cd libXdmcp-1.1.5
log_and_run ./configure $XORG_CONFIG --docdir=/usr/share/doc/libXdmcp-1.1.5
log_and_run make
log_and_run make install
cd /sources

log_and_run wget https://xorg.freedesktop.org/archive/individual/lib/libxcb-1.17.0.tar.xz
tar xf libxcb-1.17.0.tar.xz
cd libxcb-1.17.0
log_and_run ./configure $XORG_CONFIG      \
            --without-doxygen \
            --docdir='${datadir}'/doc/libxcb-1.17.0
log_and_run make
log_and_run make install
cd /sources
rm -rf /sources/*

echo "Update script completed successfully at $(date)" >> "$LOG_FILE"
