#!/bin/sh
#==============================================================================
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# common-debug.sh
#
#                   Functions to help debug Vintela installation scripts. This
#                   script is merely included by others.
#
# Version: 5.0.5.57504
#==============================================================================
if [ -z "${MAIN:-}" ];then
    echo "ERROR: Not main executable. Please run install.sh located at ISO root."
    exit 1
fi

###################################################
# Initialize debug files
#
#   This should only be called once
#
###################################################
DEBUG_SCRIPT_DAT=install-sh.dat
TRACEFILE_DIR=/tmp
InitializeDebug()
{
    # Skip if debug is off
    if [ $DEBUG = $FALSE ]; then
        return
    fi

    # If we can't write to the tracefile directory, then we won't trace at all even if the debug level
    # otherwise permits it.
    if [ -z "$TRACEFILE_PATH" ];then
        TRACEFILE_PATH=$TRACEFILE_DIR/$DEBUG_SCRIPT_DAT

    # Test if /tmp is writable
    rm -f "$TRACEFILE_PATH"
    touch "$TRACEFILE_PATH" 2> /dev/null
    if [ $? -eq $SUCCESS ]; then
        {
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            echo `date`
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        } >> "$TRACEFILE_PATH"
        chmod 644 "$TRACEFILE_PATH"
    else
        TRACEFILE_PATH=
    fi
fi

    if [ -z "$TRACEFILE_PATH" ];then
        $DEBUG=$FALSE
    else
        printf "\n   (See debug trace in file '$TRACEFILE_PATH')\n"
    fi
}

###################################################
# Send debug messages to debug file
#
#   Input:
#        scriptName
#        message
#
#   NOTE: There are several message short-cuts
#      '   ' expands to an empty line
#      '---' expands to a long single line
#      '===' expands to a long double line
#
###################################################
DebugScript()
{
    scriptName="${1:-}"
    shift
    message="${*:-}"

    if [ $DEBUG = $FALSE ]; then
        return
    fi

    if [ "x$message" = "x---" ]; then
        { echo "-------------------------------------------------------------------"
        } >> "$TRACEFILE_PATH"
    elif [ "x$message" = "x===" ]; then
        { echo "==================================================================="
        } >> "$TRACEFILE_PATH"
    elif [ "x$message" = "x   " ]; then
        { printf "\n"
        } >> "$TRACEFILE_PATH"
    else
        { printf "$scriptName: $message\n"
        } >> "$TRACEFILE_PATH"
    fi
}

