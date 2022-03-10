#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# common-library.sh
#
#                   Functions to help installation scripts. This script is
#                   merely included by others.
#
# Version: 5.0.5.57504
#==============================================================================
if [ -z "${MAIN:-}" ];then
    echo "ERROR: Not main executable. Please run install.sh located at ISO root."
    exit 1
fi

. $COMMON_DEBUG_SH
. $CHECK_OS_SH
. $GET_VAS_OS_CODE_SH

SCRIPT_NAME="common-library.sh"

SetPager ()
{
    # Hoop-jumping to avoid bombing if `set -u` is enabled.
    if [ "${PAGER:-notset}" != "notset"  ]; then
        return
    fi

    for trypager in 'less' 'more'; do
        PAGER=`which "$trypager" 2> /dev/null | grep '^/'`
        if [ -n "$PAGER" ]; then
            return
        fi
    done

    PAGER=more
}

SetPager

GetProductCodeOut=
###########################################
#  Get Product Code from product name
#
#  Input:
#       productName     - name of product to find code for
#
#  Output:
#       getProductCodeOut=<productCode>
#
###########################################
GetProductCode()
{
    productName=${1:-}

    GetProductCodeOut=
    for code in $PRODUCT_CODES VASUTIL;do
        product=`eval echo \\$${code}_NAME`

        product=`echo $product | tr "$UPPER" "$LOWER"`
        productName=`echo $productName | tr "$UPPER" "$LOWER"`
        if [ "x$product" = "x$productName" ];then
            GetProductCodeOut=$code
            break
        fi
    done
}

###########################################
#  Simply prints out help information
#
#  Input:
#       help_mode  - "full-help", "arg-help", or "version"
#
###########################################
DoHelp()
{
    help_mode=${1:-"arg-help"}

    DebugScript $SCRIPT_NAME "  "
    DebugScript $SCRIPT_NAME "DoHelp(help_mode=$help_mode)"
    DebugScript $SCRIPT_NAME "---"

    case "$help_mode" in
        "full-help")
            $PAGER $INSTALL_HELP_TXT
            ;;
        "arg-help")
            cat $INSTALL_ARGS_HELP_TXT
            ;;
        "version")
            ;;
    esac

    # List all available products on the iso.
    printf "\nChecking for available software..."
    UpdatePlatformInfo
    GetIsoInformation
    printf "Done\n"

    echo
    echo "Products available:"
    echo "================================================================"
    for productCode in $PRODUCT_CODES;do
        product=`eval echo \\$${productCode}_NAME`
        pkgVersion=`eval echo \\$${productCode}_VERSION`
        pkgDesc=`eval echo \\$${productCode}_DESC`

        if [ -n "$pkgVersion" ];then
            printf "\t%-25s(%-9s)\t%s\n" "$product" "$pkgVersion" "$pkgDesc"
        fi
    done

    DebugScript $SCRIPT_NAME "---"
}

################################################################
# Ask a yes/no question with a default and wait for a response
#
# Input:
#     prompt
#     default   - "yes" or "no"
#
# Output:
#     askyesno="yes" or "no"
#
################################################################
askyesno=
AskYesNo()
{
    yn_prompt="$1 (yes|no)?"            # the basic prompt
    yn_default=$2                       # the default (if any)
    yn_answer=

    DebugScript $SCRIPT_NAME "  "
    DebugScript $SCRIPT_NAME "AskYesNo(prompt=$yn_prompt,default=$yn_default)"
    DebugScript $SCRIPT_NAME "---"

    # Get a formalized response of yes or no to a binary-response question. This
    # is the first implementation of the Vintela standard for yes/no prompt and
    # response.
    if [ -n "$yn_default" ]; then       # add the default to prompt
        yn_prompt="$yn_prompt [$yn_default]: "
    else
        yn_prompt="$yn_prompt "
    fi

    until [ -z "$yn_prompt" ]; do
        printf "\n$yn_prompt"; read yn_answer

        yn_answer=`echo $yn_answer | tr "$UPPER" "$LOWER"`
        case $yn_answer in
            # we'll accept all of these as valid responses...
            "yes") askyesno="yes" ; yn_prompt= ;;
              "y") askyesno="yes" ; yn_prompt= ;;
             "no") askyesno="no"  ; yn_prompt= ;;
              "n") askyesno="no"  ; yn_prompt= ;;
                *)
                # if default, don't require answer...
                if [ -z "$yn_answer" ]; then
                    if [ -n "$yn_default" ]; then
                        yn_prompt=
                        askyesno=$yn_default
                    fi
                fi
                # bogus answers don't count as...
                # ...taking the default!
                ;;
        esac
    done

    DebugScript $SCRIPT_NAME "Return: askyesno=$askyesno"
    DebugScript $SCRIPT_NAME "---"
}

######################################################
# Prompt and wait for a response
#
# Input:
#   prompt
#
# Output:
#   prompt_answer=<response>
#
######################################################
prompt_answer=
PromptForResponse()
{
    __prompt=${1:-}
    prompt_answer=

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "PromptForResponse(prompt=$__prompt)"
    DebugScript $SCRIPT_NAME "---"

    printf "$__prompt"; read prompt_answer

    DebugScript $SCRIPT_NAME "Return: prompt_answer='$prompt_answer'"
    DebugScript $SCRIPT_NAME "---"
}


######################################################
# Present eula and ask for agreement
#
#   Output:
#       EULA_READ=$TRUE else exit script
#
######################################################
ConfirmEula()
{
    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "ConfirmEula()"
    DebugScript $SCRIPT_NAME "---"

    EULA_TXT="$ISO_PATH/eula.txt"

# This can be called any time, from anywhere. When done, check $eula_read to
# see if we can continue. We only need to do this once per invocation of this
# script.
    case $INSTALL_MODE in
        "simple"|"interactive")
            if [ $EULA_READ -ne $TRUE -a -f "$EULA_TXT" ]; then
                $PAGER $EULA_TXT
                echo
                AskYesNo "Do you accept the One Identity LLC. agreement" "no"

                if [ "x$askyesno" = "xno" ]; then
                    printf "\nERROR: Note: You must accept the license agreement to continue!"
                    ExitInstall 1 "ConfirmEula, line ${LINENO:-?}"
                else
                    EULA_READ=$TRUE
                fi
            fi
            ;;
    esac
    DebugScript $SCRIPT_NAME "Return: EULA_READ=$EULA_READ"
    DebugScript $SCRIPT_NAME "---"
}

