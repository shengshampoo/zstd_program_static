
#! /bin/bash

set -e

WORKSPACE=/tmp/workspace
mkdir -p $WORKSPACE
mkdir -p /work/artifact

# xz
cd $WORKSPACE
aa=$(curl -s "https://api.github.com/repos/tukaani-project/xz/releases/latest" | grep -Po '"tag_name": "v\K[0-9rc.]+')
curl -sL $( curl -s "https://api.github.com/repos/tukaani-project/xz/releases/latest" | jq -r '.assets[] | select(.content_type == "application/x-xz") | {browser_download_url}  | .browser_download_url ') | tar x --xz
cd xz-$aa && CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" ./configure --prefix=/usr/local/xzmm --disable-shared --enable-static --enable-year2038
make
make install

# lz4
cd $WORKSPACE
git clone https://github.com/lz4/lz4.git && cd lz4/build/meson
PKG_CONFIG_PATH=/usr/local/xzmm/lib/pkgconfig CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" meson setup builddir -Dprefix=/usr/local/xzmm -Ddefault_library=static -Dprograms=true --strip
cd builddir
sed -i 's@.so.3 @.a @g' ./build.ninja
sed -i 's@.so @.a @g' ./build.ninja
ninja
ninja install

# zstd
git clone https://github.com/facebook/zstd.git
cd zstd/build/meson
PKG_CONFIG_PATH=/usr/local/xzmm/lib/pkgconfig CFLAGS="$CFLAGS -static" LDFLAGS="-static --static -no-pie -s" meson setup builddir -Dprefix=/usr/local/xzmm -Ddefault_library=static -Dzlib=enabled -Dlzma=enabled -Dlz4=enabled --strip
cd builddir
sed -i 's@.so.3 @.a @g' ./build.ninja
sed -i 's@.so @.a @g' ./build.ninja
sed -i 's@-llz4@-L/usr/local/xzmm/lib -llz4@g' ./build.ninja
ninja
ninja install

cd /usr/local
tar vcJf ./xzmm.tar.xz xzmm

mv ./xzmm.tar.xz /work/artifact/
