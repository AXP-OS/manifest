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
export HOME="/home/jenkins" && echo "home set to $HOME" >> /home/jenkins/build_FP3_a13_axp_13.0.15.log
export BDEVICE="FP3"
export PATH="/home/jenkins/.local/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ ! -L "$HOME/.local/bin/sh" ];then ln -s /bin/bash $HOME/.local/bin/sh; fi
if [ ! -L "$HOME/.local/bin/rename" ];then ln -s /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/rename $HOME/.local/bin/rename; fi
alias sh=/bin/bash
alias rename="/ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/rename"
cd /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0
source build/envsetup.sh >> /home/jenkins/build_FP3_a13_axp_13.0.15.log 2>&1 && echo "sourcing envsetup: success" >> /home/jenkins/build_FP3_a13_axp_13.0.15.log
source /ssd2/androidsource/do-not-touch/axp/Scripts/init.sh >> /home/jenkins/build_FP3_a13_axp_13.0.15.log 2>&1 && echo "sourcing init: success" >> /home/jenkins/build_FP3_a13_axp_13.0.15.log

# support A14 and later

        
breakfast lineage_FP3${brf_suffix}-user

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
export EXTENDROM_PACKAGES="AOSmium_webview64 additional_repos.xml AuroraStore F-Droid noeSpeakNG noDefaultBrowserWebView"
export EXTENDROM_FDROID_REPOS="molly.xml nailyk.xml threema.xml futo_org.xml cromite.xml izzysoft.xml microg.xml"
export EXTENDROM_PREROOT_BOOT=false
#export MAGISK_TARGET_ARCH=
export EXTENDROM_BOOT_DEBUG=true
export EXTENDROM_DEBUG_PATH=/mnt/vendor/persist
export EXTENDROM_DEBUG_PATH_SIZE_FULL=500
export EXTENDROM_DEBUG_PATH_SIZE_KERNEL=100
export EXTENDROM_DEBUG_PATH_SIZE_SELINUX=200
export EXTENDROM_DEBUG_PATH_SIZE_CRASH=200
export EXTENDROM_SIGNATURE_SPOOFING=true
export EXTENDROM_PATCHER_RESET=false
export EXTENDROM_SIGNING_PATCHES=true
export EXTENDROM_ALLOW_ANY_CALL_RECORDING=false
# execute extendrom
$PWD/vendor/extendrom/er.sh

echo "[GIT] checking kernel changes in kernel/fairphone/sdm632"
# add unstaged changes
CMT=0
cd kernel/fairphone/sdm632
git add -A || CMT=1
# check for uncommitted changes
CMTL=$(git status --porcelain=v1 | wc -l 2>/dev/null)
# commit if required
if [ $CMT -eq 1 -o $CMTL -gt 0 ];then 
   git commit --author="${AXP_GIT_AUTHOR} <${AXP_GIT_MAIL}>" -m "uncatched scripted change(s)"
   echo "[GIT] committed scripted kernel changes for kernel/fairphone/sdm632" >> /home/jenkins/build_FP3_a13_axp_13.0.15.log
fi
git status
croot

# build
resetEnv
mka generate_verity_key
buildDevice FP3

# this will create a fastboot flashable factory image
# containing the official Fairphone images + AXP.OS based on vendor/firmware/FP3/0SOURCE
VERSION="20.0-20250304-SLIM"
FZIP="AXP.OS-${VERSION}-FP3"
source vendor/firmware/FP3/0SOURCE
if [ -f out/FP3-factory.zip ];then rm out/FP3-factory.zip;fi
if [ -f "/ssd/axp/persistent/FP3/FP3-${FACTORYID}-factory-${FACTORYIDHASH}.zip" ];then
    echo "Using previously downloaded factory image: FP3-${FACTORYID}-factory-${FACTORYIDHASH}.zip"
    cp "/ssd/axp/persistent/FP3/FP3-${FACTORYID}-factory-${FACTORYIDHASH}.zip" out/FP3-factory.zip 
