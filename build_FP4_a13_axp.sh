#!/bin/bash
####################################################################################################################   
# be strict on failures
set -e

# fix build errors
export LC_ALL=C

# unset any extendrom var
er_vars="ENABLE_EXTENDROM EXTENDROM_SIGNING_PATCHES EXTENDROM_SIGNING_FORCE_PDIR EXTENDROM_PACKAGES EXTENDROM_PACKAGES_SKIP_DL EXTENDROM_BOOT_DEBUG EXTENDROM_DEBUG_PATH EXTENDROM_DEBUG_PATH_SIZE_FULL EXTENDROM_DEBUG_PATH_SIZE_CRASH EXTENDROM_DEBUG_PATH_SIZE_KERNEL EXTENDROM_DEBUG_PATH_SIZE_SELINUX EXTENDROM_PREROOT_BOOT EXTENDROM_FDROID_REPOS EXTENDROM_SIGNATURE_SPOOFING EXTENDROM_ALLOW_ANY_CALL_RECORDING EXTENDROM_INTERCEPT_INSTALLSRC EXTENDROM_PATCHER_RESET EXTENDROM_SIGSPOOF_FORCE_PDIR"
for v in $er_vars;do unset $v;done

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
export HOME="/home/jenkins" && echo "home set to $HOME" >> /home/jenkins/build_FP4_a13_axp_13.0.12.log
export BDEVICE="FP4"
export PATH="/home/jenkins/.local/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ ! -L "$HOME/.local/bin/sh" ];then ln -s /bin/bash $HOME/.local/bin/sh; fi
if [ ! -L "$HOME/.local/bin/rename" ];then ln -s /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/rename $HOME/.local/bin/rename; fi
alias sh=/bin/bash
alias rename="/ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/rename"
cd /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0
source build/envsetup.sh >> /home/jenkins/build_FP4_a13_axp_13.0.12.log 2>&1 && echo "sourcing envsetup: success" >> /home/jenkins/build_FP4_a13_axp_13.0.12.log
source /ssd2/androidsource/do-not-touch/axp/Scripts/init.sh >> /home/jenkins/build_FP4_a13_axp_13.0.12.log 2>&1 && echo "sourcing init: success" >> /home/jenkins/build_FP4_a13_axp_13.0.12.log

# support A14 and later

        
breakfast lineage_FP4${brf_suffix}-user

# CCACHE
export USE_CCACHE=1
if [ "1" -eq 1 ];then
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_COMPRESS=1
    mkdir -p /ssd/ccache/jenkins/a13
    export CCACHE_DIR="/ssd/ccache/jenkins/a13"
    /usr/bin/ccache --max-size=10G
fi

    # regular build process

    # extendrom flags
    export ENABLE_EXTENDROM=true
    export EXTENDROM_PACKAGES="AOSmium_webview64 additional_repos.xml AuroraStore F-Droid noeSpeakNG noDefaultBrowserWebView Etar_ER FossifyGallery"
    export EXTENDROM_FDROID_REPOS="molly.xml nailyk.xml threema.xml futo_org.xml cromite.xml izzysoft.xml microg.xml"
        export EXTENDROM_PREROOT_BOOT=false
    #export MAGISK_TARGET_ARCH=
    export EXTENDROM_BOOT_DEBUG=true
    export EXTENDROM_DEBUG_PATH=/metadata
    export EXTENDROM_DEBUG_PATH_SIZE_FULL=500
    export EXTENDROM_DEBUG_PATH_SIZE_KERNEL=100
    export EXTENDROM_DEBUG_PATH_SIZE_SELINUX=200
    export EXTENDROM_DEBUG_PATH_SIZE_CRASH=200
    export EXTENDROM_SIGNATURE_SPOOFING=true
    export EXTENDROM_PATCHER_RESET=false
    export EXTENDROM_SIGNING_PATCHES=true
    export EXTENDROM_ALLOW_ANY_CALL_RECORDING=false
    export EXTENDROM_INTERCEPT_INSTALLSRC=false
    # execute extendrom
    $PWD/vendor/extendrom/er.sh

    echo "[GIT] checking kernel changes in kernel/fairphone/sm7225"
    # add unstaged changes
    CMT=0
    cd kernel/fairphone/sm7225
    git add -A || CMT=1
    # check for uncommitted changes
    CMTL=$(git status --porcelain=v1 | wc -l 2>/dev/null)
    # commit if required
    if [ $CMT -eq 1 -o $CMTL -gt 0 ];then 
       git commit --author="${AXP_GIT_AUTHOR} <${AXP_GIT_MAIL}>" -m "uncatched scripted change(s)"
       echo "[GIT] committed scripted kernel changes for kernel/fairphone/sm7225" >> /home/jenkins/build_FP4_a13_axp_13.0.12.log
    fi
    git status
    croot

    # when fairphone
        # get factory image
# containing the official Fairphone images + AXP.OS based on vendor/firmware/FP4/0SOURCE
VERSION="20.0-20250326-SLIM"
FZIP="AXP.OS-${VERSION}-FP4"
source vendor/firmware/FP4/0SOURCE
if [ -f out/FP4-factory.zip ];then rm out/FP4-factory.zip;fi
if [ -f "/home/androidsource/ZIPs/axp/persistent/FP4/${FACTORYFULLNAME}.zip" ];then
    echo "Using previously downloaded factory image: ${FACTORYFULLNAME}.zip"
    cp "/home/androidsource/ZIPs/axp/persistent/FP4/${FACTORYFULLNAME}.zip" out/FP4-factory.zip 