######################################################
# Run vasjoin.sh script
######################################################
DoVasJoin()
{
    result=$FAILURE
    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "DoVasJoin()"
    DebugScript $SCRIPT_NAME "---"

    if [ -z "$VASCLNT_INSTALLED_VERSION" -a -z "$VASCLNTS_INSTALLED_VERSION" ];then
        printf "Please install SAS before joining\n"
        return
    fi
    if [ ! -x "$VASJOIN_SH" ];then
        printf "vasjoin.sh script not available\n"
        return
    fi

    joinOptions=
    case $INSTALL_MODE in
        "simple"|"unattended")
            joined=`$VASTOOL -u host/ info id 2> /dev/null`
            if [ -n "$joined" ];then
                printf "Already joined to domain (%s)\n" "`$VASTOOL info domain`"
                AskYesNo "\nWould you like to join a different domain" "no"
            else
                AskYesNo "\nWould you like to join an Active Directory domain now" "yes"
            fi

            if [ "x$askyesno" = "xno" ]; then
                return
            fi
            ;;
        "interactive")
            joinOptions="-i"
            ;;
    esac

    if [ -x "$VASJOIN_SH" ];  then
        DebugScript $SCRIPT_NAME "calling $VASJOIN_SH()"

        printf "$VASJOIN_SH $joinOptions"
        $VASJOIN_SH $joinOptions
        if [ $? -eq $SUCCESS ]; then
             result=$SUCCESS
        fi
    else
        printf "\nERROR: Script $VASJOIN_SH was not properly installed!\n"
    fi
    echo
    DebugScript $SCRIPT_NAME "---"
    return $result
}

######################################################
# Run preflight binary
#
#   Input:
#       options     - options to pass to preflight
#
######################################################
DoPreflight()
{
    __options=${*:-}
    do_timesync=

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "DoPreflight(options=$__options)"
    DebugScript $SCRIPT_NAME "---"

    if [ -z "$VASPRE_PATH" -o ! -x "$VASPRE_PATH" ]; then
        printf "\nERROR: preflight binary is not yet available or improperly installed!\n"
        return
    fi

    if [ "x$__options" = "x--short-help" ]; then
        $VASPRE_PATH --short-help
        return
    fi

    if [ -z "$__options" ]; then
        PromptForResponse "\nEnter an Active Directory domain: "
        domain_name=$prompt_answer

        PromptForResponse  "Enter an Active Directory user with administrator privileges: "
        username=$prompt_answer

        AskYesNo "Report all results (default: only advisories and failures)" "no"

        __options=""
        if [ "x$askyesno" != "xno" ]; then
            __options="$__options --verbose"
        fi
        if [ "x$username" != "x" ]; then
            __options="$__options -u $username"
        fi
        if [ "x$domain_name" != "x" ]; then
            __options="$__options $domain_name"
        fi
        echo "--------------------------------------------------------------------------------"
    fi

    # Call preflight
    DebugScript $SCRIPT_NAME "calling $VASPRE_PATH: $VASPRE_PATH $__options"
    printf "$VASPRE_PATH $__options\n"
    $VASPRE_PATH $__options
    
    if [ $? -eq 0 ];then
        PREFLIGHT_STATUS="PASSED"
    else
        PREFLIGHT_STATUS="FAILED"
    fi

    DebugScript $SCRIPT_NAME "---"
}


######################################################
# Copy license file to SAS license directory
#
#   Input:
#       license     Path to license file
#
######################################################
CopyKnownLicenseFile()
{
    license=${1:-}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CopyLicenseFile(license=$license)"
    DebugScript $SCRIPT_NAME "---"

    if [ -z "$VASCLNT_INSTALLED_VERSION" -a -z "$VASCLNTS_INSTALLED_VERSION" ];then
        printf "Please install SAS before installing licenses\n"
        return
    fi

    if [ -n "$license" ]; then
        licenseDir=$VAS_LICENSE_PATH/vas/.licenses

        mkdir -p "$licenseDir" > /dev/null 2>&1
        cp "$license" "$licenseDir"
        if [ $? -eq 0 ]; then
            DebugScript $SCRIPT_NAME "succeeded"
            printf "Installed '$license' -> '$licenseDir/%s\n" "`basename $license`"
        else
            printf "Failed\n\n
WARNING: Copying the license file ($license) failed.
        This is not fatal, but not all SAS tools will function properly.
"
            DebugScript $SCRIPT_NAME "failed: warning 1"
        fi
    fi
    DebugScript $SCRIPT_NAME "---"
}

######################################################
# Prompt for license files and install them
######################################################
InteractiveCopyLicenseFile()
{
    __errcnt=0
    license_source=

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "InteractiveCopyLicenseFile()"
    DebugScript $SCRIPT_NAME "---"

    if [ -z "$VASCLNT_INSTALLED_VERSION" -a -z "$VASCLNTS_INSTALLED_VERSION" ];then
        printf "Please install SAS before installing licenses\n"
        return
    fi

    case $INSTALL_MODE in
        "unattended")
            if [ -n "$CMDLINE_LICENSE_FILE" ];then
                CopyKnownLicenseFile "$CMDLINE_LICENSE_FILE"
            else
                printf "Please specify a license file using -l option\n"
            fi
            return
            ;;
        "simple")
            if [ -n "$CMDLINE_LICENSE_FILE" ];then
                CopyKnownLicenseFile "$CMDLINE_LICENSE_FILE"
                return
            fi
            ;;
    esac

    printf "\n\nA valid license file is required\n"
    printf "Joining, depending on configuration, can automatically provide license file(s)\n"
    $VASTOOL license -q
    AskYesNo "\nWould you like to install license(s)" "no"
    if [ "x$askyesno" = "xno" ]; then
        return
    fi
    printf "\n\
Please specify the full local path for each license file, e.g. /tmp/licenses/license1.txt.

