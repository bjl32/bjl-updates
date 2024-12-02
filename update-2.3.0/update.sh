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
lar wget https://www.cairographics.org/releases/cairo-1.18.0.tar.xz
lar tar -xf cairo-1.18.0.tar.xz
lar cd cairo-1.18.0
mkdir build &&
cd    build &&

lar meson setup --prefix=/usr --buildtype=release .. &&
lar ninja
lar ninja install

cd $udir
lar wget https://github.com/fribidi/fribidi/releases/download/v1.0.15/fribidi-1.0.15.tar.xz
lar tar -xf fribidi-1.0.15.tar.xz
lar cd fribidi-1.0.15
mkdir build &&
cd    build &&

lar meson setup --prefix=/usr --buildtype=release .. &&
lar ninja
lar ninja install

cd $udir
lar wget https://download.gnome.org/sources/pango/1.54/pango-1.54.0.tar.xz
lar tar -xf pango-1.54.0.tar.xz
lar cd pango-1.54.0
mkdir build &&
cd    build &&

lar meson setup --prefix=/usr          \
            --buildtype=release    \
            --wrap-mode=nofallback \
            ..                     &&
lar ninja
lar ninja install

cd $udir
lar wget https://www.libssh2.org/download/libssh2-1.11.0.tar.gz
lar wget https://www.linuxfromscratch.org/patches/blfs/12.2/libssh2-1.11.0-security_fixes-1.patch
lar tar -xf libssh2-1.11.0.tar.gz
lar cd libssh2-1.11.0
lar patch -Np1 -i ../libssh2-1.11.0-security_fixes-1.patch
./configure --prefix=/usr          \
            --disable-docker-tests \
            --disable-static       &&
lar make
lar make install
# llvm
cd $udir 
lar wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.7/llvm-18.1.7.src.tar.xz
lar wget https://anduin.linuxfromscratch.org/BLFS/llvm/llvm-cmake-18.src.tar.xz
lar wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.7/clang-18.1.7.src.tar.xz
# The system is born to be MINIMAL. The Compiler RT will not be installed.
lar tar -xf llvm-18.1.7.src.tar.xz
lar cd llvm-18.1.7.src
tar -xf ../llvm-cmake-18.src.tar.xz                                   &&
tar -xf ../llvm-third-party-18.src.tar.xz                             &&
sed '/LLVM_COMMON_CMAKE_UTILS/s@../cmake@llvm-cmake-18.src@'          \
    -i CMakeLists.txt                                                 &&
sed '/LLVM_THIRD_PARTY_DIR/s@../third-party@llvm-third-party-18.src@' \
    -i cmake/modules/HandleLLVMOptions.cmake
tar -xf ../clang-18.1.7.src.tar.xz -C tools &&
mv tools/clang-18.1.7.src tools/clang
tar -xf ../clang-18.1.7.src.tar.xz -C tools &&
mv tools/clang-18.1.7.src tools/clang
grep -rl '#!.*python' | xargs sed -i '1s/python$/python3/'
sed 's/utility/tool/' -i utils/FileCheck/CMakeLists.txt
mkdir -v build &&
cd       build &&

CC=gcc CXX=g++                               \
lar cmake -D CMAKE_INSTALL_PREFIX=/usr           \
      -D CMAKE_SKIP_INSTALL_RPATH=ON         \
      -D LLVM_ENABLE_FFI=ON                  \
      -D CMAKE_BUILD_TYPE=Release            \
      -D LLVM_BUILD_LLVM_DYLIB=ON            \
      -D LLVM_LINK_LLVM_DYLIB=ON             \
      -D LLVM_ENABLE_RTTI=ON                 \
      -D LLVM_TARGETS_TO_BUILD="host;AMDGPU" \
      -D LLVM_BINUTILS_INCDIR=/usr/include   \
      -D LLVM_INCLUDE_BENCHMARKS=OFF         \
      -D CLANG_DEFAULT_PIE_ON_LINUX=ON       \
      -D CLANG_CONFIG_FILE_SYSTEM_DIR=/etc/clang \
      -W no-dev -G Ninja ..                  &&
