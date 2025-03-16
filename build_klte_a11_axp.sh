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
case a11 in
    a9|a10) source ~/.venv/python2/bin/activate ;;
esac

########################### BUILD #########################

# setup build env including stupid DOS workarounds
echo "BUILDHOME: /home/jenkins"
export HOME="/home/jenkins" && echo "home set to $HOME" >> /home/jenkins/build_klte_a11_axp_11.1.1.log
export BDEVICE="klte"
export PATH="/home/jenkins/.local/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ ! -L "$HOME/.local/bin/sh" ];then ln -s /bin/bash $HOME/.local/bin/sh; fi
if [ ! -L "$HOME/.local/bin/rename" ];then ln -s /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-18.1/rename $HOME/.local/bin/rename; fi
alias sh=/bin/bash
alias rename="/ssd2/androidsource/do-not-touch/axp/Build/LineageOS-18.1/rename"
cd /ssd2/androidsource/do-not-touch/axp/Build/LineageOS-18.1
source build/envsetup.sh >> /home/jenkins/build_klte_a11_axp_11.1.1.log 2>&1 && echo "sourcing envsetup: success" >> /home/jenkins/build_klte_a11_axp_11.1.1.log
source /ssd2/androidsource/do-not-touch/axp/Scripts/init.sh >> /home/jenkins/build_klte_a11_axp_11.1.1.log 2>&1 && echo "sourcing init: success" >> /home/jenkins/build_klte_a11_axp_11.1.1.log

# support A14 and later

        
breakfast lineage_klte${brf_suffix}-user

# CCACHE
export USE_CCACHE=1
if [ "1" -eq 1 ];then
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_COMPRESS=1
    mkdir -p /ssd/ccache/jenkins/a11
    export CCACHE_DIR="/ssd/ccache/jenkins/a11"
    /usr/bin/ccache --max-size=10G
fi

    # regular build process

    # extendrom flags
    export ENABLE_EXTENDROM=true
    export EXTENDROM_PACKAGES="AOSmium_webview32 additional_repos.xml AuroraStore F-Droid noeSpeakNG noDefaultBrowserWebView Etar_ER FossifyGallery"
    export EXTENDROM_FDROID_REPOS="molly.xml nailyk.xml threema.xml futo_org.xml cromite.xml izzysoft.xml microg.xml"
        export EXTENDROM_PREROOT_BOOT=false
    #export MAGISK_TARGET_ARCH=
    export EXTENDROM_BOOT_DEBUG=true
    export EXTENDROM_DEBUG_PATH=/cache
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

    echo "[GIT] checking kernel changes in kernel/samsung/msm8974"
    # add unstaged changes
    CMT=0
    cd kernel/samsung/msm8974
    git add -A || CMT=1
    # check for uncommitted changes
    CMTL=$(git status --porcelain=v1 | wc -l 2>/dev/null)
    # commit if required
    if [ $CMT -eq 1 -o $CMTL -gt 0 ];then 
       git commit --author="${AXP_GIT_AUTHOR} <${AXP_GIT_MAIL}>" -m "uncatched scripted change(s)"
       echo "[GIT] committed scripted kernel changes for kernel/samsung/msm8974" >> /home/jenkins/build_klte_a11_axp_11.1.1.log
    fi
    git status
    croot
  
    # build
    resetEnv
        mka generate_verity_key
            buildDevice klte
        
    echo -e "\n\nSUCCESS:\nYou should find your build here:\n/home/androidsource/ZIPs/slim/zips/klte/LineageOS-18.1/release_keys/\n${ZIPINF}"
    