Standard wildcards are also valid, e.g. /tmp/licenses/*.txt.

When all licenses have been installed press <enter> to quit.\n"

    quit=$FALSE
    __errcnt=0

    while [ $quit -eq $FALSE ]; do
        printf "\nPlease specify full local path of license to install (<enter> to quit):\n"
        printf "> "; read __path

        if [ -n "$__path" ]; then
            for license in $__path;do
                CopyKnownLicenseFile "$license"
            done
        else
            quit=$TRUE
        fi
    done

    printf "\nResulting license state:\n"
    $VASTOOL license -q
    DebugScript $SCRIPT_NAME "---"
}

###################################################
#  Exit the script.
#
#   Input:
#       status      Status to exit with
#       whence      Message meant for specifying where script is exiting from
#
#   Output:
#       Script closes
#
###################################################
ExitInstall()
{
    status=$1
    whence=${2:-}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "ExitInstall(status=$status, whence=$whence)"
    DebugScript $SCRIPT_NAME "---"

    # Exit the install script from anywhere. Optionally, say whence this
    # function was called, but only print the note if in debug mode.
    if [ $DEBUG -eq $TRUE -a -n "$whence" ]; then
        printf "\n--script exited from $whence\n"
    else
        echo
    fi

    DebugScript $SCRIPT_NAME "---"
    exit $status
}

#####################################
#    UpdatePlatformInfo
#
#    These will update the OS and package path variables
#####################################
UpdatePlatformInfo()
{
    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "UpdatePlatformInfo()"
    DebugScript $SCRIPT_NAME "---"

    SetOSInfo
    SetVASPath
    
    DebugScript $SCRIPT_NAME "Returns:"
    DebugScript $SCRIPT_NAME "    HOST_OS_NAME=$HOST_OS_NAME"
    DebugScript $SCRIPT_NAME "  HOST_OS_DISTRO=$HOST_OS_DISTRO"
    DebugScript $SCRIPT_NAME " HOST_OS_VERSION=$HOST_OS_VERSION"
    DebugScript $SCRIPT_NAME "  HOST_OS_KERNEL=$HOST_OS_KERNEL"
    DebugScript $SCRIPT_NAME "   HOST_HARDWARE=$HOST_HARDWARE"
    DebugScript $SCRIPT_NAME "   HOST_PKG_PATH=$HOST_PKG_PATH"

    DebugScript $SCRIPT_NAME "---"

}


#####################################
#    GetIsoInformation
#
#    These will update the <product>_VERSION and <product>_PATH variables
#####################################
GetIsoInformation()
{
    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "GetIsoInformation()"
    DebugScript $SCRIPT_NAME "---"

    for productCode in $PRODUCT_CODES "VASPRE";do
        __updatePkgInfo $productCode
    done

    DebugScript $SCRIPT_NAME "---"

}

__is_old_rpm()
{
    # RedHat 5 has rpm v4.4 which only supports md5 file checksums, so we have separate packages for it.
    # rpm >=4.6 is the first version which supports it.
    rpm --version 2>/dev/null | grep -q "RPM version 4\.[0-5]\."
}

__updatePkgInfo()
{
    productCode=${1:="---"}
    version=
    pkgpath=

    # Derive the product values
    product=`eval echo \\$${productCode}_NAME`
    description=`eval echo \\$${productCode}_DESC`

    location=`eval echo \\$${productCode}_ISO_PATH`

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "  product=$product"
    DebugScript $SCRIPT_NAME "  description=$description"
    DebugScript $SCRIPT_NAME "  location=$location"

    case $product in
        "preflight")
            location="$ISO_PATH/$location/$HOST_PKG_PATH"
            pkgpath=`ls "$location/preflight" 2> /dev/null`
            version=
            ;;

        *)
            location="$ISO_PATH/$location/$HOST_PKG_PATH"

            # Find install package and version by OS
            case "$HOST_OS_NAME" in
                "SunOS")
                    case $product in
                        $DDNS_NAME)
                            pkgpath=`ls $location/${product}-*.pkg 2> /dev/null`
                            version=`basename "$pkgpath" | sed 's/.*-\([0-9]*\.\)/\1/;s/-.*//'`
                            ;;
                        *)
                            pkgpath=`ls $location/${product}_*.pkg 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e 's/.*-//;s/\.[^0-9]*pkg//'`
                            ;;
                    esac
                    ;;

                "AIX")
                    case $product in
                        $MOD_AUTH_VAS_20_NAME)
                            pkgpath=`ls "$location/${product}."*.bff 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e "s/.*${product}\.//;s/\.bff//"`
                            ;;
                        $DDNS_NAME)
                            pkgpath=`ls "$location/${product}."*.bff 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e "s/.*${product}\.//;s/\.bff//"`
                            ;;
                        *)
                            pkgpath=`ls "$location/${product}."*.bff 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e 's/.*_[0-9]*\.//;s/\.bff//'`
                            ;;
                    esac
                    ;;

                "HP-UX")
                    case $product in
                        $DDNS_NAME|$MOD_AUTH_VAS_20_NAME)
                            pkgpath=`ls "$location/${product}-"*.depot 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e 's/.*-//;s/\.depot//'`
                            ;;
                        *)
                            pkgpath=`ls "$location/${product}_"*.depot 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e 's/.*-//;s/\.depot//'`
                            ;;
                    esac
                    ;;

                "Darwin")
                    # Darwin only supports vasclnt(s), vasgp(s), vasdev, ddns, vassc, and vascert. The install packages are grouped into dmg files
                    case $product in
                        $VASCLNT_NAME|$VASGP_NAME)
                            pkgpath=`ls "$location/VAS-"*.dmg 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e 's/.*-//;s/\.dmg//'`
                            ;;

                        $VASCLNTS_NAME|$VASGPS_NAME)
                            pkgpath=`ls "$location/VASsite-"*.dmg 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e 's/.*-//;s/\.dmg//'`
                            ;;

                        $VASDEV_NAME|$VASSC_NAME|$DDNS_NAME)
                            pkgpath=`ls "$ISO_PATH/$VASCLNT_ISO_PATH/$HOST_PKG_PATH/VAS-"*.dmg 2> /dev/null`
                            if [ -z "$pkgpath" ];then
                                pkgpath=`ls $ISO_PATH/$VASCLNTS_ISO_PATH/$HOST_PKG_PATH/VASsite-*.dmg 2> /dev/null`
                            fi
                            version=`basename "$pkgpath" | sed -e 's/.*-//;s/\.dmg//'`
                            ;;

                        # I have to attach the dmg before I can figure out the version for vascert
                        $VASCERT_NAME)
                            pkgpath=`ls "$ISO_PATH/$VASCLNT_ISO_PATH/$HOST_PKG_PATH/VAS-"*.dmg 2> /dev/null`
                            if [ -z "$pkgpath" ];then
                                pkgpath=`ls $ISO_PATH/$VASCLNTS_ISO_PATH/$HOST_PKG_PATH/VASsite-*.dmg 2> /dev/null`
                            fi
                            # In order to get the correct version, open the dmg and grab it.
                            unmountAll

                            volume=`hdiutil attach "$pkgpath" 2> /dev/null | grep "/Volumes" | sed 's,.*/Volumes,/Volumes,;s/[^A-Za-z0-9]*$//'`
                            mpkg=`ls -d "$volume"/*.pkg 2> /dev/null`

                            version=`/usr/bin/xar -t -f $mpkg | grep vascert | sed -e 's/-/ /g;s/\.pkg/ /g' | awk '{ print $2 }' | head -1`

                            unmountAll
                            ;;
                    esac
                    ;;

                "Linux")

                    # Must distinguish between debian and rpm based linux
                    case "$HOST_OS_DISTRO" in
                        "Ubuntu"|"Debian")
                            pkgpath=`ls "$location/${product}_"*.deb 2> /dev/null`
                            version=`basename "$pkgpath" | sed -e "s/[._][^0-9].*//;s/.*_//;s/-/./"`
                            ;;
                        *)
                            if __is_old_rpm; then
                                DebugScript $SCRIPT_NAME "Warning: RPM version is old (< 4.6), falling back to rh5 packages"
                                location=$location/rh5
                            fi

                            pkgpath=`ls "$location/${product}-"*.rpm 2> /dev/null`
                            version=`basename "$pkgpath" | sed 's/\.[^0-9].*//;s/.*-\([0-9][0-9]*\.\)/\1/;s/-/./'`
                            ;;
                    esac
                    ;;
                "FreeBSD")
                    pkgpath=`ls "$location/${product}-"*.txz 2>/dev/null`
                    version=`basename "$pkgpath" | sed 's/\.[^0-9].*//;s/.*-\([0-9][0-9]*\.\)/\1/;s/-/./'`
                    ;;
            esac
            ;;
    esac
    
    version=`echo $version | grep "^[0-9]"` # remove invalid versions
    eval ${productCode}_VERSION=\"\$version\"
    eval ${productCode}_PATH=\"\$pkgpath\"
}

