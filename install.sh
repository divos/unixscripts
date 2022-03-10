#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# install.sh    Install script for One Identity Safeguard Authentication Services
#
# Version: 5.0.5.57504
#==============================================================================
SCRIPT_NAME="install.sh"

# Initialization script
set -a
PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin:$PATH
CWD=`pwd`
WORKING_DIRECTORY=`dirname "$0" | sed -e "s,^\.,$CWD,"`
INIT_SH="$WORKING_DIRECTORY/client/install-sh-data/init.sh"
set +a

#######################################################
# This is just a quick check to verify that install.sh
#    dependencies all exist and are usable
########################################################
CheckForScripts()
{
    # Initialize variables
    if [ -x "$INIT_SH" ];then
        . "$INIT_SH"
    else
        printf "ERROR: Script ($INIT_SH) is missing or not executable\n"
    fi

    result=$TRUE
    for script in $SCRIPTS;do
        if [ ! -x "$script" ];then
            printf "ERROR: Script ($script) is missing or not executable\n"
            result=$FALSE
        fi
    done
    for text in $TEXTS;do
        if [ ! -r "$text" ];then
            printf "ERROR: File ($text) is missing or not readable\n"
            result=$FALSE
        fi
    done

    if [ $result = $FALSE ];then
        printf "\nPlease verify that required files are present and try again.\n"
        exit 1
    fi
}

#############################################################
# Check whether executing user is root. root is required
#  for installation tasks on systems.
#############################################################
RequireRoot()
{
    # Check for root: can't do this stuff without it!
    id=${EUID:-`id | sed -e 's/(.*//;s/.*=//'`}

    if [ $id -ne 0 ]; then
        printf "\nERROR: You must have root access to use this script!"
        DebugScript $SCRIPT_NAME "You are NOT executing as root."
        ExitInstall $FAILURE "main, line ${LINENO:-?}"
    else
        DebugScript $SCRIPT_NAME "You are executing as root."
    fi
}

#############################################################
# Make sure that vasclnt is run first and novasclnt is run last
# due to install dependicies
#############################################################
ReorderCommands()
{
    COMMAND_LIST="$@"
    NEWLIST=""

    VASCLNTS=""
    VASCLNT=""
    NOVASCLNTS=""
    NOVASCLNT=""

    echo "$COMMAND_LIST" | grep 'novasclnts' > /dev/null 2>&1
    if [ $? -eq 0 ];then
            NOVASCLNTS="novasclnts"
            COMMAND_LIST=`echo $COMMAND_LIST | sed 's/novasclnts//g'`
    fi

    echo "$COMMAND_LIST" | grep 'novasclnt' > /dev/null 2>&1
    if [ $? -eq 0 ];then
            NOVASCLNT="novasclnt"
            COMMAND_LIST=`echo $COMMAND_LIST | sed 's/novasclnt//g'`
    fi

    echo "$COMMAND_LIST" | grep 'vasclnts' > /dev/null 2>&1
    if [ $? -eq 0 ];then
            VASCLNTS="vasclnts"
            COMMAND_LIST=`echo $COMMAND_LIST | sed 's/vasclnts//g'`
    fi

    echo "$COMMAND_LIST" | grep 'vasclnt' > /dev/null 2>&1
    if [ $? -eq 0 ];then
            VASCLNT="vasclnt"
            COMMAND_LIST=`echo $COMMAND_LIST | sed 's/vasclnt//g'`
    fi

    NEWLIST="$VASCLNTS $VASCLNT $COMMAND_LIST $NOVASCLNT $NOVASCLNTS"

    echo $NEWLIST
}


