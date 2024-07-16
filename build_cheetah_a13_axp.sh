#!/bin/bash
####################################################################################################################

# be strict on failures
set -e

# fix build errors
export LC_ALL=C

# unset any extendrom var
unset EXTENDROM_DEBUG_PATH EXTENDROM_BOOT_DEBUG EXTENDROM_PREROOT_BOOT ENABLE_EXTENDROM EXTENDROM_PACKAGES PREROOT_BOOT
unset EXTENDROM_DEBUG_PATH_SIZE_FULL EXTENDROM_DEBUG_PATH_SIZE_KERNEL EXTENDROM_DEBUG_PATH_SIZE_SELINUX 
unset EXTENDROM_DEBUG_PATH_SIZE_CRASH EXTENDROM_SIGNATURE_SPOOFING EXTENDROM_SIGSPOOF_FORCE_PDIR EXTENDROM_PATCHER_RESET
unset EXTENDROM_SIGNING_PATCHES EXTENDROM_PACKAGES_SKIP_DL

########################### PREPARE #########################

# set legacy python2 env - if needed
# 1. sudo apt-get install python2 virtualenv python2-pip-whl python2-setuptools-whl
# 2. mkdir -p ~/.venv/python2
# 3. virtualenv --python=$(which python2) ~/.venv/python2
case a13 in
    a9|a10) source ~/.venv/python2/bin/activate ;;
esac

########################### BUILD #########################

# setup build env including stupid DOS workarounds
echo "BUILDHOME: /home/jenkins"
export HOME="/home/jenkins" && echo "home set to $HOME" >> /home/jenkins/build_cheetah_a13_axp_13.0.52.log
export BDEVICE="cheetah"
export PATH="/home/jenkins/.local/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ ! -L "$HOME/.local/bin/sh" ];then ln -s /bin/bash $HOME/.local/bin/sh; fi
if [ ! -L "$HOME/.local/bin/rename" ];then ln -s /home/androidsource/do-not-touch/axp/Build/LineageOS-20.0/rename $HOME/.local/bin/rename; fi
alias sh=/bin/bash
alias rename="/home/androidsource/do-not-touch/axp/Build/LineageOS-20.0/rename"
cd /home/androidsource/do-not-touch/axp/Build/LineageOS-20.0
source build/envsetup.sh >> /home/jenkins/build_cheetah_a13_axp_13.0.52.log 2>&1 && echo "sourcing envsetup: success" >> /home/jenkins/build_cheetah_a13_axp_13.0.52.log
source /home/androidsource/do-not-touch/axp/Scripts/init.sh >> /home/jenkins/build_cheetah_a13_axp_13.0.52.log 2>&1 && echo "sourcing init: success" >> /home/jenkins/build_cheetah_a13_axp_13.0.52.log

breakfast lineage_cheetah-user

# CCACHE
export USE_CCACHE=1
if [ "1" -eq 1 ];then
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_COMPRESS=1
    mkdir -p /ssd/ccache/jenkins/a13
    export CCACHE_DIR="/ssd/ccache/jenkins/a13"
    /usr/bin/ccache --max-size=10G
fi

# extendrom flags
export ENABLE_EXTENDROM=true
export EXTENDROM_PACKAGES="additional_repos.xml Phonesky_AXP-OS Magisk AuroraStore MicrogGmsCore_GH GsfProxy_GH noeSpeakNG NeoLauncher-latest OpenEUICC_AXP-OS"
export EXTENDROM_FDROID_REPOS="molly.xml nailyk.xml threema.xml futo_org.xml"
export EXTENDROM_PREROOT_BOOT=true
export MAGISK_TARGET_ARCH=arm64
export EXTENDROM_BOOT_DEBUG=true
export EXTENDROM_DEBUG_PATH=/mnt/vendor/persist
export EXTENDROM_DEBUG_PATH_SIZE_FULL=500
export EXTENDROM_DEBUG_PATH_SIZE_KERNEL=100
export EXTENDROM_DEBUG_PATH_SIZE_SELINUX=200
export EXTENDROM_DEBUG_PATH_SIZE_CRASH=200
export EXTENDROM_SIGNATURE_SPOOFING=true
export EXTENDROM_PATCHER_RESET=false
export EXTENDROM_SIGNING_PATCHES=true
# execute extendrom
$PWD/vendor/extendrom/er.sh

# build
resetEnv
mka generate_verity_key
buildDevice cheetah

# See: https://source.android.com/docs/security/features/verifiedboot/boot-flow 
FPID=$(cat user-keys/avb_pkmd.bin | openssl dgst -sha256 | cut -d "=" -f 2 | tr -d " " | tr "[[:lower:]]" "[[:upper:]]")
echo -e "\nBOOTLOADER minimal ID"
echo -e "\t${FPID:0:8}\n"
echo -e "BOOTLOADER full ID:"
echo -e "\t${FPID:0:16}"
echo -e "\t${FPID:16:16}"
echo -e "\t${FPID:32:16}"
echo -e "\t${FPID:48:16}\n"
out/host/linux-x86/bin/avbtool info_image --image out/target/product/cheetah/obj/PACKAGING/target_files_intermediates/lineage_cheetah-target_files-eng.emy/IMAGES/vbmeta.img
out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/cheetah/obj/PACKAGING/target_files_intermediates/lineage_cheetah-target_files-eng.emy/IMAGES/vbmeta.img

echo -e "\n\nSUCCESS: You should find your build here:\n/ssd/axp/zips/cheetah/LineageOS-20.0/release_keys/\n"
