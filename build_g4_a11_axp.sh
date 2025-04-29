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
# this is a low-end device (optimize for performance)
export AXP_LOWEND_DEVICE=True

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
export HOME="/home/jenkins" && echo "home set to $HOME" >> /home/jenkins/build_h815_axp_10.11.2.log
export BDEVICE="h815"
export PATH="/home/jenkins/.local/bin:$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
if [ ! -L "$HOME/.local/bin/sh" ];then ln -s /bin/bash $HOME/.local/bin/sh; fi
if [ ! -L "$HOME/.local/bin/rename" ];then ln -s /ssd2/aos/Build/LineageOS-18.1/rename $HOME/.local/bin/rename; fi
alias sh=/bin/bash
alias rename="/ssd2/aos/Build/LineageOS-18.1/rename"
cd /ssd2/aos/Build/LineageOS-18.1
source build/envsetup.sh >> /home/jenkins/build_h815_axp_10.11.2.log 2>&1 && echo "sourcing envsetup: success" >> /home/jenkins/build_h815_axp_10.11.2.log
source /ssd2/aos/Scripts/init.sh >> /home/jenkins/build_h815_axp_10.11.2.log 2>&1 && echo "sourcing init: success" >> /home/jenkins/build_h815_axp_10.11.2.log

# support A14 and later

        
breakfast lineage_h815${brf_suffix}-user

# CCACHE
export USE_CCACHE=1
if [ "1" -eq 1 ];then
    export CCACHE_EXEC=/usr/bin/ccache
    export CCACHE_COMPRESS=1
    mkdir -p /ssd/ccache/jenkins/a11
    export CCACHE_DIR="/ssd/ccache/jenkins/a11"
    /usr/bin/ccache --max-size=10G
fi

f_detect_kerr(){
    set +e
    resetEnv
    vendor/axp/scripts/find_cve_error.sh --parse -k kernel/lge/msm8992 -L /home/jenkins/build_h815_axp_10.11.2.log
    exit 5
}

    # regular build process

    # extendrom flags
    export ENABLE_EXTENDROM=true
    export EXTENDROM_PACKAGES="AOSmium_webview64 additional_repos.xml AuroraStore F-Droid noeSpeakNG noDefaultBrowserWebView Etar_ER FossifyGallery GsfProxy_GH Magisk MicrogGmsCore_GH NeoLauncher-latest Phonesky_AXP-OS"
    export EXTENDROM_FDROID_REPOS="molly.xml nailyk.xml threema.xml futo_org.xml cromite.xml izzysoft.xml"
        export EXTENDROM_PREROOT_BOOT=true
    #export MAGISK_TARGET_ARCH=
    export EXTENDROM_BOOT_DEBUG=true
    export EXTENDROM_DEBUG_PATH=/persist
    export EXTENDROM_DEBUG_PATH_SIZE_FULL=500
    export EXTENDROM_DEBUG_PATH_SIZE_KERNEL=100
    export EXTENDROM_DEBUG_PATH_SIZE_SELINUX=200
    export EXTENDROM_DEBUG_PATH_SIZE_CRASH=200
    export EXTENDROM_SIGNATURE_SPOOFING=true
    export EXTENDROM_PATCHER_RESET=false
    export EXTENDROM_SIGNING_PATCHES=true
    export EXTENDROM_ALLOW_ANY_CALL_RECORDING=true
    export EXTENDROM_INTERCEPT_INSTALLSRC=true
    # execute extendrom
    $PWD/vendor/extendrom/er.sh

    echo "[GIT] checking kernel changes in kernel/lge/msm8992"
    # add unstaged changes
    CMT=0
    cd kernel/lge/msm8992
    git add -A || CMT=1
    # check for uncommitted changes
    CMTL=$(git status --porcelain=v1 | wc -l 2>/dev/null)
    # commit if required
    if [ $CMT -eq 1 -o $CMTL -gt 0 ];then 
       git commit --author="${AXP_GIT_AUTHOR} <${AXP_GIT_MAIL}>" -m "uncatched scripted change(s)"
       echo "[GIT] committed scripted kernel changes for kernel/lge/msm8992" >> /home/jenkins/build_h815_axp_10.11.2.log
    fi
    git status
    croot

    # when fairphone
        
    # build
    resetEnv
            buildDevice h815 || f_detect_kerr
        
    echo -e "\n\nSUCCESS:\nYou should find your build here:\n/home/androidsource/ZIPs/axp/zips/h815/LineageOS-18.1/release_keys/\n${ZIPINF}"
    
