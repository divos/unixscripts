#!/bin/sh
################################################################
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# init.sh
#
#   The purpose of this script is simply to initialize a whole
#   bunch of variables that will be used throughout the install
#   process. This should be sourced in the main script only once.
#
# Version: 5.0.5.57504
################################################################

set -u    # this catches uninitialized variables as soon as they're encountered

# Would prefer 077, but Solaris x86 doesn't like it. Bug 775534.
umask 022 > /dev/null

# Global Variables
set -a
    # Constants
           TRUE=0
          FALSE=1
        SUCCESS=0
        FAILURE=1
        # for dumb 'tr' versions
        LOWER='abcdefghijklmnopqrstuvwxyz'
        UPPER='ABCDEFGHIJKLMNOPQRSTUVWXYZ'

    # State
                 MAIN=$TRUE
       TRACEFILE_PATH=
             ISO_PATH=$WORKING_DIRECTORY
            EULA_READ=$FALSE
     PREFLIGHT_STATUS="NOT RUN"

    # Command line options
         INSTALL_MODE="simple"
 CMDLINE_LICENSE_FILE=
                DEBUG=$FALSE
              PATCHED=$TRUE

    # OS INFO
        HOST_OS_NAME=
     HOST_OS_VERSION=
      HOST_OS_DISTRO=
      HOST_OS_KERNEL=
       HOST_HARDWARE=
       HOST_PKG_PATH=
           HOST_NAME=`hostname`

    # Script File Paths
           INSTALL_SH="$WORKING_DIRECTORY/install.sh"

               CHECK_OS_SH="$WORKING_DIRECTORY/client/install-sh-data/check-os.sh"
        GET_VAS_OS_CODE_SH="$WORKING_DIRECTORY/client/install-sh-data/get-vas-os-code.sh"
          CHECK_PATCHES_SH="$WORKING_DIRECTORY/client/install-sh-data/check-patches.sh"
           COMMON_DEBUG_SH="$WORKING_DIRECTORY/client/install-sh-data/common-debug.sh"
         COMMON_LIBRARY_SH="$WORKING_DIRECTORY/client/install-sh-data/common-library.sh"
     INSTALL_ARGS_HELP_TXT="$WORKING_DIRECTORY/client/install-sh-data/install-args-help.txt"
          INSTALL_HELP_TXT="$WORKING_DIRECTORY/client/install-sh-data/install-help.txt"
        INSTALL_PRODUCT_SH="$WORKING_DIRECTORY/client/install-sh-data/install-product.sh"
    INTERACTIVE_INSTALL_SH="$WORKING_DIRECTORY/client/install-sh-data/interactive-install.sh"

    SCRIPTS="\
        $INSTALL_SH \
        $CHECK_OS_SH \
        $GET_VAS_OS_CODE_SH \
        $CHECK_PATCHES_SH \
        $COMMON_DEBUG_SH \
        $COMMON_LIBRARY_SH \
        $INSTALL_PRODUCT_SH  \
        $INTERACTIVE_INSTALL_SH"
    TEXTS="\
        $INSTALL_ARGS_HELP_TXT \
        $INSTALL_HELP_TXT"

          VASJOIN_SH="/opt/quest/libexec/vas/scripts/vasjoin.sh"
 CONFIGURE_SIEBEL_SH="/opt/quest/libexec/vas/scripts/siebel/configure_siebel_adapter.sh"
       CONFIGURE_MAV="/opt/quest/sbin/setup-mod_auth_vas"
             VASTOOL=/opt/quest/bin/vastool
             VGPTOOL=/opt/quest/bin/vgptool
           DNSUPDATE=/opt/quest/sbin/dnsupdate
             VASCERT=/opt/quest/bin/vascert
                 OAT=/opt/quest/libexec/oat/oat
    VAS_LICENSE_PATH="/etc/opt/quest"

    # Package Names, versions, and paths
                     VASCLNTS_NAME="vasclnts"
                     VASCLNTS_DESC="Safeguard Authentication Services (SITE)"
                 VASCLNTS_ISO_PATH="client"
                  VASCLNTS_VERSION=
                     VASCLNTS_PATH=
        VASCLNTS_INSTALLED_VERSION=

                     VASCLNT_NAME="vasclnt"
                     VASCLNT_DESC="Safeguard Authentication Services"
                 VASCLNT_ISO_PATH="client"
                  VASCLNT_VERSION=
                     VASCLNT_PATH=
        VASCLNT_INSTALLED_VERSION=

                      VASGPS_NAME="vasgps"
                      VASGPS_DESC="Safeguard Group Policy (SITE)"
                  VASGPS_ISO_PATH="client"
                   VASGPS_VERSION=
                      VASGPS_PATH=
         VASGPS_INSTALLED_VERSION=

                       VASGP_NAME="vasgp"
                       VASGP_DESC="Safeguard Group Policy"
                   VASGP_ISO_PATH="client"
                    VASGP_VERSION=
                       VASGP_PATH=
          VASGP_INSTALLED_VERSION=

                       VASYP_NAME="vasyp"
                       VASYP_DESC="Safeguard NIS Proxy"
                   VASYP_ISO_PATH="client"
                    VASYP_VERSION=
                       VASYP_PATH=
          VASYP_INSTALLED_VERSION=

                    VASPROXY_NAME="vasproxy"
                    VASPROXY_DESC="Safeguard LDAP Proxy"
                VASPROXY_ISO_PATH="client"
                 VASPROXY_VERSION=
                    VASPROXY_PATH=
       VASPROXY_INSTALLED_VERSION=

                    # needed to detect/remove old vasutil packages
                     VASUTIL_NAME="vasutil"
                     VASUTIL_DESC="Safeguard Ownership Alignment Tool"
                 VASUTIL_ISO_PATH="client"
                  VASUTIL_VERSION=
                     VASUTIL_PATH=
        VASUTIL_INSTALLED_VERSION=

                     VASCERT_NAME="vascert"
                     VASCERT_DESC="Safeguard Certificate Autoenrollment SDK"
                 VASCERT_ISO_PATH="client"
                  VASCERT_VERSION=
                     VASCERT_PATH=
        VASCERT_INSTALLED_VERSION=

                      VASDEV_NAME="vasdev"
                      VASDEV_DESC="Safeguard Authentication Services SDK"
                  VASDEV_ISO_PATH="client"
                   VASDEV_VERSION=
                      VASDEV_PATH=
         VASDEV_INSTALLED_VERSION=

                       VASSC_NAME="vassc"
                       VASSC_DESC="Safeguard Smartcard Plugin"
                   VASSC_ISO_PATH="add-ons/smartcard"
                    VASSC_VERSION=
                       VASSC_PATH=
          VASSC_INSTALLED_VERSION=

                 VASSIEBELAD_NAME="vassiebelad"
                 VASSIEBELAD_DESC="Safeguard Siebel Plugin"
             VASSIEBELAD_ISO_PATH="add-ons/siebel"
              VASSIEBELAD_VERSION=
                 VASSIEBELAD_PATH=
    VASSIEBELAD_INSTALLED_VERSION=

                        DDNS_NAME="dnsupdate"
                        DDNS_DESC="Safeguard Dynamic DNS Update"
                    DDNS_ISO_PATH="client"
                     DDNS_VERSION=
                        DDNS_PATH=
           DDNS_INSTALLED_VERSION=

                    OLD_DDNS_NAME="quest-dnsupdate"
                    OLD_DDNS_DESC="Old Dynamic DNS Update"
                OLD_DDNS_ISO_PATH="client"
                 OLD_DDNS_VERSION=
                    OLD_DDNS_PATH=
       OLD_DDNS_INSTALLED_VERSION=

             MOD_AUTH_VAS_20_NAME="quest-mav-ap20"
             MOD_AUTH_VAS_20_DESC="Safeguard Apache 2.0 SSO Plugin"
         MOD_AUTH_VAS_20_ISO_PATH="add-ons/siebel"
          MOD_AUTH_VAS_20_VERSION=
             MOD_AUTH_VAS_20_PATH=
