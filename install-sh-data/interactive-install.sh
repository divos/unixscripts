#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# interactive-install.sh
#
#     Do interactive (menu-driven) install for products on the
#     current ISO/DVD/mounted filesystem, etc.
#
# Version: 5.0.5.57504
#==============================================================================
SCRIPT_NAME="interactive-install.sh"

if [ -z "${MAIN:-}" ];then
    echo "ERROR: Not main executable. Please run install.sh located at ISO root."
    exit 1
fi

#####################################################
# Display menu help
#
# Uses '$help_op_list' to determine what item to show help for
#
#####################################################
DisplayHelp()
{
    help_op_list=`echo ${help_op_list} | tr "${LOWER} " "${UPPER}\n" | sort -u`

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "DisplayHelp(help_op_list=$help_op_list)"
    DebugScript $SCRIPT_NAME "---"

    # Analyze the product and installation suggestions in MENU_ARRAY and
    # formulate lightly context-sensitive help blurbs for each. Thus, no help
    # will be given for issues that aren't relevant.
    for item in $help_op_list; do
        DebugScript $SCRIPT_NAME "$item"
        case "$item" in
            "P")
                printf "\n\
Preflight:
    This runs the preflight program which will run a series of tests on the client
    machine. These tests are meant to determine whether the machine is in a proper
    configuration to join Active Directory.\n"
                ;;
                
            "INSTALL")
                printf "\n\
Install <package>:
        The package on the installation medium will be installed on this host.\n"
                ;;


            "UPGRADE")
                printf "\n\
Upgrade <package>:
    Installation will be upgraded to the version of the installation medium.\n"
                ;;

            "REMOVE")
                printf "\n\
Remove <package>:
    The indicated component will be removed from this host and any settings associated
    with that package will be lost.\n"
                ;;

            "L")
                printf "\n\
Copy product license(s):
    This option conducts you through installing product licenses you have received from One Identity.
    It will copy local license files to the product license directory: $VAS_LICENSE_PATH/vas/.licenses.\n"
                ;;

            "J")
                printf "\n\
Join host to Active Directory:
    It is possible to join the host to Active Directory by means of the vasjoin.sh 
    script at this time. The vasjoin.sh script will prompt for such things as
    the name of the domain to which you wish to be joined, the name of a user with
    privileges to perform the join, user's password, as well as all other
    configurable options you may specify.\n"
                ;;
            "S")
                printf "\n\
Join host to Active Directory (simple):
    This option uses vasjoin.sh script to join the host to Active Directory in
    simple mode. It is similar to "Join host to Active Directory" above, in that it
    prompts for the name of the domain to which you wish to be joined to, the name
    of the user with privileges to perform the join, and user's password, but uses
    the default selections on all of the other configurable join options, and
    doesn't prompt the user for them.\n"
                ;;
        esac
    done

    DebugScript $SCRIPT_NAME "---"
}

####################################################
# Add a new item to the menu and update appropriate variables
####################################################
AddToMenu()
{
    operation=${1:-}
    pkgDesc=${2:-}
    pkgName=${3:-}
    pkgVersion=${4:-}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "AddToMenu(op=$operation, pkgDesc=$pkgDesc, pkgName=$pkgName, version=$pkgVersion)"
    DebugScript $SCRIPT_NAME "---"

    case $operation in
        "Install"|"Remove"|"Upgrade")
            printf "  %2s)  %s %s\n" "${item_number:=1}" "$operation" "$pkgDesc ($pkgName-$pkgVersion)"
            item_number=`expr ${item_number} + 1`

    case $operation in
        "Install")
            MENU_ARRAY="${MENU_ARRAY=} $pkgName"
            ;;
            
        "Upgrade")
            MENU_ARRAY="${MENU_ARRAY=} $pkgName"
            upgradeAll=$TRUE
            ;;

        "Remove")
            MENU_ARRAY="${MENU_ARRAY=} no$pkgName"
            removeAll=$TRUE
            ;;
    esac
    ;;
*)  printf "  %2s)  %s\n" "$operation" "$pkgDesc"       ;;
esac

    # Update Help List
    help_op_list="${help_op_list=} $operation"
    DebugScript $SCRIPT_NAME "---"
}

