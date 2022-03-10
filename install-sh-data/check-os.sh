#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# check-os.sh
#
#     Helper script for determining OS information. This script is used by
#     the Bullseye build system.
#
# Version: 5.0.5.57504
#==============================================================================
SCRIPT_NAME="check-os.sh"

SetOSInfo()
{
        HOST_OS_NAME=`uname -s`
     HOST_OS_VERSION=
      HOST_OS_DISTRO=
      HOST_OS_KERNEL=`uname -r`
       HOST_HARDWARE=
           HOST_NAME=`uname -n`
           
    case $HOST_OS_NAME in
        "Linux")
            if [ -e /etc/SuSE-release ];then
                HOST_OS_DISTRO="SuSE"
                HOST_OS_VERSION=`cat /etc/SuSE-release | grep VERSION | sed -e 's/.* //'`

            elif [ -e /etc/fedora-release ];then
                HOST_OS_DISTRO=`cat /etc/fedora-release | sed -e 's/ release .*//;s/"//g;s/ (GNU\/)*Linux$//'`
                HOST_OS_VERSION=`cat /etc/fedora-release | sed -e 's/.*release //;s/ .*//'`

            elif [ -e /etc/redhat-release ];then
                HOST_OS_DISTRO=`cat /etc/redhat-release | sed -e 's/ release .*//;s/"//g;s/ (GNU\/)*Linux$//'`
                if (grep -q "XenServer" /etc/redhat-release);then
                    HOST_OS_VERSION=`cat /etc/redhat-release | sed -e 's/.*release //;s/-.*//'`

                else
                    HOST_OS_VERSION=`cat /etc/redhat-release | sed -e 's/.*release //;s/ .*//'`
                fi

            elif [ -e /etc/lsb-release ];then
                HOST_OS_DISTRO="Ubuntu"
                HOST_OS_VERSION=`cat /etc/lsb-release | grep RELEASE | sed -e 's/.*=//'`

            else
                release=`cat /proc/version | tr "$UPPER" "$LOWER"`
                if (echo "$release" | grep -q "vmnix" );then
                    HOST_OS_DISTRO="ESX"
                    HOST_OS_VERSION=`cat /proc/vmware/version | awk '/ESX/{ print $4 }'`

                elif (echo "$release" | grep -q "debian" );then
                    HOST_OS_DISTRO="Debian"
                    HOST_OS_VERSION=`lsb_release -a 2>&1 | grep Release | sed -e 's/.*\t//'`

                elif (echo "$release" | egrep -q "redhat|red hat" ); then
                    HOST_OS_DISTRO="RedHat"
                    HOST_OS_VERSION=`cat /etc/redhat-release | sed -e 's/.*release //;s/ .*//'`

                elif [ -f /etc/debian_version ] && [ -f /etc/issue ] && (cat /etc/issue | grep -iq "debian" ) ; then
                    HOST_OS_DISTRO="Debian"
                    HOST_OS_VERSION=`cat /etc/debian_version`

                elif [ -e /etc/os-release ];then
                    HOST_OS_DISTRO=`cat /etc/os-release | grep "^NAME" | sed -e 's/NAME=//;s/"//g;s/ (GNU\/)*Linux$//;s/^SLES$/SuSE/'`
                    HOST_OS_VERSION=`cat /etc/os-release | grep "VERSION_ID" | sed -e 's/VERSION_ID=//;s/"//g'`

                fi
            fi
            
            hardware=`uname -m`
            case $hardware in
                "powerpc"|"ppc64") HOST_HARDWARE="ppc"      ;;
                           "i686") HOST_HARDWARE="x86"      ;;
                                *) HOST_HARDWARE=$hardware  ;;
            esac
            ;;
        "SunOS")
            HOST_OS_VERSION=`echo $HOST_OS_KERNEL | sed -e 's/.*\.//'`
            
            hardware=`uname -p`
            if [ "x$hardware" = "xsparc" ];then
                HOST_HARDWARE=$hardware

            else
                # x64 package should work for both x64 and x86.
                HOST_HARDWARE="x86_64"
            fi
            ;;

        "AIX")
            HOST_OS_VERSION=`oslevel | awk -F. '/^[0-9]/{ print $1 "." $2}'`
            HOST_HARDWARE="ppc"
            ;;

        "HP-UX")
            HOST_OS_VERSION=`echo $HOST_OS_KERNEL | sed -e 's/B\.//'`
            
            hardware=`uname -m`
            if [ "x$hardware" = "xia64" ]; then
                HOST_HARDWARE="ia64"

            else
                HOST_HARDWARE="pa-risc"
            fi
            ;;

        "Darwin")
            HOST_OS_VERSION=`sw_vers -productVersion`
            HOST_HARDWARE=`uname -p`
            ;;
        "FreeBSD")
            HOST_OS_VERSION=`freebsd-version -u | awk -F"-" '{print $1}'`
            hardware=`uname -p`
            if [ "x$hardware" = "xamd64" ]; then
                HOST_HARDWARE="x86_64"
            else
                HOST_HARDWARE="x86"
            fi
            ;;
    esac
}

if [ -z "${MAIN:-}" ];then
    SetOSInfo

    printf "$HOST_HARDWARE,$HOST_NAME,$HOST_OS_NAME,$HOST_OS_KERNEL,$HOST_OS_DISTRO,$HOST_OS_VERSION\n"

    exit 0
fi