else
    echo "${FACTORYFULLNAME}.zip not found in: /home/androidsource/ZIPs/axp/persistent/FP4, downloading.."
    wget -q https://fairphone-android-builds.ams3.digitaloceanspaces.com/FP4/A13/${FACTORYFULLNAME}.zip -O out/FP4-factory.zip || (wget https://fairphone-android-builds.ams3.digitaloceanspaces.com/FP4/A13/${FACTORYFULLNAME}.zip -O out/FP4-factory.zip ; exit 9)
fi

export FACZIP="$PWD/out/FP4-factory.zip"
cd vendor/firmware/FP4
./rename.sh
croot

        
    # build
    resetEnv
        mka generate_verity_key
            buildDevice FP4

# cleanup
if [ -f /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/AXP.OS-${VERSION}-factory.zip ];then rm -vf /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/AXP.OS-${VERSION}-factory.zip;fi
if [ -f /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/${FZIP}-factory.zip ]; then rm -vf /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/${FZIP}-factory.zip;fi
if [ -d /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP4-factory/ ];then rm -rf /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP4-factory/;fi

# extract the origin factory zip
unzip /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP4-factory.zip -d /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP4-factory > /dev/null
IMAGES_PATH=images
export FPIMGPATH=$(dirname /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP4-factory/*/images/)/$IMAGES_PATH

# extract AXP.OS factory zip and override Fairphone images by AOS ones
REPLHASH=$(zipinfo -1 /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/target/product/FP4/${FZIP}-fastboot.zip '*.img')
unzip -o /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/target/product/FP4/${FZIP}-fastboot.zip -d ${FPIMGPATH} '*.img' > /dev/null

# ... and replace some non-standard ones with AOS ones
# FIXME!
if [ -f "${FPIMGPATH}/super_system.img" ];then
    mv -v ${FPIMGPATH}/system.img ${FPIMGPATH}/super_system.img
    REPLHASH=$(echo "$REPLHASH" | sed "s/system.img/super_system.img/g" )
fi
if [ -f "${FPIMGPATH}/super_vendor.img" ];then
    mv -v ${FPIMGPATH}/vendor.img ${FPIMGPATH}/super_vendor.img
    REPLHASH=$(echo "$REPLHASH" | sed "s/vendor.img/super_vendor.img/g" )
fi

avb_file="FP4_AXP.OS_avb_pkmd.bin"
if [ "slim" == "slim" ];then avb_file="FP4_AXP.OS-slim_avb_pkmd.bin";fi
cp /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/user-keys/avb_pkmd.bin ${FPIMGPATH}/$avb_file
croot

# add flashing-cmd for the AXP.OS avb key
cd ${FPIMGPATH} && cd ..
f=$(echo flash_fp*.command)
awk '{print} /^flash_device$/ && !n {print "sleep 5\n'"\${FASTBOOT_BIN}"' erase avb_custom_key\n'"\${FASTBOOT_BIN}"' flash avb_custom_key '\${IMAGES_DIR}'/'"$avb_file"'\n'"\${FASTBOOT_BIN}"' reboot-bootloader"; n++}' ${f} > ${f}.tmp && mv -v ${f}.tmp ${f} && chmod +x ${f}

# do not auto-lock by default
sed -i 's/^RELOCK_BOOTLOADER=.*/RELOCK_BOOTLOADER="false"/g' $f

# update checksums
for hfile in $REPLHASH;do
    echo "generating hash for: $hfile"
    newhash=$(sha256sum $IMAGES_PATH/$hfile | cut -d ' ' -f 1)
    sed -E "s#^(.*){64,}(\s)(.*$IMAGES_PATH/$hfile)#$newhash\2\3#g" -i SHA256SUMS
done
# add command file
CMDHASH=$(sha256sum $f | cut -d ' ' -f1)
sed -E "s#^(.*){64,}(\s)(.*$f)#$CMDHASH\2\3#g" -i SHA256SUMS

# test checksums
sha256sum --check SHA256SUMS

# test vbmeta
croot
out/host/linux-x86/bin/avbtool info_image --image ${FPIMGPATH}/vbmeta.img
out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image ${FPIMGPATH}/vbmeta.img

# re-package it
cd /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-20.0/out/FP4-factory/
zip -r ../${FZIP}-factory.zip .
cd ..
sha512sum ${FZIP}-factory.zip > ${FZIP}-factory.zip.sha512
mv -v ${FZIP}-factory.zip* /home/androidsource/ZIPs/slim/zips/FP4/LineageOS-20.0/release_keys//target_files/
FZIPINF="\n\tand the FACTORY zip here: /home/androidsource/ZIPs/slim/zips/FP4/LineageOS-20.0/release_keys//target_files/${FZIP}-factory.zip\n"
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
    out/host/linux-x86/bin/avbtool info_image --image out/target/product/FP4/vbmeta.img 2> /dev/null || true
    out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/FP4/vbmeta.img 2> /dev/null \
        || (out/host/linux-x86/bin/avbtool info_image --image out/target/product/FP4/obj/PACKAGING/target_files_intermediates/lineage_FP4-target_files-eng.emy/IMAGES/vbmeta.img;\
            out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/FP4/obj/PACKAGING/target_files_intermediates/lineage_FP4-target_files-eng.emy/IMAGES/vbmeta.img)
    
    echo -e "\n\nSUCCESS:\nYou should find your build here:\n/home/androidsource/ZIPs/slim/zips/FP4/LineageOS-20.0/release_keys/\n${ZIPINF}"
    