###################################################
# Create and display menu
###################################################
DisplayMenu()
{
    # Reset these variables each time
    MENU_ARRAY=
    help_op_list=
    item_number=1

    # Flags
    removeAll=$FALSE
    upgradeAll=$FALSE

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "DisplayMenu()"
    DebugScript $SCRIPT_NAME "---"

    printf "\n\
   -----------------------------------------------------------------
   S a f e g u a r d   A u t h e n t i c a t i o n   S e r v i c e s
   -----------------------------------------------------------------\n"

    for productCode in $PRODUCT_CODES;do
            pkgName=`eval echo \\$${productCode}_NAME`
            pkgDesc=`eval echo \\$${productCode}_DESC`
            pkgPath=`eval echo \\$${productCode}_PATH`
         isoVersion=`eval echo \\$${productCode}_VERSION`
     installVersion=`eval echo \\$${productCode}_INSTALLED_VERSION`

        if [ -n "$isoVersion" ];then
            if [ -n "$installVersion" ];then
                CompareVersions $isoVersion $installVersion
                case $compare in
                    -1|0)
                        if (CanRemove $productCode);then
                            AddToMenu "Remove" "$pkgDesc" "$pkgName" "$installVersion"
                        fi
                        ;;
                    1)
                        if (CanRemove $productCode);then
                            AddToMenu "Remove" "$pkgDesc" "$pkgName" "$installVersion"
                        fi
                        if (CanInstall $productCode);then
                            AddToMenu "Upgrade" "$pkgDesc" "$pkgName" "$installVersion->$isoVersion"
                        fi
                        ;;
                esac
            else
                if (CanInstall $productCode);then
                    AddToMenu "Install" "$pkgDesc" "$pkgName" "$isoVersion"
                fi
            fi
        else
            if [ -n "$installVersion" ];then
                if (CanRemove $productCode);then
                    AddToMenu "Remove" "$pkgDesc" "$pkgName" "$installVersion"
                fi
            fi
        fi
    done

    if [ $upgradeAll -eq $TRUE ];then
        AddToMenu "U" "Upgrade all products"
    fi

    if [ $removeAll -eq $TRUE ];then
        AddToMenu "R" "Remove all products"
    fi

    if [ -n "$VASPRE_PATH" ]; then
        AddToMenu "P" "Execute $VASPRE_DESC (${PREFLIGHT_STATUS})"
    fi

    if [ -x "$VASJOIN_SH" ]; then
        joined=`$VASTOOL -u host/ info id 2> /dev/null`
        if [ -n "$joined" ];then
            AddToMenu "J" "Join Active Directory (Currently joined to '`$VASTOOL info domain`')"
            AddToMenu "S" "Join (simple) Active Directory (Currently joined to '`$VASTOOL info domain`')"
        else
            AddToMenu "J" "Join Active Directory (Currently not joined)"
            AddToMenu "S" "Join (simple) Active Directory (Currently not joined)"
        fi
    fi

    if [ -n "$VASCLNT_INSTALLED_VERSION" -o -n "$VASCLNTS_INSTALLED_VERSION" ];then
        AddToMenu "L" "Copy license file(s)"
    fi

    AddToMenu "H" "Help"
    AddToMenu "Q" "Quit"

    DebugScript $SCRIPT_NAME "MENU_ARRAY: $MENU_ARRAY"
    DebugScript $SCRIPT_NAME "---"
}

#=============================================================================#
#                                                                             #
#                             Main script body                                #
#                                                                             #
#=============================================================================#
. $COMMON_LIBRARY_SH

DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Entering interactive-install.sh()"
DebugScript $SCRIPT_NAME "==="

while true; do
    DisplayMenu

    # $MENU_ARRAY contain a list of the product indicator/names for passing on.
    # Uncomment this next line to see that list:
    # echo "MENU_ARRAY=$MENU_ARRAY"
    remove_it=$FALSE
    
    printf "\n   Select an option from the above menu: "; read answer
    if [ $? -ne $SUCCESS ];then
        echo "ERROR: Unable to read input from command line"
        ExitInstall $FAILURE "interactive-install, line ${LINENO:-?}"
    fi

    if [ -z "$answer" ];then
        continue
    fi
    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "RESPONSE: [[[[[[ $answer ]]]]]]"
    DebugScript $SCRIPT_NAME "   "

    # Lose any stuff that's not an item choice (strictly speaking)...
    answer=`echo $answer | awk '{ print $1 }'`
    case "$answer" in
        # Valid non-numeric choices are only the following:
        "h"|"H") DisplayHelp "$help_op_list"            ;;
        "q"|"Q") ExitInstall 0                          ;;
        "p"|"P") DoPreflight                            ;;
        "j"|"J") DoVasJoin                              ;;
        "s"|"S") INSTALL_MODE="simple";DoVasJoin;INSTALL_MODE="interactive"  ;;
        "l"|"L") InteractiveCopyLicenseFile             ;;
        "u"|"U") ExecuteCommand "upgrade"               ;;
        "r"|"R") ExecuteCommand "remove"                ;;
        # -------------------------------------------------------------------------
        *)
            # Verify that answer is a number
            answer=`expr "$answer" + 0 2> /dev/null`
            if [ -z "$answer" ];then
                printf "\nNOTE: Invalid menu item. Please choose one of the menu items listed.\n"
            else
                command=`eval echo $MENU_ARRAY | awk "{ print \\$($answer) }" 2> /dev/null | sed -e '/ /d' `
                if [ -z "$command" ];then
                    printf "\nNOTE: Invalid menu item ($answer). Please choose one of the menu items listed.\n"
                else
                    ExecuteCommand "$command"
                fi
            fi
            ;;
    esac
    DebugScript $SCRIPT_NAME "   "
done

DebugScript $SCRIPT_NAME "==="

exit 0
