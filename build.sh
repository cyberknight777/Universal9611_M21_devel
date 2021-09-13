#!/bin/bash

# Initialize variables

BOLD='\033[1m'
GRN='\033[01;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[01;31m'
RST='\033[0m'
ORIGIN_DIR=$(pwd)
BUILD_PREF_COMPILER='clang'
TOOLCHAIN=$(pwd)/build-shit/toolchain
# export environment variables
export_env_vars() {
    export KBUILD_BUILD_USER=Kohei
    export KBUILD_BUILD_HOST=Izumi
    
    export ARCH=arm64
    export SUBARCH=arm64
    export ANDROID_MAJOR_VERSION=r
    export PLATFORM_VERSION=11
    export $ARCH
    
    # CCACHE
    export CCACHE="$(which ccache)"
    export USE_CCACHE=1
    ccache -M 5GB
    export CROSS_COMPILE=aarch64-linux-gnu-
    export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
    export CC=${BUILD_PREF_COMPILER}
}

script_echo() {
    echo "  $1"
}
exit_script() {
    kill -INT $$
}
add_deps() {
    echo -e "${CYAN}"
    if [ ! -d $(pwd)/build-shit ]
    then
        script_echo "Create build-shit folder"
        mkdir $(pwd)/build-shit
    fi

    if [ ! -d $(pwd)/output ]
    then
        script_echo "Create output folder"
        mkdir $(pwd)/output
    fi

    if [ ! -d $(pwd)/build-shit/toolchain ]
    then
        script_echo "Downloading toolchain...."
        git clone https://github.com/gamer13433/android_clang_prebuilt.git ${TOOLCHAIN} --single-branch --depth 1 2>&1 | sed 's/^/     /'
    fi
    verify_toolchain_install
}
verify_toolchain_install() {
    sleep 2
    script_echo " "
    if [[ -d "${TOOLCHAIN}" ]]; then
        script_echo "I: Toolchain found at default location"
        export PATH="${TOOLCHAIN}/bin:$PATH"
        export LD_LIBRARY_PATH="${TOOLCHAIN}/lib:$LD_LIBRARY_PATH"
    else
        script_echo "I: Toolchain not found"
        script_echo "   Downloading recommended toolchain at ${TOOLCHAIN}..."
        add_deps
    fi
}
build_kernel_image() {
    sleep 3
    script_echo " "
    read -p "Write the Kernel version: " KV
    script_echo 'Building Pika-Kernel Kernel For M21'
    sleep 3
    make -C $(pwd) CC=${BUILD_PREF_COMPILER} LLVM=1 LLVM_IAS=1 AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LOCALVERSION="Pika-Kernel-${KV}" -j$((`nproc`+1)) m21_defconfig 2>&1 | sed 's/^/     /'
    make -C $(pwd) CC=${BUILD_PREF_COMPILER} LLVM=1 LLVM_IAS=1 AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip LOCALVERSION="Pika-Kernel-${KV}" -j$((`nproc`+1)) 2>&1 | sed 's/^/     /'
}
build_flashable_zip() {
    if [[ -e "$(pwd)/out/arch/arm64/boot/Image" ]]; then
        script_echo " "
        script_echo "I: Building kernel image..."
        echo -e "${GRN}"
        rm -rf $(pwd)/output/*
        rm -rf $(pwd)/Pika-Kernel/AK/Image
        rm -rf $(pwd)/Pika-Kernel/AK/*.zip
        cp -r $(pwd)/out/arch/arm64/boot/Image $(pwd)/Pika-Kernel/AK/Image
        cd $(pwd)/Pika-Kernel/AK
        bash zip.sh
        cd ../..
        cp -r $(pwd)/Pika-Kernel/AK/1*.zip $(pwd)/output/Pika-kernel-ONEUI-$KV-M21.zip
        cd $(pwd)/output
        wget -q https://temp.sh/up.sh
        chmod +x up.sh
        echo -e "${RED}"
        ./up.sh Cos* 2>&1 | sed 's/^/     /'
        cd ../
        if [[ ! -f ${ORIGIN_DIR}/Pika-Kernel/AK/Image ]]; then
            echo -e "${RED}"
            script_echo " "
            script_echo "E: Kernel image not built successfully!"
            script_echo "   Errors can be fround from above."
            sleep 3
            exit_script
        else
            rm -f $(pwd)/out/arch/arm64/boot/Image
            rm -f $(pwd)/Pika-Kernel/AK/{Image, *.zip}
            rm -f $(pwd)/output/*
        fi
        
    else
        echo -e "${RED}"
        script_echo "E: Image not built!"
        script_echo "   Errors can be fround from above."
        sleep 3
        exit_script
    fi
}
add_deps
export_env_vars
build_kernel_image
build_flashable_zip