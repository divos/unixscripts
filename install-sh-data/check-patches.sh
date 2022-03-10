#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# check-patches.sh
#
#                   Workhorse script for checking host platform maintenance
#                   levels and patches. This is pretty nasty stuff: be careful.
#
#                   This script verifies that the latest patches required for a
#                   given host environment (OS, version, etc.) are present.
#
#                   Note: preflight requires consistent function names and that
#                   each receives distro/version as a parameter and does not
#                   depend on outside variables. (i.e. each function is standalone)
#
# Version: 5.0.5.57504
#==============================================================================
SCRIPT_NAME="check-patches.sh"

if [ -z "${MAIN:-}" ];then
    echo "ERROR: Not main executable. Please run install.sh located at ISO root."
    exit 1
fi

LinuxLibcVersionUnknown() {
  printf "Please ensure you have libc version $1 or later installed.\n"
  result=$SUCCESS
}

Linuxsse2Check() {
  if [ `uname -m` = "ia64" ]; then
      return
  fi

  if [ `uname -m` = "ppc64" ]; then
      return
  fi

  if [ `uname -m` = "ppc64le" ]; then
      return
  fi

  if [ ! -f /proc/cpuinfo ] ; then 
      return
  fi

  if grep ^flags /proc/cpuinfo >/dev/null 2>&1 ; then
      :
  else
      return 
  fi

  if grep sse2 /proc/cpuinfo >/dev/null 2>&1 ; then
      result=$SUCCESS
  else
      result=$FAILURE
      printf "\n\n\n***************** WARNING *****************\n"
      printf "SAS requires the sse2 instruction set ( Pentium 4 or higher )\n"
      printf "This will install but fail to run.\n"
      printf "***************** WARNING *****************\n\n"
  fi
}

LinuxLibcCheck() {
  local libcFilename version requireVersion
  local majorVersion minorVersion microVersion
  local requireMajor requireMinor requireMicro
  local archPath

  if [ `uname -m` = "ia64" ]; then
    requireMajor=2
    requireMinor=3
    requireMicro=5
  else
    requireMajor=2
    requireMinor=4
    requireMicro=0
  fi

  if [ $requireMicro -eq 0 ]; then
    requireVersion="$requireMajor.$requireMinor"
  else
    requireVersion="$requireMajor.$requireMinor.$requireMicro"
  fi

  P="`uname -p`"
  if [ "x$P" =  "xx86_64" ] || [ "x$P" = "xppc64le" ] || [ "x$P" = "xaarch64" ] ; then
    archPath="/lib64/libc-2.*.so"
  fi

  libcFilename=/lib/libc.so.6
  if ! [ -r "$libcFilename" ]; then
    for file in /lib/libc-2.*.so /lib/*-linux-*/libc-2.*.so $archPath; do
      if [ -r "$file" ]; then
        libcFilename="$file"
        break
      fi
    done
  fi

  if ! [ -r "$libcFilename" ]; then
    printf "Failed to find libc.\n"
    LinuxLibcVersionUnknown "$requireVersion"
    return
  fi

  version=`$libcFilename | head -1 | sed -e 's/.*version \([0-9]\+\.[0-9]\+\(\.[0-9]\+\)\?\)[^0-9]*.*/\1/'`
  majorVersion=`echo $version | cut -d. -f1`
  minorVersion=`echo $version | cut -d. -f2`
  microVersion=`echo $version | cut -d. -f3`
  if [ "$microVersion" = "" ]; then
    microVersion=0
  fi

  if [ $majorVersion -gt $requireMajor ]; then
    result=$SUCCESS
  elif [ $majorVersion -eq $requireMajor ]; then
    if [ $minorVersion -gt $requireMinor ]; then
      result=$SUCCESS
    elif [ $minorVersion -eq $requireMinor ]; then
      if [ $microVersion -ge $requireMicro ]; then
        result=$SUCCESS
      else
        result=$FAILURE
      fi
    else
      result=$FAILURE
    fi
  else
    result=$FAILURE
  fi

  if [ $result = $FAILURE ]; then
    printf "libc version $requireVersion or later is required but $version was found.\n"
  fi
}

###############################################
#
#  Require glibc >= 2.4
#
#   Input:
#       distro      Linux distribution
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
###############################################
CheckLinuxPatches()
{
    distro=${1:-unknown}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CheckLinuxPatches(distro=$distro)"
    DebugScript $SCRIPT_NAME "---"

    LinuxLibcCheck

    if [ $result = $SUCCESS ] ; then
        Linuxsse2Check
    fi

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
}

###############################################
#
# Solaris   8: Patch 108993-01 or greater on SPARC, 
#              Patch 108994-01 or greater on x86
# Solaris   9: No required patches
# Solaris  10: Solaris 10 8/07 (Update 4)
#
#   Input:
#       version     OS version
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
###############################################
CheckSolarisPatches()
{
    version=${1:-unknown}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CheckSolarisPatches(version=$version)"
    DebugScript $SCRIPT_NAME "---"

    case $version in
        8)
            hardware=`uname -p`
            case $hardware in
                sparc)
                    patches="108993-1"
                    ;;
                *)
                    patches="108994-1"
                    ;;
            esac
            ;;

        9)
            hardware=`uname -p`
            case $hardware in
                sparc)
                    patches="113319-22 112960-14"
                    ;;
            esac
            ;;

        10)
            patches=
        ;;
    esac

    for patch in $patches; do
        patchNum=`echo $patch | cut -d- -f 1`
        reqLevel=`echo $patch | cut -d- -f 2`

        # Don't use awk. Solaris awk in /usr/bin chokes on long lines, such as
        # those produced by `showrev -p`. See bug #21844.
        level=`showrev -p | grep "^Patch: $patchNum" | cut -d' ' -f 2 | sed -e 's/.*-0*//' | sort -n | tail -1`
        if [ ${level:=0} -lt $reqLevel ]; then
            # Figure out if the patch is obsolete
            # Doesn't verify the reqLevel, assumes that if the patch is
            # obsolescent then it is probably completely so.
            if showrev -p | sed -e 's,.*Obsoletes:\([^:]*\).*,\1,' | grep -- " $patchNum-" >/dev/null; then
                # This patch is obsolete
                :
            else
                printf "