MOD_AUTH_VAS_20_INSTALLED_VERSION=

             MOD_AUTH_VAS_22_NAME="quest-mav-ap22"
             MOD_AUTH_VAS_22_DESC="Safeguard Apache 2.2 SSO Plugin"
         MOD_AUTH_VAS_22_ISO_PATH="add-ons/siebel"
          MOD_AUTH_VAS_22_VERSION=
             MOD_AUTH_VAS_22_PATH=
MOD_AUTH_VAS_22_INSTALLED_VERSION=

                    DEFENDER_NAME="pamdefender"
                    DEFENDER_DESC="Safeguard Defender Pam Module"
                DEFENDER_ISO_PATH="client"
                 DEFENDER_VERSION=
                    DEFENDER_PATH=
       DEFENDER_INSTALLED_VERSION=

                     VASPRE_NAME="preflight"
                     VASPRE_DESC="Safeguard Preflight Utility"
                 VASPRE_ISO_PATH="client"
                     VASPRE_PATH=

    PRODUCT_CODES="\
        VASCLNT \
        VASCLNTS \
        VASGP \
        VASGPS \
        VASYP \
        VASPROXY \
        VASCERT \
        VASDEV \
        VASSC \
        VASSIEBELAD \
        DDNS \
        OLD_DDNS \
        MOD_AUTH_VAS_22 \
        MOD_AUTH_VAS_20 \
        DEFENDER"
set +a
