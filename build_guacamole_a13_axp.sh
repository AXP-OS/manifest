#!/bin/bash
####################################################################################################################   
# be strict on failures
set -e

# fix build errors
export LC_ALL=C

# unset any extendrom var
er_vars="ENABLE_EXTENDROM EXTENDROM_SIGNING_PATCHES EXTENDROM_SIGNING_FORCE_PDIR EXTENDROM_PACKAGES EXTENDROM_PACKAGES_SKIP_DL EXTENDROM_BOOT_DEBUG EXTENDROM_DEBUG_PATH EXTENDROM_DEBUG_PATH_SIZE_FULL EXTENDROM_DEBUG_PATH_SIZE_CRASH EXTENDROM_DEBUG_PATH_SIZE_KERNEL EXTENDROM_DEBUG_PATH_SIZE_SELINUX EXTENDROM_PREROOT_BOOT EXTENDROM_FDROID_REPOS EXTENDROM_SIGNATURE_SPOOFING EXTENDROM_ALLOW_ANY_CALL_RECORDING EXTENDROM_INTERCEPT_INSTALLSRC EXTENDROM_PATCHER_RESET EXTENDROM_SIGSPOOF_FORCE_PDIR"
for v in $er_vars;do unset $v;done

# unset low-end def
unset AXP_LOWEND_DEVICE

########################### BUILD #########################


# setup build env including stupid DOS workarounds
echo "BUILDHOME: /home/droidme"
export HOME="/home/droidme" && echo "home set to $HOME" >> /home/droidme/build_guacamole_axp_2025-09.1.log
export BDEVICE="guacamole"
export PATH="/home/droidme/.local/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export TMPDIR="/usr/src/android/.tmp"
if [ ! -L "$HOME/.local/bin/sh" ];then ln -s /bin/bash $HOME/.local/bin/sh; fi
if [ ! -L "$HOME/.local/bin/rename" ];then ln -s /usr/src/android/axp/Build/LineageOS-20.0/rename $HOME/.local/bin/rename; fi
alias sh=/bin/bash
alias rename="/usr/src/android/axp/Build/LineageOS-20.0/rename"
gpg --list-secret-keys >> /home/droidme/build_guacamole_axp_2025-09.1.log 2>&1 || true

cd /usr/src/android/axp/Build/LineageOS-20.0
source build/envsetup.sh >> /home/droidme/build_guacamole_axp_2025-09.1.log 2>&1 && echo "sourcing envsetup: success" >> /home/droidme/build_guacamole_axp_2025-09.1.log
source /usr/src/android/axp/Scripts/init.sh >> /home/droidme/build_guacamole_axp_2025-09.1.log 2>&1 && echo "sourcing init: success" >> /home/droidme/build_guacamole_axp_2025-09.1.log

# set target release (see common/defaults)

# set advanced deblobbing on A15 and later
if [ 13 -ge 15 ];then
    export AXP_ADVANCED_DEBLOB=true
else
    unset AXP_ADVANCED_DEBLOB
fi


# ensure vendor secpatch date is set
source vendor/firmware/guacamole/0SOURCE  >> /home/droidme/build_guacamole_axp_2025-09.1.log 2>&1 || true
        
breakfast lineage_guacamole${brf_suffix}-user >> /home/droidme/build_guacamole_axp_2025-09.1.log 2>&1

# CCACHE
export USE_CCACHE=1
if [ "1" -eq 1 ];then
    export CCACHE_EXEC=/usr/bin/ccache
    export PATH="/usr/lib/ccache/:$PATH"
    export CCACHE_NOCOMPRESS=1
    unset CCACHE_COMPRESS
    mkdir -p /ccache/a13
    export CCACHE_DIR="/ccache/a13"
    /usr/bin/ccache --max-size=100G
fi

f_detect_kerr(){
    set +e
    resetEnv
    vendor/axp/scripts/find_cve_error.sh --parse -k kernel/oneplus/sm8150 -L /home/droidme/build_guacamole_axp_2025-09.1.log
    exit 5
}

    # regular build process

    # extendrom flags
    export ENABLE_EXTENDROM=true
    export EXTENDROM_PACKAGES="AOSmium_webview64 additional_repos.xml AuroraStore F-Droid noeSpeakNG noDefaultBrowserWebView Etar_ER FossifyGallery GsfProxy_GH Magisk MicrogGmsCore_GH Phonesky_AXP-OS NeoLauncher-latest"
    export EXTENDROM_FDROID_REPOS="axpos.xml molly.xml nailyk.xml threema.xml futo_org.xml cromite.xml ironfox.xml izzysoft.xml"
        export EXTENDROM_PREROOT_BOOT=true
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
    export EXTENDROM_ALLOW_ANY_CALL_RECORDING=true
    export EXTENDROM_INTERCEPT_INSTALLSRC=false
    # execute extendrom
    $PWD/vendor/extendrom/er.sh

    echo "[GIT] checking kernel changes in kernel/oneplus/sm8150"
    # add unstaged changes
    CMT=0
    cd kernel/oneplus/sm8150
    git add -A || CMT=1
    # check for uncommitted changes
    CMTL=$(git status --porcelain=v1 | wc -l 2>/dev/null)
    # commit if required
    if [ $CMT -eq 1 -o $CMTL -gt 0 ];then 
       git commit -S --author="${AXP_GIT_AUTHOR} <${AXP_GIT_MAIL}>" -m "uncatched scripted change(s)"
       echo "[GIT] committed scripted kernel changes for kernel/oneplus/sm8150" >> /home/droidme/build_guacamole_axp_2025-09.1.log
    fi
    git status
    croot
    
    # build
    resetEnv
    
    #### LEGACY PYTHON #########################
    case a13 in
      a9|a10) source ~/.venv/python2/bin/activate ;;
    esac

        mka generate_verity_key
            buildDevice guacamole || f_detect_kerr
            # See: https://source.android.com/docs/security/features/verifiedboot/boot-flow 
    FPID=$(cat user-keys/avb_pkmd.bin | openssl dgst -sha256 | cut -d "=" -f 2 | tr -d " " | tr "[[:lower:]]" "[[:upper:]]")
    echo -e "\nBOOTLOADER minimal ID"
    echo -e "\t${FPID:0:8}\n"
    echo -e "BOOTLOADER full ID:"
    echo -e "\t${FPID:0:16}"
    echo -e "\t${FPID:16:16}"
    echo -e "\t${FPID:32:16}"
    echo -e "\t${FPID:48:16}\n"
    out/host/linux-x86/bin/avbtool info_image --image out/target/product/guacamole/vbmeta.img 2> /dev/null || true
    out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/guacamole/vbmeta.img 2> /dev/null \
        || (out/host/linux-x86/bin/avbtool info_image --image out/target/product/guacamole/obj/PACKAGING/target_files_intermediates/lineage_guacamole-target_files*/IMAGES/vbmeta.img;\
            out/host/linux-x86/bin/avbtool verify_image --follow_chain_partitions --image out/target/product/guacamole/obj/PACKAGING/target_files_intermediates/lineage_guacamole-target_files*/IMAGES/vbmeta.img)
    
    #gpg --homedir "$DOS_SIGNING_GPG" --sign --local-user "$DOS_GPG_SIGNING_KEY" --detach-sign --armor ...
    echo -e "\n\nSUCCESS:\nYou should find your build here:\n/usr/src/android/zips/guacamole/axp/zips/guacamole/LineageOS-20.0/release_keys/\n${ZIPINF}"
    
