#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# install-product.sh
#
#                     Package manager workhorse script for performing installs,
#                     upgrades or removals.
#
# Version: 5.0.5.57504
#==============================================================================
SCRIPT_NAME="install-product.sh"

if [ -z "${MAIN:-}" ];then
    echo "ERROR: Not main executable. Please run install.sh located at ISO root."
    exit 1
fi


CheckForAndRemoveOldVasutil()
{
    # - This section is needed for the 4.0.2 upgrade because the vasutil 
    #   package no longer exists, oat was merged into the vasclnt package.
    if [ -n "${VASUTIL_INSTALLED_VERSION}" ]; then

        # Removal of the old vasutil package on OSX is done in the 
        # %postup [macos] section of pkg-vasclnt.pp.in. 
        if [ ${HOST_OS_NAME} != "Darwin" ]; then
            remove "${VASUTIL_NAME}" "${VASUTIL_PATH}" "${VASUTIL_INSTALLED_VERSION}"
        fi
    fi
}

#=============================================================================#
#                                                                             #
#                             Main script body                                #
#                                                                             #
#=============================================================================#
operation=$1  # one of: { "install" ""upgrade" "remove" }
pkgName=$2    # { "vasclnt[s]" "vasgp[s]" "vasyp" "vasproxy" "vassc" etc. }
pkgPath=$3    # path to install package
pkgVersion=$4    # (used only by Tru64 to manufacture kit subset name)

. $COMMON_LIBRARY_SH

DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Entering install-product.sh(operation=$operation,pkgName=$pkgName,pkgPath=$pkgPath,pkgVersion=$pkgVersion)..."
DebugScript $SCRIPT_NAME "==="

# Run product specific install
case $pkgName in
    $VASSIEBELAD_NAME)
        case $operation in
            "install")
                install "$pkgName" "$pkgPath" "$pkgVersion"
                result=$?

                if [ $result -eq $SUCCESS ];then
                    case $INSTALL_MODE in
                        "simple"|"interactive")
                            if [ -x "$CONFIGURE_SIEBEL_SH" ];then
                                AskYesNo "\nDo you wish to configure the Siebel adapter now? " "yes"
                                if [ "x$askyesno" = "xyes" ];then
                                    printf "Running: $CONFIGURE_SIEBEL_SH\n"
                                    $CONFIGURE_SIEBEL_SH
                                    result=$?
                                    echo
                                fi
                            fi
                            ;;
                    esac
                fi
                ;;
            "upgrade")
                upgrade "$pkgName" "$pkgPath" "$pkgVersion"
                result=$?
                ;;
            "remove")
                remove "$pkgName" "$pkgPath" "$pkgVersion"
                result=$?
                ;;
        esac
        ;;

    $MOD_AUTH_VAS_20_NAME|$MOD_AUTH_VAS_22_NAME)
        case $operation in
            "install")
                install "$pkgName" "$pkgPath" "$pkgVersion"

                GetInstalledInformation
                if [ "x$MOD_AUTH_VAS_20_INSTALLED_VERSION" = "x$pkgVersion" -o "x$MOD_AUTH_VAS_22_INSTALLED_VERSION" = "x$pkgVersion" ];then
                    result=$SUCCESS
                else
                    case $HOST_OS_DISTRO in
                        "Debian"|"Ubuntu") dpkg -P $pkgName ;;
                    esac
                    result=$FAILURE
                fi

                if [ $result -eq $SUCCESS ];then
                    case $INSTALL_MODE in
                        "simple"|"interactive")
                            if [ -x "$CONFIGURE_MAV" ];then
                                AskYesNo "\nDo you wish to configure apache for mod_auth_vas now? " "yes"
                                if [ "x$askyesno" = "xyes" ];then
                                    printf "Running: $CONFIGURE_MAV\n"
                                    $CONFIGURE_MAV
                                    echo
                                fi
                            fi

                            if [ -x "$CONFIGURE_SIEBEL_SH" ];then
                                AskYesNo "\nDo you wish to configure mod_auth_vas for siebel now? " "yes"
                                if [ "x$askyesno" = "xyes" ];then
                                    printf "Running: $CONFIGURE_SIEBEL_SH\n"
                                    $CONFIGURE_SIEBEL_SH
                                    echo
                                fi
                            fi
                            ;;
                    esac
                fi
                ;;
            "upgrade")
                upgrade "$pkgName" "$pkgPath" "$pkgVersion"

                GetInstalledInformation
                if [ "x$MOD_AUTH_VAS_20_INSTALLED_VERSION" = "x$pkgVersion" -o "x$MOD_AUTH_VAS_22_INSTALLED_VERSION" = "x$pkgVersion" ];then
                    result=$SUCCESS
                else
                    result=$FAILURE
                fi
                ;;
            "remove")
                remove "$pkgName" "$pkgPath" "$pkgVersion"

                GetInstalledInformation
                if [ "x$MOD_AUTH_VAS_20_INSTALLED_VERSION" = "x$pkgVersion" -o "x$MOD_AUTH_VAS_22_INSTALLED_VERSION" = "x$pkgVersion" ];then
                    result=$FAILURE
                else
                    result=$SUCCESS
                fi
                ;;
        esac
        ;;

    $VASCLNT_NAME|$VASCLNTS_NAME)
        case $operation in
            "install")
                CheckForAndRemoveOldVasutil

                install "$pkgName" "$pkgPath" "$pkgVersion"

                GetInstalledInformation
                if [ "x$VASCLNT_INSTALLED_VERSION" = "x$pkgVersion" -o "x$VASCLNTS_INSTALLED_VERSION" = "x$pkgVersion" ];then
                    result=$SUCCESS
                else
                    result=$FAILURE
                fi
                ;;
            "upgrade")
                CheckForAndRemoveOldVasutil

                upgrade "$pkgName" "$pkgPath" "$pkgVersion"

                GetInstalledInformation
                if [ "x$VASCLNT_INSTALLED_VERSION" = "x$pkgVersion" -o "x$VASCLNTS_INSTALLED_VERSION" = "x$pkgVersion" ];then
                    result=$SUCCESS
                else
                    result=$FAILURE
                fi
                ;;
            "remove")
                remove "$pkgName" "$pkgPath" "$pkgVersion"

                GetInstalledInformation
                if [ "x$VASCLNT_INSTALLED_VERSION" = "x$pkgVersion" -o "x$VASCLNTS_INSTALLED_VERSION" = "x$pkgVersion" ];then
                    result=$FAILURE
                else
                    result=$SUCCESS
                fi
                ;;
        esac
        ;;

    # All other products
    *)
        case $operation in
            "install")
                install "$pkgName" "$pkgPath" "$pkgVersion"
                result=$?
                ;;
            "upgrade")
                upgrade "$pkgName" "$pkgPath" "$pkgVersion"
                result=$?
                ;;
            "remove")
                remove "$pkgName" "$pkgPath" "$pkgVersion"
                result=$?
                ;;
        esac
        ;;
esac

DebugScript $SCRIPT_NAME "Returns: $result"
DebugScript $SCRIPT_NAME "==="
exit $result