else
    echo "FP3-${FACTORYID}-gms-${FACTORYIDHASH}.zip not found in: /ssd/axp/persistent/FP3, downloading.."
    wget -q https://fairphone-android-builds.ams3.digitaloceanspaces.com/FP3/A13/${FACTORYID}-gms-${FACTORYIDHASH}-user-fastbootimage.zip -O out/FP3-factory.zip || (wget https://fairphone-android-builds.ams3.digitaloceanspaces.com/FP3/A13/${FACTORYID}-gms-${FACTORYIDHASH}-user-fastbootimage.zip -O out/FP3-factory.zip ; exit 9)
fi
cd out/target/product/FP3
if [ -d factory ];then rm -rf factory;fi
if [ -f AXP.OS-${VERSION}-factory.zip ];then rm AXP.OS-${VERSION}-factory.zip;fi
unzip /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP3-factory.zip -d factory -x '*/super_system.img' '*/super_vendor.img'
cd factory/${FACTORYID}-gms-${FACTORYIDHASH}-user-fastbootimage/images
unzip -o ../../../${FZIP}-fastboot.zip '*.img'
mv system.img super_system.img
mv vendor.img super_vendor.img
avb_file="FP3_AXP.OS_avb_pkmd.bin"
if [ "slim" == "slim" ];then avb_file="FP3_AXP.OS-slim_avb_pkmd.bin";fi
cp /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/user-keys/avb_pkmd.bin $avb_file
cd ..

# add flashing the AXP.OS avb key
f=$(echo flash_fp*.command)
awk '{print} /^flash_device$/ && !n {print "sleep 5\n'"\${FASTBOOT_BIN}"' erase avb_custom_key\n'"\${FASTBOOT_BIN}"' flash avb_custom_key '\${IMAGES_DIR}'/'"$avb_file"'\n'"\${FASTBOOT_BIN}"' reboot-bootloader"; n++}' $f > $f.tmp && mv $f.tmp $f && chmod +x $f
cd ..

# re-package it
zip -r ../${FZIP}-factory.zip ${FACTORYID}-gms-${FACTORYIDHASH}-user-fastbootimage
cd ..
sha256sum ${FZIP}-factory.zip > ${FZIP}-factory.zip.sha256
mv ${FZIP}-factory.zip* /ssd/slim/zips/FP3/LineageOS-20.0/release_keys//target_files/
FZIPINF="\n\tand the FACTORY zip here: /ssd/slim/zips/FP3/LineageOS-20.0/release_keys//target_files/${FZIP}-factory.zip\n"
cd /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0

# See: https://source.android.com/docs/security/features/verifiedboot/boot-flow 
FPID=$(cat user-keys/avb_pkmd.bin | openssl dgst -sha256 | cut -d "=" -f 2 | tr -d " " | tr "[[:lower:]]" "[[:upper:]]")
echo -e "\nBOOTLOADER minimal ID"
echo -e "\t${FPID:0:8}\n"
echo -e "BOOTLOADER full ID:"
echo -e "\t${FPID:0:16}"
echo -e "\t${FPID:16:16}"
echo -e "\t${FPID:32:16}"
echo -e "\t${FPID:48:16}\n"
out/host/linux-x86/bin/avbtool info_image --image out/target/product/FP3/vbmeta.img 2> /dev/null || true
out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/FP3/vbmeta.img 2> /dev/null \
    || (out/host/linux-x86/bin/avbtool info_image --image out/target/product/FP3/obj/PACKAGING/target_files_intermediates/lineage_FP3-target_files-eng.emy/IMAGES/vbmeta.img;\
        out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/FP3/obj/PACKAGING/target_files_intermediates/lineage_FP3-target_files-eng.emy/IMAGES/vbmeta.img)

echo -e "\n\nSUCCESS:\nYou should find your build here:\n/ssd/slim/zips/FP3/LineageOS-20.0/release_keys/\n${ZIPINF}"
