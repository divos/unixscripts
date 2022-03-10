#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# get-vas-os-code.sh
#
#     Helper script for determining SAS OS code needed to find packages
#
# Version: 5.0.5.57504
#==============================================================================
SCRIPT_NAME="get-vas-os-code.sh"

SetVASPath()
{    
    case $HOST_OS_NAME in
        "SunOS")
            case $HOST_HARDWARE in
                "sparc")
                    if [ "$HOST_OS_VERSION" -ge 10 ]; then
                        HOST_PKG_PATH="solaris10-sparc"
                    else
                        HOST_PKG_PATH=
                    fi
                    ;;
                   "x86") HOST_PKG_PATH="solaris8-x86"              ;;
                "x86_64") HOST_PKG_PATH="solaris10-x64"             ;;
                       *) HOST_PKG_PATH=                            ;;
            esac
            ;;

        "AIX")
            case $HOST_OS_VERSION in
                    "4.3") HOST_PKG_PATH= 		    ;;
                    "5.1") HOST_PKG_PATH="aix-51"   ;;
                    "5.2") HOST_PKG_PATH="aix-51"   ;;
                    "5.3") HOST_PKG_PATH="aix-53"   ;;
                    "6."*) HOST_PKG_PATH="aix-61"   ;;
                        *) HOST_PKG_PATH="aix-71"   ;;
            esac
            ;;

        "HP-UX")
            if [ "x$HOST_HARDWARE" = "xia64" ];then
                HOST_PKG_PATH="hpux-ia64"

            else
                case $HOST_OS_VERSION in
                    "11.00") HOST_PKG_PATH="hpux-pa"        ;;
                    "11.11") HOST_PKG_PATH="hpux-pa-11v1"   ;;
                          *) HOST_PKG_PATH="hpux-pa-11v3"   ;;
                esac
            fi
            ;;

        "Darwin")
            HOST_PKG_PATH="macos"
            ;;

        "Linux")
            if [ "x$HOST_HARDWARE" = "xppc" ];then
				if [ "x$HOST_OS_DISTRO" = "xSuSE" ];then
					if ( echo "$HOST_OS_VERSION" | grep "^8" > /dev/null 2>&1) ;then
						HOST_PKG_PATH="linux-glibc22-ppc64"
					else
						HOST_PKG_PATH="linux-ppc64"
					fi
				else
					HOST_PKG_PATH="linux-ppc64"
				fi
            else
                HOST_PKG_PATH="linux-$HOST_HARDWARE"
            fi
            ;;
        "FreeBSD")
            HOST_PKG_PATH="freebsd-$HOST_HARDWARE"
            ;;
        *)
            HOST_PKG_PATH=
        ;;
    esac
}

if [ -z "${MAIN:-}" ];then
    HOST_PKG_PATH=
    SetVASPath
    
    printf "$HOST_PKG_PATH\n"

    exit 0
fi