#############################################################
# Read command line arguments and update variables
#############################################################
ParseCommandLine()
{
    SHOW_HELP=
    ERROR=$FALSE

    set +u  # disable -u

    # This allows the long arg names on platforms (e.g. hpux) with old getopt
    argv=
    for arg in $@;do
        if [ "$arg" = "--version" ]; then
            SHOW_HELP="version"
        elif [ "$arg" = "--help" ]; then
            SHOW_HELP="full-help"
        else
            argv="$argv $arg"
        fi
    done
    set -- $argv

    argv=`getopt adhil:p:qtv ${*-} 2> /dev/null`
    if [ $? -ne $SUCCESS ];then
        DoHelp "arg-help"
        printf "\nERROR: Invalid option(s)"; ExitInstall $FAILURE "main, line ${LINENO:-?}"
    fi

    set -- $argv
    while [ $1 != -- ]; do
        case $1 in
            -a) EULA_READ=$TRUE                                                                                          ;;
            -d) DEBUG=$TRUE; InitializeDebug                                                                             ;;
            -h) SHOW_HELP="arg-help"                                                                                     ;;
            -i) INSTALL_MODE="interactive"                                                                               ;;
            -l) CMDLINE_LICENSE_FILE=$2;
                    # Quick check to see if it actually exists. Otherwise it might be an option error
                    if [ ! -f "$CMDLINE_LICENSE_FILE" ];then
                        SHOW_HELP="arg-help";
                        printf "\nERROR: Invalid license file ($CMDLINE_LICENSE_FILE)\n"
                        ERROR=$TRUE
                    fi                                                                                             ;shift;;
            -q) INSTALL_MODE="unattended";                                                                               ;;
            -t) INSTALL_MODE="test";                                                                                     ;;
            -v) SHOW_HELP="version"                                                                                      ;;
            -p) ISO_PATH=$2                                                                                        ;shift;;
             *) SHOW_HELP="arg-help"; printf "\nERROR: Invalid option ($1)\n"; ERROR=$TRUE                               ;;
        esac
        shift
    done
    shift
    set -u  # And turn it back on -- it fixes HPUX's strict -u interpretations

    foundLicense=$FALSE
    argv=
    args="${*:-}"
    for command in $args;do
        command=`echo $command | tr "$UPPER" "$LOWER"`
        # special command
        case $command in
            "upgrade"|"remove")
                argv="$argv $command"
                continue
                ;;
            "join"|"preflight"|"license")
                case $INSTALL_MODE in
                    "simple")
                        argv="$argv $command"
                        ;;
                    *)
                        printf "\nERROR: '$command' is only available in simple mode (no -i or -q)"
                        SHOW_HELP="arg-help"
                        ERROR=$TRUE
                        ;;
                esac
                if [ "x$command" = "xlicense" ];then
                    foundLicense=$TRUE
                fi
                continue
                ;;
        esac

        # Install/Remove command
        GetProductCode `echo $command | sed -e 's/^no//'`
        if [ -z "$GetProductCodeOut" ];then
            SHOW_HELP="arg-help"
            printf "\nERROR: Invalid command ($command)\n"
            ERROR=$TRUE
        else
            argv="$argv $command"
        fi
    done

    # Convert -l option into a license command if not already specified
    if [ -n "$CMDLINE_LICENSE_FILE" -a $foundLicense -eq $FALSE ];then
        case $INSTALL_MODE in
            "simple")
                if [ -n "$argv" ];then
                    argv="$argv license"
                fi
                ;;
            "unattended")
                argv="$argv license"
                ;;
        esac
    fi
    
    argv=`ReorderCommands "$argv"`

    if [ -n "$SHOW_HELP" ];then
        DoHelp $SHOW_HELP
        if [ $ERROR -eq $TRUE ];then
            ExitInstall $FAILURE "main, line ${LINENO:-?}"
        else
            ExitInstall $SUCCESS "main, line ${LINENO:-?}"
        fi
    fi
}

#==============================================================================
#                                                                             #
#                             Main script body                                #
#                                                                             #
#==============================================================================
printf "
One Identity Safeguard Authentication Services Installation Script
Script Build Version: 5.0.5.57504
Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
Protected by U.S. Patent Nos. 7,617,501, 7,895,332, 7,904,949, 8,086,710, 8,087,075, 8,245,242. Patents pending.
"

#------------------------------------------------------------------------------
# i n i t
#------------------------------------------------------------------------------
# Verify that all support scripts and files are present
CheckForScripts

. $COMMON_LIBRARY_SH

#------------------------------------------------------------------------------
# p l a t f o r m
#------------------------------------------------------------------------------
UpdatePlatformInfo
SetVASPath
    printf "\n%17s: %s\n" "Host Name" "$HOST_NAME"
    if [ "x$HOST_OS_NAME" = "xLinux" ];then
        printf "%17s: %s\n" "Operating System" "$HOST_OS_DISTRO $HOST_OS_NAME $HOST_OS_VERSION ($HOST_HARDWARE)"
    else
        printf "%17s: %s\n"  "Operating System" "$HOST_OS_NAME $HOST_OS_VERSION ($HOST_HARDWARE)"
    fi
    
	if [ -z "$HOST_PKG_PATH" ];then
		printf "You are not running on a supported platform. Sorry.\n"
		ExitInstall $FAILURE "main, line ${LINENO:-?}"
	fi

# need platform info to correctly parse command line
ParseCommandLine "${@:-}"

RequireRoot

#------------------------------------------------------------------------------
# c h e c k - p a t c h e s . s h
#------------------------------------------------------------------------------
DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Checking for recommended patches..."
DebugScript $SCRIPT_NAME "---"
printf "\nChecking for recommended patches..."
if ($CHECK_PATCHES_SH);then
    printf "Done\n"
    DebugScript $SCRIPT_NAME "check-patches returned success"
    PATCHED=$TRUE
else
    PATCHED=$FALSE
fi

#------------------------------------------------------------------------------
# c h e c k - i s o
#------------------------------------------------------------------------------
DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Checking version and name of product distribution media..."
printf "Checking for available software... "
GetIsoInformation
printf "Done\n"

#------------------------------------------------------------------------------
# c h e c k - i n s t a l l e d
#------------------------------------------------------------------------------
DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Checking for installed software..."
printf "Checking for installed software... "
GetInstalledInformation
printf "Done\n"

#------------------------------------------------------------------------------
# I N S T A L L   M O D E S
#
#     unattended, simple, and interactive
#------------------------------------------------------------------------------
DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Running in '$INSTALL_MODE' mode"
DebugScript $SCRIPT_NAME "---"
case "$INSTALL_MODE" in
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    "unattended")
        if [ -z "$argv" ]; then
            printf "\nERROR: Arguments are expected (see 'install.sh -h')\n"
            ExitInstall $SUCCESS "main, line ${LINENO:-?}"
        fi

        echo
        cmdResult=$TRUE
        for command in $argv;do
            printf "%-40s" "Executing command: '$command'..."
            ExecuteCommand $command
            if [ $? -ne $SUCCESS ]; then
                printf "ERROR: Failed to execute command: '$command'\n\n"
                cmdResult=$FALSE
            fi
        done

        if [ $cmdResult -eq $FALSE ];then
            ExitInstall $FAILURE "Not all commands succeeded. Run script in simple mode (i.e. without -q) for more information."
        else
            printf "\nExecution Successful\n\n"
        fi
        ;;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    "simple")
        if [ -z "$argv" ]; then
            # Default simple (upgrade) mode
            if [ -n "$VASCLNT_INSTALLED_VERSION" -o -n "$VASCLNTS_INSTALLED_VERSION" ];then
                argv="$argv upgrade"
            
            # Default simple mode
            elif [ -n "$VASCLNT_VERSION" ];then
                argv="$argv $VASCLNT_NAME"

                if [ -n "$VASGP_VERSION" ];then
                    argv="$argv $VASGP_NAME"
                fi
                argv="$argv license join"

            elif [ -n "$VASCLNTS_VERSION" ];then
                argv="$argv $VASCLNTS_NAME"

                if [ -n "$VASGPS_VERSION" ];then
                    argv="$argv $VASGPS_NAME"
                fi
                argv="$argv join"
            fi

            printf "\nExecuting the following commands:\n"
            for command in $argv;do
                case $command in
                    $VASCLNT_NAME|$VASCLNTS_NAME)
                        printf "   Install SAS Client ($command)\n"
                        ;;
                    $VASGP_NAME|$VASGPS_NAME)
                        printf "   Install SAS Group Policy Client ($command)\n"
                        ;;
                    "upgrade")
                        printf "   Upgrade all SAS products ($command)\n"
                        ;;
                    "license")
                        printf "   License SAS ($command)\n"
                        ;;
                    "join")
                        printf "   Join the Active Directory Domain ($command)\n"
                        ;;
                esac
            done
            AskYesNo "Do you wish to continue? " "yes"
            if [ "x$askyesno" = "xno" ];then
                printf "\nCancelling execution\n"
                ExitInstall $SUCCESS "main"
            fi
        else
            printf "\n"
        fi

        cmdResult=$TRUE
        for command in $argv;do
            printf "%-40s" "Executing command: '$command'..."
            ExecuteCommand $command
            if [ $? -ne $SUCCESS ]; then
                printf "ERROR: Failed to execute command: '$command'\n\n"
                cmdResult=$FALSE
            fi
        done

        if [ $cmdResult -eq $TRUE ];then
            printf "\nExecution Successful\n\n"
        else
            ExitInstall $FAILURE "Not all commands succeeded"
        fi
        ;;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    "interactive")
        if [ -n "$argv" ]; then
            echo "WARNING: Arguments are not expected in interactive mode and will be ignored (see 'install.sh -h')"
            DebugScript $SCRIPT_NAME "Arguments not expected: $argv"
        fi

        $INTERACTIVE_INSTALL_SH
        ;;

    "test")
        for productCode in $PRODUCT_CODES;do
            pkgName=`eval echo \\$${productCode}_NAME`
            pkgDesc=`eval echo \\$${productCode}_DESC`
            pkgPath=`eval echo \\$${productCode}_PATH`
         isoVersion=`eval echo \\$${productCode}_VERSION`
     installVersion=`eval echo \\$${productCode}_INSTALLED_VERSION`

            printf "

              Product: $pkgName
          Description: $pkgDesc
          ISO package: ${pkgPath:-<none>}
          ISO Version: ${isoVersion:-<none>}
    Installed Version: ${installVersion:-<none>}
"
        done
esac

exit 0
