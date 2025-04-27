#!/bin/bash

TC_DIR="$HOME/tc/clang-19.0.0"
DEFCONFIG="lisa_defconfig"
ZIPNAME="MoeKernel-lisa-$(date '+%Y%m%d-%H%M').zip"

if ! [ -d "${TC_DIR}" ]; then
echo "Clang not found! Cloning to ${TC_DIR}..."
if ! git clone --depth=1 https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r530567.git ${TC_DIR}; then
echo "Cloning failed! Aborting..."
exit 1
fi
fi

export PATH="$TC_DIR/bin:$PATH"

MAKE_PARAMS="O=out ARCH=arm64 LLVM=1 LLVM_IAS=1"

export PATH="$TC_DIR/bin:$PATH"

if [[ $1 = "-r" || $1 = "--regen" ]]; then
        make $MAKE_PARAMS $DEFCONFIG savedefconfig
        cp out/defconfig arch/arm64/configs/$DEFCONFIG
        echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
        exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
        rm -rf out
        echo "Cleaned output folder"
fi

mkdir -p out
make $MAKE_PARAMS $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS || exit $?
make -j$(nproc --all) $MAKE_PARAMS INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install

kernel="out/arch/arm64/boot/Image"
dtb="out/arch/arm64/boot/dts/vendor/qcom/yupik.dtb"
dtbo="out/arch/arm64/boot/dts/vendor/qcom/lisa-sm7325-overlay.dtbo"

if [ ! -f "$kernel" ] || [ ! -f "$dtb" ] || [ ! -f "$dtbo" ]; then
        echo -e "\nCompilation failed!"
        exit 1
fi

echo -e "\nKernel compiled succesfully! Zipping up...\n"
if [ -d "$AK3_DIR" ]; then
        cp -r $AK3_DIR AnyKernel3
        git -C AnyKernel3 checkout lisa &> /dev/null
elif ! git clone -q https://github.com/MoeKernel/AnyKernel3 -b lisa; then
        echo -e "\nAnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
        exit 1
fi

cp $kernel AnyKernel3/Image
cp $dtb AnyKernel3/dtb
cp $dtbo AnyKernel3/dtbo.img
cp out/.config AnyKernel3/config

# cp out/arch/arm64/boot/Image AnyKernel3/Image
# cp out/arch/arm64/boot/dtb.img AnyKernel3/dtb
# cp out/arch/arm64/boot/dtbo.img AnyKernel3/dtbo.img

cp $(find out/modules/lib/modules/5.4* -name '*.ko') AnyKernel3/modules/vendor/lib/modules/
cp out/modules/lib/modules/5.4*/modules.{alias,dep,softdep} AnyKernel3/modules/vendor/lib/modules
cp out/modules/lib/modules/5.4*/modules.order AnyKernel3/modules/vendor/lib/modules/modules.load
sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' AnyKernel3/modules/vendor/lib/modules/modules.dep
sed -i 's/.*\///g' AnyKernel3/modules/vendor/lib/modules/modules.load
rm -rf out/arch/arm64/boot out/modules
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
cd ..
rm -rf AnyKernel3
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"

if [ ! -f "./go-up" ]; then
    echo -e "\nDownloading go-up..."
    wget https://raw.githubusercontent.com/GustavoMends/go-up/master/go-up && chmod +x go-up
fi

echo -e "\nUploading with go-up..."
./go-up "$ZIPNAME"