#################################################
#   Update installed Product Info
#
#   This updates them <product>_INSTALLED_VERSION variables
#
#################################################
data=
GetInstalledInformation()
{
    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "GetInstalledInformation()"
    DebugScript $SCRIPT_NAME "---"

    # VASUTIL needs to be added to this list in 
    # order to detect/remove old vasutil packages
    installedProductCodes="VASUTIL $PRODUCT_CODES"

    data="init"
    for productCode in $installedProductCodes; do
        __updateInstallVersion $productCode
    done

    DebugScript $SCRIPT_NAME "---"
}

__updateInstallVersion()
{
    productCode=${1:="---"}
    product=`eval echo \\$${productCode}_NAME`
    version=

    case $HOST_OS_NAME in
        "SunOS")
            VAS_VERSION=`getVasVersion`
            case $product in
                # Use 'vastool v' because sometimes the 'pkginfo -l' lies to me
                $VASCLNT_NAME)
                    isLicensedBuildSolaris
                    if [ $? -eq $SUCCESS ];then
                        version=$VAS_VERSION
                    fi
                    ;;
                $VASCLNTS_NAME)
                    isLicensedBuildSolaris
                    if [ $? -ne $SUCCESS ];then
                        version=$VAS_VERSION
                    fi
                    ;;
                *)
                    if [ "x$data" = "xinit" ];then
                        data=`pkginfo -l | awk '/PKGINST:  |VERSION:  /{ print $2 }' | sed -e 'N;s/\n/=/' | awk '/^vas|quest|QSFT|pamdef|dnsupdate/{ print }'`
                    fi
                    ;;
            esac
            ;;

        "AIX")
            if [ "x$data" = "xinit" ];then
                # Need to handle vas and pamdefender and modauthvas. And handle 3.5 (vasclnt.AIX_53 instead of vasclnt for $1).
                data=`lslpp -cL 2> /dev/null | awk -F: '/^ *vas|quest|mod|pamdef|dnsupdate/{sub(/\..*/,"",$1); print $1"="$3}'`
            fi
            ;;

        "HP-UX")
            if [ "x$data" = "xinit" ];then
                data=`swlist | awk '/vas|quest|mod|pamdef|dnsupdate/{print $1"="$2 }'`
            fi
            ;;

        "Darwin")
            VAS_VERSION=`getVasVersion`
            
            case $product in
                $VASCLNT_NAME)
                    isLicensedBuildMac
                    if [ $? -eq $SUCCESS ];then
                        version=$VAS_VERSION
                    fi
                    ;;
                $VASCLNTS_NAME)
                    isLicensedBuildMac
                    if [ $? -ne $SUCCESS ];then
                        version=$VAS_VERSION
                    fi
                    ;;
                $VASGP_NAME)
                    isLicensedBuildMac
                    if [ $? -eq $SUCCESS ];then
                        version=`getVgpVersion`
                    fi
                    ;;
                $VASGPS_NAME)
                    isLicensedBuildMac
                    if [ $? -ne $SUCCESS ];then
                        version=`getVgpVersion`
                    fi
                    ;;
                $VASSC_NAME)
                    if [ -x "$VASTOOL" -a -f "/etc/opt/quest/vas/vas-plugins.conf" ];then
                        version=$VAS_VERSION
                    fi
                    ;;
                $VASDEV_NAME)
                    if [ -x "$VASTOOL" -a -f "/opt/quest/include/vas.h" ];then
                        version=$VAS_VERSION
                    fi
                    ;;
                $VASCERT_NAME)
                    if [ -x "$VASTOOL" -a -f "/opt/quest/bin/vascert" ];then
                        version=`$VASCERT -h 2>/dev/null | awk '{ print $NF }' | head -1`
                    fi
                    ;;
                $DDNS_NAME)
                    version=`$DNSUPDATE -V 2> /dev/null  | awk '{ print $NF }'`
                    ;;
                # needed to detect/remove old vasutil packages
                $VASUTIL_NAME)
                    version=`$OAT -v 2> /dev/null  | awk '/Version/{ print $NF }'`
                    if [ -n "$version" ];then
                        major=`echo $version | sed 's/\..*//'`
                        if [ $major -ge 3 ];then
                            version=""
                        fi
                    fi
                    ;;
            esac
            ;;

        "OSF1")
            if [ "x$data" = "xinit" ];then
                data=`setld -i | awk '/^VAS|quest|pamdef|dnsupdate/{ print }' | sed -e '/not installed/d;s/[0-9].*-/=/;s/ .*//' | tr "$UPPER" "$LOWER"`
            fi
            ;;

        "IRIX64")
            if [ "x$data" = "xinit" ];then
                data=`versions -IMbn | awk '/vas|quest|pamdef|dnsupdate/{ print $2"="$NF }'`
            fi
            ;;

        "Linux")
            case $HOST_OS_DISTRO in
                "Debian"|"Ubuntu")
                    if [ "x$data" = "xinit" ];then
                        data=`dpkg -l | grep '^ii' | awk '/vas|quest|pamdef|dnsupdate/{ print $2"="$3 }' | sed 's/-\([^-]*\)$/.\1/'`
                    fi
                    ;;

                *)
                    if [ "x$data" = "xinit" ];then
                        data=`rpm -qa | sed 's/-\([^0-9]\)/_\1/' | awk -F"-" '/vas|quest|pamdef|dnsupdate/{ print $1"="$2"."$3}' | sed 's/quest_/quest-/;s/mod_auth_vas_/mod_auth_vas-/;s/\.i386//;s/\.x86_64//;s/\.noarch//;s/\.s390.*//;s/\.ppc64le//;s/\.ppc//;s/\.ia64//;s/\.aarch64//'`
                    fi
                    ;;
            esac
            ;;
        "FreeBSD")
            if [ "x$data" = "xinit" ];then
                data="`pkg info -x vas quest pamdef dnsupdate 2>/dev/null | awk -F "-" '/vas|quest|pamdef|dnsupdate/{ print $1"="$2 }'`"
            fi
            ;;
    esac
    if [ -z "$version" -a -n "$data" ];then
        # Using pre-filtered data. This way we only have to call the system
        #   install utility once. Install utilities are notoriously slow.
        for prodVersion in $data;do
            prod=`echo $prodVersion | awk -F"=" '{ print $1 }'`
            if [ "x$prod" = "x$product" ];then
                version=`echo $prodVersion | awk -F"=" '{ print $2 }'`
            fi
        done
    fi

    eval ${productCode}_INSTALLED_VERSION=$version

    DebugScript $SCRIPT_NAME "  $product installed version=$version"
}