For best results, SAS prefers Solaris $version to have patch $patch or later. The
present level is $level. Use command showrev -p to view installed patches.\n"
                result=$FAILURE
            fi
        fi
    done
    # Now requiring update 10 or higher for solaris 10 per Bug 804105
    if test "$version" = 10; then
        solaris_10_version=`head -1 /etc/release`
        update_year=`head -1 /etc/release | cut -d/ -f2 | cut -d' ' -f1`

        if test "$update_year" -lt 11; then
            printf "
Solaris 10 8/11 (Update 10) or higher is required. It looks like you have $solaris_10_version.\n"
            result=$FAILURE
        fi
    fi

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
}

###############################################
#
# AIX 5.3: OS level 5300-05 or greater
# AIX 6.1: No required patches
# AIX 7.1: No required patches
#
#   Input:
#       version     OS version
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
###############################################
CheckAIXPatches()
{
    version=${1:-unknown}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CheckAIXPatches(osversion=$version)"
    DebugScript $SCRIPT_NAME "---"

    level=`oslevel -r 2> /dev/null | sed -e 's/.*-//;s/^0*//'`
    case $version in
        5.3)
            reqLevel=5
            ;;

        6.1)
            reqLevel=0
            ;;
        7.1)
            reqLevel=0
            ;;
        *)
            reqLevel=0
            ;;
    esac

    if [ ${level:=0} -lt ${reqLevel:-99} ];then
        result=$FAILURE
        printf "
For best results, SAS prefers an AIX $version maintenance level of $reqLevel or
later. The present level is $level.\n"
    fi

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
}

###############################################
#
# HPUX 11.11:
#       GOLDQPK11i (i.e. GOLDAPPS11i and GOLDBASE11i) (version?)
#       BUNDLE11i (version?)
#       ld(1) and linker tools cumulative patch (PHSS_30970 or greater)
# HPUX 11.23: No required patches
# HPUX 11.31: No required patches
#
#   Input:
#       version     OS version
#
#   Output:
#       result=$SUCCESS or $FAILURE
#
###############################################
CheckHPUXPatches()
{
    version=${1:-unknown}

    DebugScript $SCRIPT_NAME "   "
    DebugScript $SCRIPT_NAME "CheckHPUXPatches(osversion=$version)"
    DebugScript $SCRIPT_NAME "---"

    case $version in
    11.11)
        swlist=`/usr/sbin/swlist | awk '/BUNDLE11i|GOLDAPPS|GOLDBASE/{ print }' | wc -l`
        show_patches=`/usr/contrib/bin/show_patches | awk '/linker tools cumulative patch/{ print }' | wc -l`
        if [ ${swlist:-0} -lt 3 -o ${show_patches:-0} -lt 1 ];then
            printf "
For HP-UX 11.11, SAS requires the following as a minimum:
    GOLDQPK11i - GOLDBASE11i and GOLDAPPS11i quality packs
    BUNDLE11i  - Patch bundle
    ld(1) and linker tools cumulative patch (PHSS_30970 or greater)
Use command swlist to view installed patches, quality packs and bundles."
            result=$FAILURE
        fi
        ;;

        11.23)
            ;;
        11.31)
            ;;
    esac

    DebugScript $SCRIPT_NAME "Return: $result"
    DebugScript $SCRIPT_NAME "---"
}

#=============================================================================#
#                                                                             #
#                             Main script body                                #
#                                                                             #
#=============================================================================#
if [ -n "${COMMON_DEBUG_SH:-}" ];then
. $COMMON_DEBUG_SH
fi

DebugScript $SCRIPT_NAME "   "
DebugScript $SCRIPT_NAME "Entering check-patches.sh()"
DebugScript $SCRIPT_NAME "==="

# Check out the patch level of the host OS; Linux doesn't even come in here...
result=$SUCCESS
case $HOST_OS_NAME in
    "Linux")    CheckLinuxPatches   $HOST_OS_DISTRO  ;;
    "SunOS")    CheckSolarisPatches $HOST_OS_VERSION ;;
    "AIX")      CheckAIXPatches     $HOST_OS_VERSION ;;
    "HP-UX")    CheckHPUXPatches    $HOST_OS_VERSION ;;
esac

if [ $result -eq $SUCCESS ]; then
    DebugScript $SCRIPT_NAME "All necessary OS patches are installed."
else
    DebugScript $SCRIPT_NAME "Failed"
    printf "
NOTE: Patch recommendations not met.

SAS may not run correctly in all situations. Please apply patches so that we can 
ensure SAS functionality on your system.\n\n"
fi

DebugScript $SCRIPT_NAME "Exit: $result"
DebugScript $SCRIPT_NAME "==="
exit $result
# vim: set tabstop=2 shiftwidth=2:
