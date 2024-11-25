#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Add these functions at the beginning of the script
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


cat > /etc/profile << "EOF"
# Begin /etc/profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# modifications by Dagmar d'Surreal <rivyqntzne@pbzpnfg.arg>
# used in original form in BJL

# System wide environment variables and startup programs.

# System wide aliases and functions should go in /etc/bashrc.  Personal
# environment variables and startup programs should go into
# ~/.bash_profile.  Personal aliases and functions should go into
# ~/.bashrc.

# Functions to help us manage paths.  Second argument is the name of the
# path variable to be modified (default: PATH)
pathremove () {
        local IFS=':'
        local NEWPATH
        local DIR
        local PATHVARIABLE=${2:-PATH}
        for DIR in ${!PATHVARIABLE} ; do
                if [ "$DIR" != "$1" ] ; then
                  NEWPATH=${NEWPATH:+$NEWPATH:}$DIR
                fi
        done
        export $PATHVARIABLE="$NEWPATH"
}

pathprepend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="$1${!PATHVARIABLE:+:${!PATHVARIABLE}}"
}

pathappend () {
        pathremove $1 $2
        local PATHVARIABLE=${2:-PATH}
        export $PATHVARIABLE="${!PATHVARIABLE:+${!PATHVARIABLE}:}$1"
}

export -f pathremove pathprepend pathappend

# Set the initial path
export PATH=/usr/bin

# Attempt to provide backward compatibility with LFS earlier than 11
if [ ! -L /bin ]; then
        pathappend /bin
fi

if [ $EUID -eq 0 ] ; then
        pathappend /usr/sbin
        if [ ! -L /sbin ]; then
                pathappend /sbin
        fi
        unset HISTFILE
fi

# Set up some environment variables.
export HISTSIZE=1000
export HISTIGNORE="&:[bf]g:exit"

# Set some defaults for graphical systems
export XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/share}
export XDG_CONFIG_DIRS=${XDG_CONFIG_DIRS:-/etc/xdg}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$USER}

# Set up a red prompt for root and a green one for users.
NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

for script in /etc/profile.d/*.sh ; do
        if [ -r $script ] ; then
                . $script
        fi
done

unset script RED GREEN NORMAL

# End /etc/profile
EOF
install --directory --mode=0755 --owner=root --group=root /etc/profile.d
cat > /etc/profile.d/bash_completion.sh << "EOF"
# Begin /etc/profile.d/bash_completion.sh
# Import bash completion scripts
# This is the original form of the script written in the BLFS systemd book.

# If the bash-completion package is installed, use its configuration instead
if [ -f /usr/share/bash-completion/bash_completion ]; then

  # Check for interactive bash and that we haven't already been sourced.
  if [ -n "${BASH_VERSION-}" -a -n "${PS1-}" -a -z "${BASH_COMPLETION_VERSINFO-}" ]; then

    # Check for recent enough version of bash.
    if [ ${BASH_VERSINFO[0]} -gt 4 ] || \
       [ ${BASH_VERSINFO[0]} -eq 4 -a ${BASH_VERSINFO[1]} -ge 1 ]; then
       [ -r "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion" ] && \
            . "${XDG_CONFIG_HOME:-$HOME/.config}/bash_completion"
       if shopt -q progcomp && [ -r /usr/share/bash-completion/bash_completion ]; then
          # Source completion code.
          . /usr/share/bash-completion/bash_completion
       fi
    fi
  fi

else

  # bash-completions are not installed, use only bash completion directory
  if shopt -q progcomp; then
    for script in /etc/bash_completion.d/* ; do
      if [ -r $script ] ; then
        . $script
      fi
    done
  fi
fi

# End /etc/profile.d/bash_completion.sh
EOF
cat > /etc/profile.d/dircolors.sh << "EOF"
# Setup for /bin/ls and /bin/grep to support color, the alias is in /etc/bashrc.
# This is the original form of the script written in the BLFS systemd book.
if [ -f "/etc/dircolors" ] ; then
        eval $(dircolors -b /etc/dircolors)
fi

if [ -f "$HOME/.dircolors" ] ; then
        eval $(dircolors -b $HOME/.dircolors)
fi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
EOF
cat > /etc/profile.d/extrapaths.sh << "EOF"
# This is the original form of the script written in the BLFS systemd book.
if [ -d /usr/local/lib/pkgconfig ] ; then
        pathappend /usr/local/lib/pkgconfig PKG_CONFIG_PATH
fi
if [ -d /usr/local/bin ]; then
        pathprepend /usr/local/bin
fi
if [ -d /usr/local/sbin -a $EUID -eq 0 ]; then
        pathprepend /usr/local/sbin
fi

if [ -d /usr/local/share ]; then
        pathprepend /usr/local/share XDG_DATA_DIRS
fi

# Set some defaults before other applications add to these paths.
pathappend /usr/share/info INFOPATH
EOF
cat > /etc/profile.d/readline.sh << "EOF"
# Set up the INPUTRC environment variable.
# This is the original form of the script written in the BLFS systemd book.
if [ -z "$INPUTRC" -a ! -f "$HOME/.inputrc" ] ; then
        INPUTRC=/etc/inputrc
fi
export INPUTRC
EOF
install --directory --mode=0755 --owner=root --group=root /etc/bash_completion.d
cat > /etc/profile.d/umask.sh << "EOF"
# By default, the umask should be set.
# This is the original form of the script written in the BLFS systemd book.
if [ "$(id -gn)" = "$(id -un)" -a $EUID -gt 99 ] ; then
  umask 002
else
  umask 022
fi
EOF
cat > /etc/profile.d/i18n.sh << "EOF"
# Set up i18n variables
# This is the original form of the script written in the BLFS systemd book.
for i in $(locale); do
  unset ${i%=*}
done

if [[ "$TERM" = linux ]]; then
  export LANG=C.UTF-8
else
  source /etc/locale.conf

  for i in $(locale); do
    key=${i%=*}
    if [[ -v $key ]]; then
      export $key
    fi
  done
fi
EOF
cat > /etc/bashrc << "EOF"
# Begin /etc/bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>
# This is the original form of the script written in the BLFS systemd book.

# System wide aliases and functions.

# System wide environment variables and startup programs should go into
# /etc/profile.  Personal environment variables and startup programs
# should go into ~/.bash_profile.  Personal aliases and functions should
# go into ~/.bashrc

# Provides colored /bin/ls and /bin/grep commands.  Used in conjunction
# with code in /etc/profile.

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# Provides prompt for non-login shells, specifically shells started
# in the X environment. [Review the LFS archive thread titled
# PS1 Environment Variable for a great case study behind this script
# addendum.]

NORMAL="\[\e[0m\]"
RED="\[\e[1;31m\]"
GREEN="\[\e[1;32m\]"
if [[ $EUID == 0 ]] ; then
  PS1="$RED\u [ $NORMAL\w$RED ]# $NORMAL"
else
  PS1="$GREEN\u [ $NORMAL\w$GREEN ]\$ $NORMAL"
fi

unset RED GREEN NORMAL

# End /etc/bashrc
EOF
cat > ~/.bash_profile << "EOF"
# Begin ~/.bash_profile
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# updated by Bruce Dubbs <bdubbs@linuxfromscratch.org>
# This is the original form of the script written in the BLFS systemd book.

# Personal environment variables and startup programs.

# Personal aliases and functions should go in ~/.bashrc.  System wide
# environment variables and startup programs are in /etc/profile.
# System wide aliases and functions are in /etc/bashrc.

if [ -f "$HOME/.bashrc" ] ; then
  source $HOME/.bashrc
fi

if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Having . in the PATH is dangerous
#if [ $EUID -gt 99 ]; then
#  pathappend .
#fi

# End ~/.bash_profile
EOF
cat > ~/.profile << "EOF"
# Begin ~/.profile
# Personal environment variables and startup programs.
# This is the original form of the script written in the BLFS systemd book.
if [ -d "$HOME/bin" ] ; then
  pathprepend $HOME/bin
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.profile
EOF
cat > ~/.bashrc << "EOF"
# Begin ~/.bashrc
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# This is the original form of the script written in the BLFS systemd book.
# Personal aliases and functions.

# Personal environment variables and startup programs should go in
# ~/.bash_profile.  System wide environment variables and startup
# programs are in /etc/profile.  System wide aliases and functions are
# in /etc/bashrc.

if [ -f "/etc/bashrc" ] ; then
  source /etc/bashrc
fi

# Set up user specific i18n variables
#export LANG=<ll>_<CC>.<charmap><@modifiers>

# End ~/.bashrc
EOF
cat > ~/.bash_logout << "EOF"
# Begin ~/.bash_logout
# Written for Beyond Linux From Scratch
# by James Robertson <jameswrobertson@earthlink.net>
# This is the original form of the script written in the BLFS systemd book.
# Personal items to perform on logout.

# End ~/.bash_logout
EOF
dircolors -p > /etc/dircolors
rm -rf /sources
mkdir /sources
cd /sources
log_and_run wget https://archive.xfce.org/src/xfce/libxfce4util/4.18/libxfce4util-4.18.2.tar.bz2
tar -xf libxfce4util-4.18.2.tar.bz2
cd libxfce4util-4.18.2
log_and_run ./configure --prefix=/usr
log_and_run make
make install
cd ..
log_and_run wget https://archive.xfce.org/src/xfce/xfconf/4.18/xfconf-4.18.3.tar.bz2
tar -xf xfconf-4.18.3.tar.bz2
cd xfconf-4.18.3
log_and_run ./configure --prefix=/usr
log_and_run make
make install
cd ..
log_and_run wget https://curl.se/download/curl-8.9.1.tar.xz
tar -xf curl-8.9.1.tar.xz
cd curl-8.9.1
log_and_run ./configure --prefix=/usr                           \
            --disable-static                        \
            --with-openssl                          \
            --enable-threaded-resolver              \
            --with-ca-path=/etc/ssl/certs
log_and_run make
make install
find docs \( -name Makefile\* -o  \
             -name \*.1       -o  \
             -name \*.3       -o  \
             -name CMakeLists.txt \) -delete &&

cp -v -R docs -T /usr/share/doc/curl-8.9.1
cd /sources
log_and_run wget https://dist.libuv.org/dist/v1.48.0/libuv-v1.48.0.tar.gz
tar -xf libuv-v1.48.0.tar.gz
cd libuv-v1.48.0
log_and_run ./autogen.sh
log_and_run ./configure --prefix=/usr --disable-static
log_and_run make
make install
cd ..
log_and_run wget https://github.com/nghttp2/nghttp2/releases/download/v1.62.1/nghttp2-1.62.1.tar.xz
tar -xf nghttp2-1.62.1.tar.xz
cd nghttp2-1.62.1
log_and_run ./configure --prefix=/usr     \
            --disable-static  \
            --enable-lib-only \
            --docdir=/usr/share/doc/nghttp2-1.62.1
log_and_run make
make install
cd ..
log_and_run wget https://cmake.org/files/v3.30/cmake-3.30.2.tar.gz
tar -xf cmake-3.30.2.tar.gz
cd cmake-3.30.2
sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake
log_and_run ./bootstrap --prefix=/usr        \
            --system-libs        \
            --mandir=/share/man  \
            --no-system-jsoncpp  \
            --no-system-cppdap   \
            --no-system-librhash \
            --docdir=/share/doc/cmake-3.30.2
log_and_run make
make install
cd ..
log_and_run wget https://github.com/silnrsi/graphite/releases/download/1.3.14/graphite2-1.3.14.tgz
tar -xf graphite2-1.3.14.tgz
cd graphite2-1.3.14
sed -i '/cmptest/d' tests/CMakeLists.txt
mkdir build &&
cd    build &&
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
log_and_run make
make install
cd ..
log_and_run wget https://downloads.sourceforge.net/libpng/libpng-1.6.43.tar.xz
log_and_run wget https://downloads.sourceforge.net/sourceforge/libpng-apng/libpng-1.6.43-apng.patch.gz
tar -xf libpng-1.6.43.tar.xz
cd libpng-1.6.43
gzip -cd ../libpng-1.6.43-apng.patch.gz | patch -p1
log_and_run ./configure --prefix=/usr --disable-static
log_and_run make
make install
mkdir -v /usr/share/doc/libpng-1.6.43 &&
cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.43
cd ..
# Which Alternative
cat > /usr/bin/which << "EOF"
#!/bin/bash
type -pa "$@" | head -n 1 ; exit ${PIPESTATUS[0]}
EOF
chmod -v 755 /usr/bin/which
chown -v root:root /usr/bin/which
log_and_run wget https://downloads.sourceforge.net/freetype/freetype-2.13.3.tar.xz
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg
sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h
log_and_run ./configure --prefix=/usr --enable-freetype-config --disable-static
log_and_run make
make install
cd ..

log_and_run wget https://github.com/harfbuzz/harfbuzz/releases/download/9.0.0/harfbuzz-9.0.0.tar.xz
tar -xf harfbuzz-9.0.0.tar.xz
cd harfbuzz-9.0.0
mkdir build &&
cd    build &&
meson setup ..             \
      --prefix=/usr        \
      --buildtype=release  \
      -D graphite2=enabled
ninja
ninja install
cd ..

rm -rf freetype-2.13.3
tar -xf freetype-2.13.3.tar.xz
cd freetype-2.13.3
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg
sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h
log_and_run ./configure --prefix=/usr --disable-static
log_and_run make
make install
cd ..

log_and_run wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.15.0.tar.xz
tar -xf fontconfig-2.15.0.tar.xz
cd fontconfig-2.15.0
log_and_run ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-docs --docdir=/usr/share/doc/fontconfig-2.15.0
log_and_run make
make install
install -v -dm755 \
        /usr/share/{man/man{1,3,5},doc/fontconfig-2.15.0/fontconfig-devel} &&
install -v -m644 fc-*/*.1         /usr/share/man/man1 &&
install -v -m644 doc/*.3          /usr/share/man/man3 &&
install -v -m644 doc/fonts-conf.5 /usr/share/man/man5 &&
install -v -m644 doc/fontconfig-devel/* \
                                  /usr/share/doc/fontconfig-2.15.0/fontconfig-devel &&
install -v -m644 doc/*.{pdf,sgml,txt,html} \
                                  /usr/share/doc/fontconfig-2.15.0
cd ..
export XORG_PREFIX="/usr"
export XORG_CONFIG="--prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-static"
cat > /etc/profile.d/xorg.sh << EOF
XORG_PREFIX="$XORG_PREFIX"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"
export XORG_PREFIX XORG_CONFIG
EOF
chmod 644 /etc/profile.d/xorg.sh
rm -rf /sources
echo "Update script completed successfully at $(date)" >> "$LOG_FILE"
/etc/profile

