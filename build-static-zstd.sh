
#! /bin/bash

set -e

WORKSPACE=/tmp/workspace
mkdir -p $WORKSPACE
mkdir -p /work/artifact

# xz
cd $WORKSPACE
aa=$(curl -s "https://api.github.com/repos/tukaani-project/xz/releases/latest" | grep -Po '"tag_name": "v\K[0-9rc.]+')
curl -sL $( curl -s "https://api.github.com/repos/tukaani-project/xz/releases/latest" | jq -r '.assets[] | select(.content_type == "application/x-xz") | {browser_download_url}  | .browser_download_url ') | tar x --xz
cd xz-$aa
CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" ./configure --prefix=/usr/local/xzmm --disable-shared --enable-static --enable-year2038
make
make install

# lz4
cd $WORKSPACE
git clone https://github.com/lz4/lz4.git
cd lz4/build/meson
PKG_CONFIG_PATH=/usr/local/xzmm/lib/pkgconfig CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" meson setup builddir -Dprefix=/usr/local/xzmm -Ddefault_library=static -Dprograms=true --strip
cd builddir
sed -i 's@.so.3 @.a @g' ./build.ninja
sed -i 's@.so @.a @g' ./build.ninja
ninja
ninja install

# zstd
cd $WORKSPACE
git clone https://github.com/facebook/zstd.git
cd zstd/build/meson
sed -i '/man1_EXT/s/^/#&/'  ./programs/meson.build
PKG_CONFIG_PATH=/usr/local/xzmm/lib/pkgconfig CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" meson setup builddir -Dprefix=/usr/local/xzmm -Ddefault_library=static -Dzlib=enabled -Dlzma=enabled -Dlz4=enabled --strip
cd builddir
sed -i 's@.so.3 @.a @g' ./build.ninja
sed -i 's@.so @.a @g' ./build.ninja
sed -i 's@-llz4@-L/usr/local/xzmm/lib -llz4@g' ./build.ninja
ninja
ninja install

# lzip
cd $WORKSPACE
aa=1.25
curl -sL http://download.savannah.gnu.org/releases/lzip/lzip-$aa.tar.lz | tar x --lzip
cd lzip-$aa
LDFLAGS="-static --static -no-pie -s" ./configure --prefix=/usr/local/lzipmm
sed -i '/^LDFLAGS = /s/ = / = -static --static -no-pie -s/' ./Makefile
make
make install 

# lunzip
cd $WORKSPACE
aa=1.16-rc1
curl -sL http://download.savannah.gnu.org/releases/lzip/lunzip/lunzip-$aa.tar.lz | tar x --lzip
cd lunzip-$aa
LDFLAGS="-static --static -no-pie -s" ./configure --prefix=/usr/local/lzipmm
sed -i '/^LDFLAGS = /s/ = / = -static --static -no-pie -s/' ./Makefile
make
make install

# tar
cd $WORKSPACE
git clone git://git.savannah.gnu.org/tar.git
cd tar
git clone --recursive https://github.com/coreutils/gnulib.git
./bootstrap
FORCE_UNSAFE_CONFIGURE=1 CFLAGS="$CFLAGS -Wno-error=unused-value" LDFLAGS="-static --static -no-pie -s" ./configure --prefix=/usr/local/tarmm
make
make install

cd /usr/local
tar vcJf ./xzmm.tar.xz xzmm
tar vcJf ./lzipmm.tar.xz lzipmm
tar vcJf ./tarmm.tar.xz tarmm

mv ./*mm.xz /work/artifact/