isLicensedBuildMac()
{
    pkgutil --pkgs | grep vasclnts
    if [ $? -eq 0 ]; then
        return $FAILURE
    fi
    return $SUCCESS
}

isLicensedBuildSolaris()
{
    pkginfo -q vasclnts
    if [ $? -eq 0 ]; then
        return $FAILURE
    fi
    return $SUCCESS
}

getVasVersion()
{
    if [ -x "$VASTOOL" ];then
        $VASTOOL -v 2> /dev/null | awk '/Version/{ print $NF }'
    fi
}

getVgpVersion()
{
    if [ -x "$VGPTOOL" ];then
        $VGPTOOL -v 2> /dev/null | awk '/Version/{ print $NF }'
    fi
}

######################################################
#  Execute the specified install command
#
#   Input:
#       command     Script command to execute (see help file for valid commands)
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
######################################################
ExecuteCommand()
{
    command=${1:-}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "ExecuteCommand(command=$command)"
    DebugScript $SCRIPT_NAME "---"
    skipEULA=$FALSE

    # check for special commands
    case $command in

        "upgrade")
            echo
            for productCode in $PRODUCT_CODES;do
                       product=`eval echo \\$${productCode}_NAME`
                    isoVersion=`eval echo \\$${productCode}_VERSION`
                installVersion=`eval echo \\$${productCode}_INSTALLED_VERSION`
				# This line helps the upgrade command to detect the old quest-dnsupdate
				if [ $product = "quest-dnsupdate" ];then
					isoVersion=$DDNS_VERSION
				fi
                if [ -n "$isoVersion" ];then
                    if [ -n "$installVersion" ];then

                        printf "\t$product: "

                        # if available version is greater than install version
                        CompareVersions $isoVersion $installVersion
                        case $compare in
                            1)
								# This extra 'if' section is also needed to detect and upgrade the old quest-dnsupdate
								if [ $product = "quest-dnsupdate" ];then
									if (CanUpgrade "DDNS" $TRUE);then
										ExecuteCommand "dnsupdate"
										result=`expr $result '&' $?`
									fi
                                elif (CanUpgrade $productCode $TRUE);then
                                    ExecuteCommand "$product"
                                    result=`expr $result '&' $?`
                                fi
                                ;;
                            0)
                                printf "SKIPPING - Already installed ($installVersion).\n"
                                ;;
                           -1)
                               printf "SKIPPING - Found newer version ($installVersion).\n"
                               ;;
                        esac
                    else
                        printf "SKIPPING - $product not installed.\n"                        
                    fi
                else
                    printf "SKIPPING - $product not available.\n"
                    
                fi
            done

            if [ $result -eq $FAILURE ];then
                printf "Failed\n"
            else
                printf "Done\n"
            fi
            return $result
            ;;

        "remove")
            echo
            codes=`echo $PRODUCT_CODES | sed 's/VASCLNTS//;s/VASCLNT//;s/DDNS//'`

#   Check vasclnt(s) last since it's the only one that has remove dependencies
            for productCode in "DDNS" "VASUTIL" $codes "VASCLNT" "VASCLNTS";do
                       product=`eval echo \\$${productCode}_NAME`
                    isoVersion=`eval echo \\$${productCode}_VERSION`
                installVersion=`eval echo \\$${productCode}_INSTALLED_VERSION`

                if [ -n "$installVersion" ];then
                    printf "\t$product: "
                    if (CanRemove $productCode $TRUE);then
                        ExecuteCommand "no$product"
                    fi
                else
                    printf "SKIPPING - $product not installed.\n"                    
                fi
            done

            if [ $result -eq $FAILURE ];then
                printf "Failed\n"
            else
                printf "Done\n"
            fi
            return $result
            ;;

        "join")
            DoVasJoin
            result=$?
            if [ $result -eq $FAILURE ];then
                printf "Failed\n"
            else
                printf "Done\n"
            fi
            return $result
            ;;

        "preflight")
            DoPreflight
            return
            ;;

        "license")
            InteractiveCopyLicenseFile
            return
            ;;
    esac

# Process command
    action=`echo $command | grep "^no"`
    if [ -n "$action" ];then
        action="remove"
    else
        action="install"
    fi

    GetProductCode `echo $command | sed -e 's/^no//'`
    productCode=$GetProductCodeOut

    product=`eval echo \\$${productCode}_NAME`
    pkgPath=`eval echo \\$${productCode}_PATH`
    isoVersion=`eval echo \\$${productCode}_VERSION`
    installVersion=`eval echo \\$${productCode}_INSTALLED_VERSION`
    
    if [ -z "$pkgPath" ];then
        pkgPath="-"
    fi

    DebugScript $SCRIPT_NAME "             Name: $product"
    DebugScript $SCRIPT_NAME "             Path: $pkgPath"
    DebugScript $SCRIPT_NAME "      ISO Version: $isoVersion"
    DebugScript $SCRIPT_NAME "Installed Version: $installVersion"
    DebugScript $SCRIPT_NAME "     Install Mode: $INSTALL_MODE"