lar ninja
lar ninja install
mkdir -pv /etc/clang &&
for i in clang clang++; do
  echo -fstack-protector-strong > /etc/clang/$i.cfg
done
# sqlite
cd $udir
lar wget https://sqlite.org/2024/sqlite-autoconf-3460100.tar.gz
lar tar -xf sqlite-autoconf-3460100.tar.gz
lar cd sqlite-autoconf-3460100
lar ./configure --prefix=/usr     \
            --disable-static  \
            --enable-fts{4,5} \
            CPPFLAGS="-D SQLITE_ENABLE_COLUMN_METADATA=1 \
                      -D SQLITE_ENABLE_UNLOCK_NOTIFY=1   \
                      -D SQLITE_ENABLE_DBSTAT_VTAB=1     \
                      -D SQLITE_SECURE_DELETE=1"         &&
lar make
lar make install
# rustc
# This will be installed to the /opt directory.
cd $udir
echo Hey! This package need an internet connection.
lar ping -c 3 1.1.1.1
lar wget https://static.rust-lang.org/dist/rustc-1.80.1-src.tar.xz
lar tar -xf rustc-1.80.1-src.tar.xz
lar cd rustc-1.80.1-src
mkdir -pv /opt/rustc-1.80.1      &&
ln -svfn rustc-1.80.1 /opt/rustc
cat << EOF > config.toml
# see config.toml.example for more possible options
# See the 8.4 book for an old example using shipped LLVM
# e.g. if not installing clang, or using a version before 13.0

# Tell x.py the editors have reviewed the content of this file
# and updated it to follow the major changes of the building system,
# so x.py will not warn us to do such a review.
change-id = 125535

[llvm]
# by default, rust will build for a myriad of architectures
targets = "X86"

# When using system llvm prefer shared libraries
link-shared = true

[build]
# omit docs to save time and space (default is to build them)
docs = false

# install extended tools: cargo, clippy, etc
extended = true

# Do not query new versions of dependencies online.
locked-deps = true

# Specify which extended tools (those from the default install).
tools = ["cargo", "clippy", "rustdoc", "rustfmt"]

# Use the source code shipped in the tarball for the dependencies.
# The combination of this and the "locked-deps" entry avoids downloading
# many crates from Internet, and makes the Rustc build more stable.
vendor = true

[install]
prefix = "/opt/rustc-1.80.1"
docdir = "share/doc/rustc-1.80.1"

[rust]
channel = "stable"
description = "for BLFS 12.2"

# Enable the same optimizations as the official upstream build.
lto = "thin"
codegen-units = 1

[target.x86_64-unknown-linux-gnu]
# NB the output of llvm-config (i.e. help options) may be
# dumped to the screen when config.toml is parsed.
llvm-config = "/usr/bin/llvm-config"

[target.i686-unknown-linux-gnu]
# NB the output of llvm-config (i.e. help options) may be
# dumped to the screen when config.toml is parsed.
llvm-config = "/usr/bin/llvm-config"
EOF
{ [ ! -e /usr/include/libssh2.h ] ||
  export LIBSSH2_SYS_USE_PKG_CONFIG=1; }    &&
{ [ ! -e /usr/include/sqlite3.h ] ||
  export LIBSQLITE3_SYS_USE_PKG_CONFIG=1; } &&
python3 x.py build
python3 x.py install rustc std &&
install -vm755 \
  build/host/stage1-tools/*/*/{cargo{,-clippy,-fmt},clippy-driver,rustfmt} \
  /opt/rustc-1.80.1/bin &&
install -vDm644 \
  src/tools/cargo/src/etc/_cargo \
  /opt/rustc-1.80.1/share/zsh/site-functions/_cargo &&
