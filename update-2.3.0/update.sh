#!/bin/bash
# lar stands for log_and_run
# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

die() {
    echo "Error occurred. Check log file for details." >&2
    exit 1
}

lar() {
    echo "Running: $@" >> "$LOG_FILE"
    "$@" >> "$LOG_FILE" 2>&1 || die
}
# udir: update directory: /tmp/bjlud
export udir='/tmp/bjlud'

# Set up logging
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="/BJLetc/logs/log-${TIMESTAMP}.log"
mkdir -p /BJLetc/logs

echo "Starting update script at $(date)" > "$LOG_FILE"
lar mkdir -v /tmp/bjlud
lar rm -rf /tmp/bjlud/*
cd /tmp/bjlud

log_and_run wget https://dbus.freedesktop.org/releases/dbus/dbus-1.14.10.tar.xz
lar tar -xf dbus-1.14.10.tar.xz
lar cd dbus-1.14.10
lar ./configure --prefix=/usr                        \
            --sysconfdir=/etc                    \
            --localstatedir=/var                 \
            --runstatedir=/run                   \
            --enable-user-session                \
            --disable-doxygen-docs               \
            --disable-xml-docs                   \
            --disable-static                     \
            --docdir=/usr/share/doc/dbus-1.14.10  \
            --with-system-socket=/run/dbus/system_bus_socket &&
lar make
lar make install
cat > /etc/dbus-1/session-local.conf << "EOF"
<!DOCTYPE busconfig PUBLIC
 "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
 "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>

  <!-- Search for .service files in /usr/local -->
  <servicedir>/usr/local/share/dbus-1/services</servicedir>

</busconfig>
EOF

cd $udir
lar wget https://download.gnome.org/sources/gsettings-desktop-schemas/46/gsettings-desktop-schemas-46.1.tar.xz
lar tar -xf gsettings-desktop-schemas-46.1.tar.xz
lar cd gsettings-desktop-schemas-46.1
sed -i -r 's:"(/system):"/org/gnome\1:g' schemas/*.in &&

mkdir build &&
cd    build &&

lar meson setup --prefix=/usr --buildtype=release .. &&
lar ninja
lar ninja install

cd $udir
lar wget https://download.gnome.org/sources/at-spi2-core/2.52/at-spi2-core-2.52.0.tar.xz
lar tar -xf at-spi2-core-2.52.0.tar.xz
lar cd at-spi2-core-2.52.0
mkdir build &&
cd    build &&

lar meson setup --prefix=/usr --buildtype=release .. &&
lar ninja
lar ninja install

cd $udir
lar wget https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/nasm-2.16.03.tar.xz
lar tar -xf nasm-2.16.03.tar.xz
lar cd nasm-2.16.03
lar ./configure --prefix=/usr &&
lar make
lar make install

cd $udir
lar wget https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz
lar tar -xf yasm-1.3.0.tar.gz
lar cd yasm-1.3.0
sed -i 's#) ytasm.*#)#' Makefile.in &&

lar ./configure --prefix=/usr &&
lar make
lar make install
cd $udir

lar wget https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-3.0.1.tar.gz
lar tar -xf libjpeg-turbo-3.0.1.tar.gz
lar cd libjpeg-turbo-3.0.1
lar mkdir build &&
cd    build &&

lar cmake -D CMAKE_INSTALL_PREFIX=/usr        \
      -D CMAKE_BUILD_TYPE=RELEASE         \
      -D ENABLE_STATIC=FALSE              \
      -D CMAKE_INSTALL_DEFAULT_LIBDIR=lib \
      -D CMAKE_SKIP_INSTALL_RPATH=ON      \
      -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/libjpeg-turbo-3.0.1 \
      .. &&
lar make
lar make install

cd $udir
lar wget https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/2.4/shared-mime-info-2.4.tar.gz
lar tar -xf shared-mime-info-2.4.tar.gz
lar cd shared-mime-info-2.4
tar -xf ../xdgmime.tar.xz &&
make -C xdgmime
mkdir build &&
cd    build &&

lar meson setup --prefix=/usr --buildtype=release -D update-mimedb=true .. &&
lar ninja
lar ninja install

cd $udir
lar wget https://www.cairographics.org/releases/pixman-0.43.4.tar.gz
lar tar -xf pixman-0.43.4.tar.gz
lar cd pixman-0.43.4
mkdir build &&
cd    build &&

lar meson setup --prefix=/usr --buildtype=release .. &&
lar ninja
lar ninja install

cd $udir