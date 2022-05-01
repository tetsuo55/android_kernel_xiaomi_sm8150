#!/bin/bash
#
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="Steroid-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="$HOME/clang-llvm"
GCC_DIR="$HOME/gcc"
DEFCONFIG="raphael_defconfig"
ZIPNAME="Steroid--$(date '+%Y%m%d-%H%M').zip"
export LD_LIBRARY_PATH=$TC_DIR/lib64:$LD_LIBRARY_PATH

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
	ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

export PATH="$TC_DIR/bin:$PATH"

if ! [ -d "$TC_DIR" ]; then
	echo "Atom-X clang not found! Cloning to $TC_DIR..."
	if ! git clone https://gitlab.com/reinazhard/aosp-clang.git --depth=1 --no-tags --single-branch "$TC_DIR"; then
		echo "Cloning failed! Aborting..."
		exit 1
	fi
fi

if ! [ -d "$GCC_DIR" ]; then
        echo "Atom-X clang not found! Cloning to $TC_DIR..."
        if ! git clone https://android.googlesource.com/platform/prebuilts/gas/linux-x86/ -b master --depth=1 --single-branch --no-tags "$GCC_DIR"; then
                echo "Cloning failed! Aborting..."
                exit 1
        fi
fi


if [[ $1 = "-r" || $1 = "--regen" ]]; then
	make O=out ARCH=arm64 $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
	rm -rf out
fi

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_DIR/aarch64-linux-gnu- CROSS_COMPILE_ARM32=$GCC_DIR/arm-linux-gnueabi- Image.gz-dtb dtbo.img

kernel="out/arch/arm64/boot/Image.gz-dtb"
dtbo="out/arch/arm64/boot/dtbo.img"

if [ -f "$kernel" ] && [ -f "$dtbo" ]; then
	echo -e "\nKernel compiled succesfully! Zipping up...\n"
	if ! git clone -q https://github.com/tetsuo55/AnyKernel3 -b x3; then
		echo -e "\nCloning AnyKernel3 repo failed! Aborting..."
		exit 1
	fi
	cp $kernel $dtbo AnyKernel3
	rm -f *zip
	cd AnyKernel3 || exit
	rm -rf out/arch/arm64/boot
	zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
	cd ..
	rm -rf AnyKernel3
	echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
	echo "Zip: $ZIPNAME"
	gdrive upload --share "$ZIPNAME"
	curl --upload-file "$ZIPNAME" https://free.keep.sh
	echo
else
	echo -e "\nCompilation failed!"
fi