# Formatting tweaks
    logfile=
    outputArg=
    newline=
    case $INSTALL_MODE in
        "unattended")
            logfile="/tmp/$product.$action"
            outputArg=" > $logfile 2>&1"
            ;;
        "simple")
            newline="\n"
            ;;
    esac

    case $action in
        "remove")
            # Nothing to uninstall
            if [ -z "$installVersion" ];then
                printf "$product is not installed\n"

            # Normal uninstall
            else
                if (CanRemove $productCode $TRUE);then
                    eval \$INSTALL_PRODUCT_SH \$action \$product \$pkgPath \$installVersion $outputArg
                    if [ $? -ne $SUCCESS ];then
                        printf "Failed to remove $product ($installVersion)."
                        if [ -n "$logfile" ];then
                            printf " See $logfile for details."
                        fi
                        printf "\n"
                        result=$FAILURE
                    else
                        eval ${productCode}_INSTALLED_VERSION=
                        printf "$product ($installVersion) removed.\n$newline"
                        if [ -n "$logfile" ];then rm -f $logfile;fi
                    fi
                else
                    result=$FAILURE
                fi
            fi
            ;;

    "install")
		# Check for special dnsupdate upgrade from quest-dnsupdate case
		if [ $command = "dnsupdate" ];then
			if [ -n "$OLD_DDNS_INSTALLED_VERSION" ];then
			ExecuteCommand "noquest-dnsupdate"
			product=$DDNS_NAME
			isoVersion=$DDNS_VERSION
			installVersion=$DDNS_INSTALLED_VERSION
			productCode="DDNS"
			action="install"
			pkgPath=$DDNS_PATH
            skipEULA=$TRUE
			fi
		fi
        # Not Patched
        if [ $PATCHED -eq $FALSE ];then
            printf "\nSkipping install selection because required patch levels have not been met.\n"
            result=$FAILURE
        else
        
            # Nothing to install
            if [ -z "$isoVersion" ];then
                printf "$product is not available to install. Please verify ISO contents.\n"
                result=$FAILURE

            # Nothing already installed
            elif [ -z "$installVersion" ];then
                if (CanInstall $productCode $TRUE);then
                    if [ "$skipEULA" -eq $FALSE ];then
                        ConfirmEula
                    fi
                    eval \$INSTALL_PRODUCT_SH \$action \$product \$pkgPath \$isoVersion $outputArg
                    if [ $? -ne $SUCCESS ];then
                        result=$FAILURE
                        printf "ERROR: Failed to install $product ($isoVersion)."
                        if [ -n "$logfile" ];then
                            printf " See $logfile for details."
                        fi
                        printf "\n"
                    else
                        eval ${productCode}_INSTALLED_VERSION=$isoVersion
                        printf "$product ($isoVersion) installed.\n$newline"
                        if [ -n "$logfile" ];then rm -f $logfile;fi
                    fi
                else
                    result=$FAILURE
                fi

            else
                # Test whether we need to upgrade, remove, or do nothing
                CompareVersions $isoVersion $installVersion
                case $compare in
                    -1)
                        printf "ERROR: A newer version is already installed ($installVersion)."
                        ;;

                     1)
                        if (CanUpgrade $productCode $TRUE);then
                            eval \$INSTALL_PRODUCT_SH "upgrade" \$product \$pkgPath \$isoVersion $outputArg
                            if [ $? -ne $SUCCESS ];then
                                result=$FAILURE
                                printf "ERROR: Failed to upgrade $product ($installVersion) to $product ($isoVersion)."
                                if [ -n "$logfile" ];then
                                    printf " See $logfile for details."
                                fi
                                printf "\n"
                            else
                                eval ${productCode}_INSTALLED_VERSION=$isoVersion
                                printf "$product ($installVersion) upgraded to $product ($isoVersion)\n$newline"
                                if [ -n "$logfile" ];then rm -f $logfile;fi
                            fi
                        else
                            result=$FAILURE
                        fi
                        ;;

                    0)
                        printf "$product ($isoVersion) is already installed.\n"
                        ;;
                esac
            fi
        fi
        ;;
    esac

    DebugScript $SCRIPT_NAME "Returning: $result"
    DebugScript $SCRIPT_NAME "---"
    return $result
}

###############################################
# Compare two version strings
#
#   Input:
#       version1
#       version2
#
#   Output:
#  Result is stored in variable 'compare' as follows:
#   -1 : version1 < version2
#    0 : version1 = version2
#    1 : version1 > version2
#
###############################################
compare=
CompareVersions()
{
    version1=${1:-}
    version2=${2:-}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CompareVersions(version1=$version1,version2=$version2)"
    DebugScript $SCRIPT_NAME "---"

    for index in 1 2 3 4;do
        num1=`eval echo $version1 | awk -F"." "{ print \\$${index} }"`
        num2=`eval echo $version2 | awk -F"." "{ print \\$${index} }"`

        if [ ${num1:-0} -lt ${num2:-0} ] 2> /dev/null;then
            compare=-1
            break
        elif [ ${num1:-0} -gt ${num2:-0} ] 2> /dev/null;then
            compare=1
            break
        else
            compare=0
        fi
    done

    DebugScript $SCRIPT_NAME "Return: compare=$compare"
    DebugScript $SCRIPT_NAME "---"
}

###########################################################
#  Checks that nothing that depends on SAS is installed
#
#   Input:
#       productCode     productCode (see init.sh)
#       verbose         whether to print error messages
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
###########################################################
CanRemove()
{
    productCode=${1:-}
    verbose=${2:-$FALSE}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CanRemove(productCode=$productCode,verbose=$verbose)"
    DebugScript $SCRIPT_NAME "---"

    errors=
    case $productCode in
        "VASCLNT"|"VASCLNTS")
            for productCode in $PRODUCT_CODES;do
                case $productCode in
                    "VASCLNT"|"VASCLNTS"|"DEFENDER") : ;;
                    *)
                        installVersion=`eval echo \\$${productCode}_INSTALLED_VERSION`
                        if [ -n "$installVersion" ];then
                            product=`eval echo \\$${productCode}_NAME`
                            errors="$errors Please_uninstall_${product}_first"
                            result=$FAILURE
                        fi
                        ;;
                esac
            done
            ;;

        # nothing depends on other products
        *)  :
            ;;
    esac

    if [ $result -eq $FAILURE -a $verbose -eq $TRUE ];then
        printf "Failed.\n"
        for error in $errors;do
            printf "\t\t$error\n" | tr "_" " "
        done
    fi

    DebugScript $SCRIPT_NAME "Returning: $result"
    DebugScript $SCRIPT_NAME "---"
    return $result
}