install -vm644 src/tools/cargo/src/etc/man/* \
  /opt/rustc-1.80.1/share/man/man1
rm -fv /opt/rustc-1.80.1/share/doc/rustc-1.80.1/*.old   &&
install -vm644 README.md                                \
               /opt/rustc-1.80.1/share/doc/rustc-1.80.1 &&

install -vdm755 /usr/share/zsh/site-functions      &&
ln -sfv /opt/rustc/share/zsh/site-functions/_cargo \
        /usr/share/zsh/site-functions
unset LIB{SSH2,SQLITE3}_SYS_USE_PKG_CONFIG
cat > /etc/profile.d/rustc.sh << "EOF"
# Begin /etc/profile.d/rustc.sh

pathprepend /opt/rustc/bin           PATH

# End /etc/profile.d/rustc.sh
EOF
source /etc/profile.d/rustc.sh
# librsvg
cd $udir
lar wget https://download.gnome.org/sources/librsvg/2.58/librsvg-2.58.3.tar.xz
lar tar -xf librsvg-2.58.3.tar.xz
lar cd librsvg-2.58.3.tar.xz
./configure --prefix=/usr    \
            --enable-vala    \
            --disable-static \
            --docdir=/usr/share/doc/librsvg-2.58.3 &&
make
make DOC_INSTALL_DIR='$(docdir)' install
#libtiff
cd $udir
lar wget https://download.osgeo.org/libtiff/tiff-4.6.0.tar.gz
lar tar -xf tiff-4.6.0.tar.gz
lar cd tiff-4.6.0
mkdir -p libtiff-build &&
cd       libtiff-build &&

lar cmake -D CMAKE_INSTALL_DOCDIR=/usr/share/doc/libtiff-4.6.0 \
      -D CMAKE_INSTALL_PREFIX=/usr -G Ninja .. &&
lar ninja
lar ninja install
#gdk-pixbuf
cd $udir
lar wget https://download.gnome.org/sources/gdk-pixbuf/2.42/gdk-pixbuf-2.42.12.tar.xz
lar tar -xf gdk-pixbuf-2.42.12.tar.xz
lar cd gdk-pixbuf-2.42.12
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D others=enabled   \
      --wrap-mode=nofallback &&
ninja
ninja install
#libdrm
cd $udir
lar wget https://dri.freedesktop.org/libdrm/libdrm-2.4.122.tar.xz
lar tar -xf libdrm-2.4.122.tar.xz
lar cd libdrm-2.4.122
mkdir build &&
cd    build &&

meson setup --prefix=$XORG_PREFIX \
            --buildtype=release   \
            -D udev=true          \
            -D valgrind=disabled  \
            ..                    &&
ninja
ninja install
#pymod::mako
cd $udir
lar wget https://files.pythonhosted.org/packages/source/M/Mako/Mako-1.3.5.tar.gz
lar tar -xf Mako-1.3.5.tar.gz
lar cd Mako-1.3.5
pip3 wheel -w dist --no-build-isolation --no-deps --no-cache-dir $PWD
pip3 install --no-index --find-links=dist --no-cache-dir --no-user Mako
#wayland
cd $udir
lar wget https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.23.0/downloads/wayland-1.23.0.tar.xz
lar tar -xf wayland-1.23.0.tar.xz
lar cd wayland-1.23.0
mkdir build &&
cd    build &&

meson setup ..            \
      --prefix=/usr       \
      --buildtype=release \
      -D documentation=false &&
ninja
ninja install
#wayland-protocols
cd $udir
lar wget https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/1.36/downloads/wayland-protocols-1.36.tar.xz
lar tar -xf wayland-protocols-1.36.tar.xz
lar cd wayland-protocols-1.36
mkdir build &&
cd    build &&

meson setup --prefix=/usr --buildtype=release &&
ninja
ninja install
# Vulkan headers
cd $udir
lar wget https://github.com/KhronosGroup/Vulkan-Headers/archive/v1.3.294/Vulkan-Headers-1.3.294.tar.gz
lar tar -xf Vulkan-Headers-1.3.294.tar.gz
lar cd Vulkan-Headers-1.3.294
mkdir build &&
cd    build &&

lar cmake -D CMAKE_INSTALL_PREFIX=/usr -G Ninja .. &&
lar ninja
lar ninja install
# Vulkan Loader
cd $udir
lar wget https://github.com/KhronosGroup/Vulkan-Loader/archive/v1.3.294/Vulkan-Loader-1.3.294.tar.gz
lar tar -xf Vulkan-Loader-1.3.294.tar.gz
lar cd Vulkan-Loader-1.3.294
mkdir build &&
cd    build &&

cmake -D CMAKE_INSTALL_PREFIX=/usr   \
      -D CMAKE_BUILD_TYPE=Release    \
      -D CMAKE_SKIP_INSTALL_RPATH=ON \
      -G Ninja .. &&
ninja
ninja install
# libva
# CHOOSER 01
cd $udir
echo "What is your GPU?"
echo "1)    Intel                 2)   Other.               3)     Nvidia"
read gpu_choice

case $gpu_choice in
    1)
        echo "Choose one that is true to you. If you dont know, google it yourself."
        echo "1)    My GPU is provided with Haswell CPUs or earlier"
        echo "2)    My GPU is provided with Broadwell CPUs or later"
        read intel_gen
        case $intel_gen in
            1) echo "vaapi"
               wget https://github.com/intel/intel-vaapi-driver/releases/download/2.4.1/intel-vaapi-driver-2.4.1.tar.bz2
               tar -xf intel-vaapi-driver-2.4.1.tar.bz2
               cd intel-vaapi-driver-2.4.1
               ./configure $XORG_CONFIG &&
               make
               make install
               echo "___________________________________________________________________________________________"
               echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
               echo "==========================================================================================="
               echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!OPERATION REQUIRED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
               echo "==========================================================================================="
               echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
               echo "___________________________________________________________________________________________"

               echo "Enable the following options in the kernel configuration. Recompile the kernel if necessary"
               echo "Device Drivers --->"
               echo "  Graphics support --->"
               echo "    <*/M> Direct Rendering Manager (XFree86 4.1.0 and higher DRI support) --->"
               echo "                                                                      ...  [DRM]"
               echo "      <*/M> Intel 8xx/9xx/G3x/G4x/HD Graphics                         [DRM_I915]"
               echo "DO THIS OR THE SYSTEM WILL FAIL."
               # a
               ;;
            2) echo "media" 
               wget https://github.com/intel/gmmlib/archive/intel-gmmlib-22.4.1.tar.gz
               tar -xf intel-gmmlib-22.4.1.tar.gz
               cd intel-gmmlib-22.4.1
               mkdir build &&
               cd    build &&

               cmake -D CMAKE_INSTALL_PREFIX=/usr \
                     -D BUILD_TYPE=Release        \
                     -G Ninja                     \
                     -W no-dev ..                 &&
              ninja
              ninja install
              cd $udir
              echo "___________________________________________________________________________________________"
              echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              echo "==========================================================================================="
              echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!OPERATION REQUIRED!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
              echo "==========================================================================================="
              echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
              echo "___________________________________________________________________________________________"

              echo "FOLLOW THIS GUIDE TO PROCEED!!! https://github.com/bjl32/BJL3/wiki/Intel-Media"
              echo "FOLLOW THIS GUIDE TO PROCEED!!! https://github.com/bjl32/BJL3/wiki/Intel-Media"
              echo "FOLLOW THIS GUIDE TO PROCEED!!! https://github.com/bjl32/BJL3/wiki/Intel-Media"

              ;;
        esac
        ;;
    2) echo "okay!" ;;
    3) echo "you're cooked. try this: https://github.com/bjl32/BJL3/wiki/nvidia-GPUs"
esac