###########################################################
#  Checks that required products are installed
#
#   Input:
#       productCode     productCode (see init.sh)
#       verbose         whether to print error messages
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
###########################################################
CanInstall()
{
    productCode=${1:-}
    verbose=${2:-$FALSE}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CanInstall(productCode=$productCode,verbose=$verbose)"
    DebugScript $SCRIPT_NAME "---"

    isoVersion=`eval echo \\$${productCode}_VERSION`
    installedVasVersion=${VASCLNT_INSTALLED_VERSION:-$VASCLNTS_INSTALLED_VERSION}

    errors=
    case $productCode in
        "VASCLNT")
            if [ -n "$VASCLNTS_INSTALLED_VERSION" ];then
                errors="$errors Please_remove_vasclnts_first"
                result=$FAILURE
            fi
            ;;
        "VASCLNTS")
            if [ -n "$VASCLNT_INSTALLED_VERSION" ];then
                errors="$errors Please_remove_vasclnt_first"
                result=$FAILURE
            fi
            ;;

        "VASGP")
            if [ -n "$VASGPS_INSTALLED_VERSION" ];then
                errors="$errors Please_remove_vasgps_first"
                result=$FAILURE
            fi
            if [ "x$installedVasVersion" != "x${VASGP_VERSION}" ];then
                errors="$errors Please_install_VAS_Client_${isoVersion}_first"
                result=$FAILURE
            fi
            ;;
        "VASGPS")
            if [ -n "$VASGP_INSTALLED_VERSION" ];then
                errors="$errors Please_remove_vasgp_first"
                result=$FAILURE
            fi
            if [ "x$installedVasVersion" != "x${VASGPS_VERSION}" ];then
                errors="$errors Please_install_VAS_Client_${isoVersion}_first"
                result=$FAILURE
            fi
            ;;
        "MOD_AUTH_VAS_20")
            if [ -n "$MOD_AUTH_VAS_22_INSTALLED_VERSION" ];then
                errors="$errors Please_remove_mod-auth-vas-22_first"
                result=$FAILURE
            fi
            if [ -z "$installedVasVersion" ];then
                errors="$errors Please_install_VAS_Client_${isoVersion}_first"
                result=$FAILURE
            fi
            ;;
        "MOD_AUTH_VAS_22")
            if [ -n "$MOD_AUTH_VAS_20_INSTALLED_VERSION" ];then
                errors="$errors Please_remove_mod-auth-vas-20_first"
                result=$FAILURE
            fi
            if [ -z "$installedVasVersion" ];then
                errors="$errors Please_install_VAS_Client_${isoVersion}_first"
                result=$FAILURE
            fi
            ;;
        "DEFENDER")
            ;;
        "DDNS"|"VASCERT")
            if [ -z "$installedVasVersion" ];then
                errors="$errors Please_install_VAS_Client_${isoVersion}_first"
                result=$FAILURE
            fi
            ;;
        *)
            if [ "x$installedVasVersion" != "x$isoVersion" ];then
                errors="$errors Please_install_VAS_Client_${isoVersion}_first"
                result=$FAILURE
            fi
    esac

    if [ $result -eq $FAILURE -a $verbose -eq $TRUE ];then
        printf "SKIPPING\n"
        for error in $errors;do
            printf "\t\t$error\n" | tr "_" " "
        done
    fi

    DebugScript $SCRIPT_NAME "Returning: $result"
    DebugScript $SCRIPT_NAME "---"
    return $result
}

#This whole function is here just because we used to fail upgrade if 
# a QAC hadn't been created yet.  Now it should simply always return true
# but maybe there will be a time when we want to restrict upgrades in the 
# future.
CanUpgrade()
{
    productCode=${1:-}
    verbose=${2:-$FALSE}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CanUpgrade(productCode=$productCode,verbose=$verbose)"
    DebugScript $SCRIPT_NAME "---"

    errors=
    schemaError=$FALSE
    CanInstall "$@"
    result=$?
    errors=""
    
    case $productCode in
        "VASCLNT"|"VASCLNTS")
            result=$SUCCESS
            ;;

        # nothing depends on other products
        *)  :
            ;;
    esac

    DebugScript $SCRIPT_NAME "Returning: $result"
    DebugScript $SCRIPT_NAME "---"
    return $result   
}

#####################################################################
# Prints and evaluates command
#
#   Input:
#       cmd     cmd to evaluate
#
#   Output:
#       result=<cmd exit code>
#
#####################################################################
EvalCmd()
{
    cmd=${1:-}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "EvalCmd(cmd=$cmd)"
    DebugScript $SCRIPT_NAME "---"

    printf "\n$cmd\n"
    eval $cmd
    result=$?

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
}

#####################################################################
#
# Unmount all VAS volumes on mac
#
#####################################################################
unmountAll()
{
    PREFIX=${1:-VAS}
    
    volume=`ls -ld /Volumes/${PREFIX}* 2> /dev/null | sed 's,.*\(/Volumes\),\1,;' | head -n1`
    while [ -n "$volume" ];do
        hdiutil detach -Force "$volume" > /dev/null 2>&1
        volume=`ls -ld /Volumes/${PREFIX}* 2> /dev/null | sed 's,.*\(/Volumes\),\1,;' | head -n1`
    done
}

#####################################################################
# platform specific install function
#
#   Input:
#       product     Name of product to install
#       pkgPath     Path to install package
#       pkgVersion  Version of product to install
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
#####################################################################
xml_changes_file="/var/tmp/new_choices.xml"
CreateChoiceChangesXML()
{
    product=${1:-}
    darwin_common_products="$DDNS_NAME $VASCERT_NAME $VASSC_NAME $VASDEV_NAME"
    darwin_licensed_products="$VASCLNT_NAME $VASGP_NAME $darwin_common_products"
    darwin_site_products="$VASCLNTS_NAME $VASGPS_NAME $darwin_common_products"
    darwin_choices=""
    choice_changes_file="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<array>"

    isLicensedBuildMac
    if [ $? -eq $SUCCESS ]; then
        darwin_choices="$darwin_licensed_products"
    else
        darwin_choices="$darwin_site_products"
    fi

    for choice in $darwin_choices; do
        select_choice=0
        if [ "$choice" = "$product" ]; then
            select_choice=1
        fi
        choice_changes_file="$choice_changes_file
    <dict>
        <key>attributeSetting</key>
        <true/>
        <key>choiceAttribute</key>
        <string>visible</string>
        <key>choiceIdentifier</key>
        <string>choice_$choice</string>
    </dict>
    <dict>
        <key>attributeSetting</key>
        <true/>
        <key>choiceAttribute</key>
        <string>enabled</string>
        <key>choiceIdentifier</key>
        <string>choice_$choice</string>
    </dict>
    <dict>
        <key>attributeSetting</key>
        <integer>$select_choice</integer>
        <key>choiceAttribute</key>
        <string>selected</string>
        <key>choiceIdentifier</key>
        <string>choice_$choice</string>
    </dict>"
    done
    choice_changes_file="$choice_changes_file
</array>
</plist>"

    printf "$choice_changes_file" >$xml_changes_file
}

install()
{
    installProduct=${1:-}
    installPkgPath=${2:-}
    installPkgVersion=${3:-}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "install(installProduct=$installProduct,installPkgPath=$installPkgPath,installPkgVersion=$installPkgVersion)"
    DebugScript $SCRIPT_NAME "---"

    case $HOST_OS_NAME in
        "SunOS")
            adminFile=/tmp/vas-admin

            printf \
"mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
basedir=default" > $adminFile

            case $HOST_OS_VERSION in
                6|7|8|9) cmd="echo 'y' | pkgadd -a '$adminFile' -d '$installPkgPath' all"     ;;
                      *) cmd="echo 'y' | pkgadd -a '$adminFile' -G -d '$installPkgPath' all"  ;;
            esac

            EvalCmd "$cmd"

            rm -f $adminFile
            ;;

        "AIX")
            EvalCmd "installp -acXd '$installPkgPath' all"
            ;;

        "HP-UX")
            EvalCmd "swinstall -s '$installPkgPath' \\*"
            ;;

        "Darwin")
            unmountAll
                
            volume=`hdiutil attach "$installPkgPath" | grep "/Volumes" | sed 's,.*/Volumes,/Volumes,;s/[^A-Za-z0-9]*$//' 2> /dev/null`
            mpkg=`ls -d "$volume"/*.pkg 2> /dev/null`

            CreateChoiceChangesXML $installProduct
            EvalCmd "/usr/sbin/installer -applyChoiceChangesXML $xml_changes_file -pkg '$mpkg' -target /"

            rm -f $xml_changes_file

            unmountAll
            ;;

        "Linux")
            case $HOST_OS_DISTRO in
                "Debian"|"Ubuntu")
                    cmd="dpkg -i --force-depends '$installPkgPath'"
                    ;;
                *)
                    cmd="rpm -ivh '$installPkgPath' --nodeps"
                    ;;
            esac
            EvalCmd "$cmd"
            ;;
        "FreeBSD")
            EvalCmd "pkg add '$installPkgPath'"
            ;;
    esac

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
    return $result
}

#####################################################################
# platform specific upgrade function
#
#   Input:
#       product     Name of product to upgrade
#       pkgPath     Path to upgrade package
#       pkgVersion  Version of product to upgrade to
#
#   Output:
#       result=$SUCCESS or $FAILURE
#####################################################################
upgrade()
{
    upgradeProduct=${1:-}
    upgradePkgPath=${2:-}
    upgradePkgVersion=${3:-}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "upgrade(upgradeProduct=$upgradeProduct,upgradePkgPath=$upgradePkgPath,upgradePkgVersion=$upgradePkgVersion)"
    DebugScript $SCRIPT_NAME "---"

    case $HOST_OS_NAME in
        "SunOS")
            adminFile=/tmp/vas-admin

            printf \
"mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
basedir=default" > $adminFile

            case $HOST_OS_VERSION in
                6|7|8|9) cmd="echo 'y' | pkgadd -a '$adminFile' -d '$upgradePkgPath' all"     ;;
                      *) cmd="echo 'y' | pkgadd -a '$adminFile' -G -d '$upgradePkgPath' all"  ;;
            esac

            EvalCmd "$cmd"

            rm -f $adminFile
            ;;

        "AIX")
            EvalCmd "installp -acXd '$upgradePkgPath' all"
            ;;

        "HP-UX")
            EvalCmd "swinstall -s '$upgradePkgPath' \\*"
            ;;

        "Darwin")
            unmountAll
            
            volume=`hdiutil attach "$upgradePkgPath" | grep "/Volumes" | sed 's,.*/Volumes,/Volumes,;s/[^A-Za-z0-9]*$//' 2> /dev/null`
            mpkg=`ls -d "$volume"/*.pkg 2> /dev/null`

            CreateChoiceChangesXML $upgradeProduct
            EvalCmd "/usr/sbin/installer -applyChoiceChangesXML $xml_changes_file -pkg '$mpkg' -target /"

            rm -f $xml_changes_file

            unmountAll
            ;;

        "OSF1")
            tmpDir="/tmp/vas-tru64-install"
            kitName=`echo ${upgradeProduct}${upgradePkgVersion} | tr "$LOWER" "$UPPER" | sed -e 's/\.[0-9]*$//;s/\.//g'`

            (\
                rm -rf "$tmpDir";
                mkdir -p "$tmpDir";
                cd "$tmpDir";
                gunzip -c "$upgradePkgPath" | tar -xvf - \
            ) > /dev/null

            EvalCmd "(cd "$tmpDir"; setld -l . "$kitName")"

            (rm -rf "$tmpDir") > /dev/null
            ;;

        "IRIX64")
            EvalCmd "inst -A -f '$upgradePkgPath' -u upgrade"
            ;;

        "Linux")
            case $HOST_OS_DISTRO in
                "Debian"|"Ubuntu")
                    cmd="dpkg -i '$upgradePkgPath'"
                    ;;
                *)
                    cmd="rpm -Uvh '$upgradePkgPath' --nodeps"
                    ;;
            esac
            EvalCmd "$cmd"
            ;;
        "FreeBSD")
            EvalCmd "pkg upgrade -y '$upgradePkgPath'"
            ;;
    esac

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
    return $result
}

#####################################################################
# platform specific remove function
#
#   Input:
#       product     Name of product to remove
#       pkgPath     Path to install package
#       pkgVersion  Version of product to remove
#
#   Output:
#       result=$SUCCESS or $FAILURE
#####################################################################
remove()
{
    removeProduct=${1:-}
    removePkgPath=${2:-}
    removePkgVersion=${3:-}
    result=$SUCCESS

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "remove(removeProduct=$removeProduct,removePkgPath=$removePkgPath,removePkgVersion=$removePkgVersion)"
    DebugScript $SCRIPT_NAME "---"

    case $HOST_OS_NAME in
        "SunOS")
            adminFile=/tmp/vas-admin

            printf \
"mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
basedir=default" > $adminFile

            EvalCmd "pkgrm -a '$adminFile' -n '$removeProduct'"

            /bin/rm -f $adminFile
            ;;

        "AIX")
            EvalCmd "installp -C '$removeProduct'"
            EvalCmd "installp -u '$removeProduct'"
            ;;

        "HP-UX")
            EvalCmd "swremove '$removeProduct'"
            ;;

        "Darwin")
            macuninstaller_path="/opt/quest/libexec/vas/macos/Uninstall.app/Contents/MacOS/Uninstall"
            if [ -f $macuninstaller_path ]; then
                unmountAll
                EvalCmd "'$macuninstaller_path' --console --force $removeProduct"
            else
                if [ -n "$removePkgPath" ];then
                    unmountAll
                    
                    volume=`hdiutil attach "$removePkgPath" | grep "/Volumes" | sed 's,.*/Volumes,/Volumes,;s/[^A-Za-z0-9]*$//' 2> /dev/null`

                    EvalCmd "'$volume/Uninstall.app/Contents/MacOS/Uninstall' --console --force $removeProduct"

                    unmountAll
                else
                    printf "Failed to uninstall. Uninstaller on .dmg file is unavailable."
                fi
            fi
            ;;

        "OSF1")
            kitName=`echo ${removeProduct}${removePkgVersion} | tr "$LOWER" "$UPPER" | sed -e 's/\.[0-9]*$//;s/\.//g'`

            EvalCmd "setld -d '$kitName'"
            ;;

        "IRIX64")
            EvalCmd "/opt/quest/sbin/uninstall-$removeProduct"
            ;;

        "Linux")
            case $HOST_OS_DISTRO in
                "Debian"|"Ubuntu") cmd="dpkg --purge '$removeProduct'" ;;
                                *) cmd="rpm -e '$removeProduct'"      ;;
            esac
            EvalCmd "$cmd"
            ;;
        "FreeBSD")
            EvalCmd "pkg remove -y '$removeProduct'"
            ;;
    esac

    DebugScript $SCRIPT_NAME "Return: $removeResult"
    DebugScript $SCRIPT_NAME "---"
    return $result
}
