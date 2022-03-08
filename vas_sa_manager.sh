#! /bin/sh
# 
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.

# This script is intended to help manage service accounts by allowing the end user to create new 
# service accounts, modify existing service accounts, turn standard users into a service account
# validate service accounts keytabs, and create keytabs for existing service accounts.
# 
# Author: Jayson Hurst
#
# This script is provided "as-is".
#
# The flow goes something like this:
#
# - Is there a ketyab for this service already?
# 	Yes - Get $samAccountName associated to keytab
#   No  - Do you want to use an existing account?
#   	Yes - Get the samAccountName/password of the AD object to create a keytab for. 
#             (We still do not know what SPN service we are working with here, nor does it matter)
#           - Does the account exists?
#           YES - lookup the SPN's on the supplied samAccountName
#               - Does the AD object have SPN's already set
#               YES - Add them to the keytab which is then named based
#                     off the first SPN service type found.
#               NO  - Add a SPN to set in the AD object?
#                   YES - Set the SPN's for the AD object, this includes both the fqdn and shortname.
#                       - use the suplied value to derive the name of the keytab.
#               - Add the ad Objects samAccountName as an entry in the keytab (this allows for 
#                 vastool -u samAccountName -k <ketyab> to work)
#               - check that we were able to create the new keytab
#               YES - return success
#               NO  - exit                
#           NO - Exit
#       NO - create a new service object in AD and its associated keytab.
#   - validate the AD object and its keytab are useable
#
# vas_sa_manager.sh

set -e

VASTOOL=/opt/quest/bin/vastool
KTUTIL=/opt/quest/bin/ktutil
KLIST=/opt/quest/bin/klist
LOGFILE="/tmp/`basename $0 | grep ".sh" | sed 's/\.sh/\.log/'`.$$"
TRAP_SIGNAL_LIST="TERM INT HUP PIPE ALRM ABRT QUIT"
SERVICE_TYPE="HTTP"
VERSION="1.0.0.5"
DEFALUT_KEYTAB_PATH=/etc/opt/quest/vas
NEWLINE='
'

DEBUG=false
ALLOWKINIT=false

# Re-execute with a reasonable shell and sensible PATH on Solaris.
if id -un >/dev/null 2>&1; then
    echo ok >/dev/null
else
    if test -d /usr/xpg4/bin && test "$SAM_SANE_SHELL" != yes; then
    SAM_SANE_SHELL=yes
    export SAM_SANE_SHELL
    if echo $PATH | grep xpg4 >/dev/null 2>&1; then
        echo ok > /dev/null
    else
        PATH=/usr/xpg4/bin:$PATH
        export PATH
    fi
    echo "Re-executing with /usr/xpg4/bin in PATH..."
    exec /usr/xpg4/bin/sh "$0" "$@"
    fi
    echo "WARNING: Could not find a sensible environment, consider re-running this" >&2
    echo "         script with a POSIX-compatible shell such as bash or ksh." >&2
    echo "         eg. /bin/bash $0 $@" >&2
fi

echo1 () { echo -n "$*"; }
echo2 () { echo "$*\\c"; }
echo3 () { echo "$* +"; }

if test "x`echo1 y`z" = "xyz"; then
    echon() { echo1 "$*"; }
elif test "x`echo2 y`z" = "xyz"; then
    echon () { echo2 "$*"; }
else
    echon () { echo3 "$*"; }
fi

# debug_echo <text>
#   Prints a message to standard error if $DEBUG is defined and set to true
debug_echo () {
    if test x"$DEBUG" = x"true"; then
    echo "$*" >&2
    fi
}

#-- prints a label with dots after it, and no newline
label () {
DOTS=".............................................................................................................................."
    if [ -z $2 ]; then
      echon "  `echo $1 $DOTS | cut -c -108` "
    else
      echo  "  `echo $1 $DOTS | cut -c -108` $2"
    fi
}

#-- prints an error message and dies
die () {
    echo "  -> Failed: $1" >&2
    $logfile_written && echo "(Log written to $LOGFILE)"
    func_cleanup
    exit 1
}

#-- prompt user for information
#   usage: query prompt varname [default]
query () {
    eval $2=
    while eval "test ! -n \"\$$2\""; do
        if read xx?yy <$0 2>/dev/null; then
            eval "read \"$2?$1${3+ [$3]}: \"" || die "(end of file)"
        else
            eval "read -p \"$1${3+ [$3]}: \" $2" || die "(end of file)"
        fi
        eval : "\${$2:=\$3}"
    done
}

query_noescape() {
    eval $2=
    while eval "test ! -n \"\$$2\""; do
    if read xx?yy <$0 2>/dev/null; then
        eval "read -r \"$2?$1${3+ [$3]}: \"" || die "(end of file)"
    else
        eval "read -rp \"$1${3+ [$3]}: \" $2" || die "(end of file)"
    fi
    eval : "\${$2:=\$3}"
    done

}

#-- prompt for a yes/no question default yes
yesorno () {
    echo "";
    while :; do
        query "$1" YESORNO $2
        case "$YESORNO" in
            Y*|y*) echo; return 0;;
            N*|n*) echo; return 1;;
            *) echo "Please enter 'y' or 'n'" >&2;;
        esac
    done
}


#-- record and execute a shell command
recordcmd () {

    set -- "$@" "---END---"

    LOGGER=""

    while test $# -gt 0; do
        case "$1" in
            # Special case for vastool -w password. XXXXXX out the password in the log
            -w)
                OPT=$1
                shift
                passwd=$1
                shift
                LOGGER="$LOGGER -w xxxxxx"
                set -- "$@" "$OPT" "$passwd"
                ;;
            ---END---)
                shift
                break
                ;;
             *)
                OPT="$1"
                LOGGER="$LOGGER $OPT"
                shift
                set -- "$@" "$OPT"
                ;;
        esac
    done

    (echo "# `date`";
    echo "$LOGGER";
    echo ) >> $LOGFILE
    "$@"
}

# Cleanup our temp ccname caches
func_cleanup()
{
    if [ -f "$ccname" ]; then
        rm -f "$ccname"
    fi
}

# get a TGT for some operation
#
# $1 - prompt for user
# $2 - username to user if not $USER
# $3 - password of user associated to $2
#
#
#-- get a TGT for some operations
kinit () {

    if [ -n "$KRB5CCNAME" -o -n "$uflag" ]; then
        # If KRB5CCNAME is exported, then assume kinit is done
        # If -u is supplied then a password will be prompted
        return
    fi
    
    if $ALLOWKINIT; then
        if test -r /tmp/krb5cc_`id -u`; then
           KRB5CCNAME=/tmp/krb5cc_`id -u`; export KRB5CCNAME
           return
        fi

        if [ "z$SUDO_UID" != "z" ] && [ -r /tmp/krb5cc_${SUDO_UID} ]; then
           KRB5CCNAME=/tmp/krb5cc_${SUDO_UID}; export KRB5CCNAME
           return
        fi
    fi

    local USER="${2:-$USER}"
    ccname=/tmp/.create_service_$$
    if test ! -s $ccname; then
        if [ -n "$3" ]; then
            KRB5CCNAME=$ccname; export KRB5CCNAME
            trap func_cleanup ${TRAP_SIGNAL_LIST}
            echo "$3" | $VASTOOL -s kinit "$USER" >/dev/null || die "Unable to acquire credentials"
        else
            if [ $# -gt 0 ]; then
                echo "Credentials required to $1"
            fi
            USER="${SUDO_USER:-${USER}}"
            if [ z"$USER" = z"root" ]; then USER=Administrator; fi
            echo
            echo "Please login with a sufficiently privileged domain account."

            query "Username" USER ${USER}
            KRB5CCNAME=$ccname; export KRB5CCNAME
            trap func_cleanup ${TRAP_SIGNAL_LIST}
            recordcmd $VASTOOL kinit "$USER" || die "Unable to acquire credentials"
        fi 
    fi
}


# Given a path to a keytab return an absolute path to the keytab.
# If only a path is provided generate the keytab name based on
# the passed in name.
#
# PARAMS:
#  $1 - path to a keytab
#  $2 - Name to use when generating a missing keytab name
#
# RETURNS:
#  echo the absolute path on success, otherwise empty string
#  returns 0 for success 1 for failure
#
func_verify_keytab_path()
{
    path="$1"
    name="$2"

    if [ -d "$path" ]; then
        if [ -z "$name" ]; then
            echo ""
            return 1
        fi

        filename="$name"
        path=$path/.
    elif [ -f "$path" ]; then
        filename=`basename "$path"`
        path=`dirname -- "$path"`
    else
        tpath=`dirname -- "$path"`
        if [ ! -d "$tpath" ]; then
            echo ""
            return 1
        else
            if test `echo "$path" | grep '/'$`; then
                echo ""
                return 1
            fi
            filename=`basename -- "$path"`
            path="$tpath"
        fi
    fi

    cd "$path" 2>/dev/null && PwD=`pwd` && ( absolute=`printf %s "$PwD"`; echo "$absolute${filename:+"/$filename"}" ) || ( echo ""; return 1; )

    return 0
}


# Gets a unique list of servicePrincipalName from a given keytab for a given kvno
#
# PARAMS:
#  $1 keytab
#  $2 kvno (optional)
#
# RETURNS:
#  Unique set [encryptionType servicePrincipalName] from the given keytab for the given kvno.
#
func_get_keytab_spns()
{
    local keytab="$1"
    local kvno="$2"

    if test -f "$keytab"; then
        # If no kvno was passed in, it means the caller didn't know it or expects the default.
        # so let's get the highest kvno from the keytab and use it.
        if [ -z "$kvno" ]; then
            # Get the latest kvno from the keytab so we don't find older entries
            kvno=`$KTUTIL -k "$keytab" list | sort -rn | awk 'NR==1 {print $1}' | grep [0-9]`
        fi

        if test $kvno; then
            # Once we have the kvno we are looking for let's pull out all entries with that kvno
            # The returned data set will be [etype spn] and will be unique.
            keytab_entries="`$KTUTIL -k $keytab list | sort -rn | awk -v vno=$kvno '{ if ( $1 == vno ) print $2, $3}' | uniq`"
        fi
    fi
    echo "$keytab_entries"
}


# Gets an AD objects servicePrincipalName(s) if they are set
#
# PARAMS:
#  $1 samAccountName
#
# RETURNS:
#  List of servicePrincipalNames for samAccuntName, if no SPN's are found return empty string
#
func_get_ad_objects_spns()
{
    local SPNS=""
    local samAccountName="$1"
    if [ -n "$samAccountName" ]; then
      #this will not work so well if -u is passed on the command line, they will be prompted for
      #a password everytime.
      local searchUser=${suflag:+$suflag}
      if [ ! -n "$searchUser" ]; then
        # If KRB5CCNAME has been exported then the user has kinited so use it.
        if [ -z "$KRB5CCNAME" ]; then
            searchUser="host/"
        fi
      fi
 	  set +e
      SPNS=`recordcmd $VASTOOL ${searchUser:+-u "$searchUser"} attrs -q $samAccountName servicePrincipalName 2>/dev/null`
	  set -e
    fi

    echo "$SPNS"
}


# Query AD for the supplied name and gets the distinguishedName and then turns that into the names realm
#
# PARAMS:
#   name = $1
#
# RETURNS:
#   AD objects realm based on distinguishedName
#
func_determine_realm()
{

  local realm=
  local name="$1"
  if [ -n "$name" ]; then
  	local searchUser=${suflag:+$suflag}
        if [ ! -n "$searchUser" ]; then
            # If KRB5CCNAME has been exported then the user has kinited so use it.
            if [ -z "$KRB5CCNAME" ]; then
                searchUser="host/"
            fi
        fi
	dn=`recordcmd $VASTOOL ${searchUser:+-u "$searchUser"} attrs -q "$name" distinguishedName || die "Could not get distinguishedName for "$name" from Active Directory"`
    
    realm=`echo "$dn" | sed -n -e 's/\([Dd][Cc]=.*\)$/&_=_\1/; /_=_/ { s/.*_=_\(.*\)/\1/p; }' \
           -e 's/,[Dd][Cc]=/./g' | sed -e 's/[Dd][Cc]=/~/' -e 's/^[^~]*~//' \
           -e 's/,[Dd][Cc]=/./g' | tr "[:lower:]" "[:upper:]"`
  fi

  echo "$realm"

}


# Given a service type will create the appropriate spns
#
# service = $1
# service entries could be in any of the following forms:
#  SERVICE/fqdn
#  SERVICE/shortname
#  SERVICE/
#  SERVICE
# @REALM will be used over $realm
# realm = $2
# fqdn = $3 (optional)
#
# RETURNS:
#   service_type/fqdn@REALM
#   service_type/hostname@REALM
#
# ***Function cannot echo anything other than the desired SPNS***
#
func_create_canonical_spn()
{
    local SPNS=""
    local service_type=`echo $1 | cut -d '/' -f1`
    # check to see if a REALM was provided
    local lrealm=`echo $1 | cut -s -d '@' -f2`
    # if a REALM was provided in the service name use it over the passed in REALM?
    local realm=${lrealm:-$2}
    local fqdn=$3

    if [ -n "$service_type" ]; then

      local pfqdn=`echo $1 | cut -s -d '/' -f2 | cut -d '@' -f1`

      # Make sure there is a dot in the service name otherwise it's a shortname
      if [ -n $pfqdn ] && test `echo "$pfqdn" | grep  '\.'`; then
        fqdn=$pfqdn
      else
        shortname=$pfqdn
      fi

      #this will not work so well if -u is passed on the command line, they will be prompted for
      #a password everytime.
      local searchUser=${suflag:+$suflag}
      if [ ! -n "$searchUser" ]; then
        # If KRB5CCNAME has been exported then the user has kinited so use it.
        if [ -z "$KRB5CCNAME" ]; then
            searchUser="host/"
        fi
      fi

      if [ -n "$fqdn" ]; then
        SPNS="$service_type/$fqdn${realm+@"$realm"} $service_type/`echo $fqdn | cut -s -d '.' -f1`${realm+@"$realm"}"
      elif [ -n "$shortname" ]; then
        SPNS="$service_type/$shortname${realm+@"$realm"}"      
      else
        dnsname=`recordcmd $VASTOOL ${searchUser:+-u "$searchUser"} attrs -q host/ dNSHostName || die "Could not query host's dnsHostName"`
        dnslookup_rc=$?
        if [ $dnslookup_rc -eq 0 ]; then
            fqdn=$dnsname
        fi
        SPNS="$service_type/$fqdn${realm+@"$realm"} $service_type/`echo $fqdn | cut -s -d '.' -f1`${realm+@"$realm"}"
      fi
      
      SERVICE_TYPE="$service_type"
      debug_echo "func_create_canonical_spn SERVICE_TYPE: $SERVICE_TYPE"
	fi

	echo "$SPNS"
}


# Does an ldap query looking for the objects samAccountName
# 
# samAccountName = $1
# password = $2
#
# 
func_validate_ad_object_exists()
{
    local samAccountName="$1"
    local password="$2"
    local errornreturn=0
    if [ -n "$samAccountName" ]; then
		local searchUser=${suflag:+$suflag}
      	if [ ! -n "$searchUser" ]; then
        	# If KRB5CCNAME has been exported then the user has kinited so use it.
	        if [ -z "$KRB5CCNAME" ]; then
    	        searchUser="host/"
        	fi
		fi

        # If a password has been passed in then always use the samAccountName and password to validate the AD object exists
        # This way we don't prompt for a password when it's not needed.
        if [ -n "$password" ]; then
			searchUser="$samAccountName"
            errornreturn=1
        fi

	    label "Validating that AD object "$samAccountName" exists in AD"

        set +e
        #DN=`recordcmd $VASTOOL ${searchUser:+-u "$searchUser"} ${password:+-w "$password"} attrs -q $samAccountName distinguishedname` 2>/dev/null
        DN=`recordcmd $VASTOOL ${searchUser:+-u "$searchUser"} ${password:+-w "$password"} attrs -q $samAccountName distinguishedname  </dev/null 2>/dev/null`
        rval=$?
        set -e

        if [ $rval -ne 0 ]; then

                echo "AD object $samAccountName NOT found"

                # As of right now only return if the ERRNO is "VAS_ERR_NOT_FOUND", this will give the calling function a chance
                # to handle it if they wish to create the object.
                if [ $errornreturn -eq 1 ] || [ $rval -ne 8 ]; then
                    echo "The error message was:"
                    $VASTOOL ${searchUser:+-u "$searchUser"} ${password:+-w "$password"} attrs -q $samAccountName distinguishedname </dev/null 2>&1 | sed -e 's/^/  /'
                    echo "$DN"
                    exit ${rval:-1}
                else
                    return ${rval:-1}
                fi
        fi
    	echo "AD object found"
        label "Using AD object" $DN
    fi
    return 0
}


# Sets an AD objects servicePrincipalNames(s)
# Strips any @REALMS from the spns before setting them.
#
# PARAMS:
#  $1 samAccountName of AD object to set SPN's
#  $2 SPNS to add to AD object
# 
func_set_ad_objects_spns()
{
    local samAccountName="$1"
    # We need to make sure that there are no @REALMS in the SPNS or they will not be set correctly.
    local SPNS="`echo $2| sed -e 's/@[^@]* / /g' -e 's/@[^@]*$//g'`"
    echo "SPNS: $SPNS"

    if [ -n "$samAccountName" ]; then
        recordcmd $VASTOOL ${uflag:+-u $uflag} setattrs -m -u "$samAccountName" servicePrincipalName $SPNS
    else
        die "SamAccoutName must be specified"
    fi
}


# Updates the given keytab. Does not allow for dupliate entries based on
# kvno, encryption type and servicePrincipalNames.
#
# $1 - keytab - list of SPNS from the keytab
# $2 - ad_object_spns - list of SPNS from the ad object
# $3 - password associated to the AD object
# $4 - ad_realm - AD realm of the ad object
# $5 - etypes - Desired encryption types
#
func_update_keytab()
{

    local keytab="$1"
    local ad_object_sps="$2"
    local password="$3"
    local realm="$4"
    local etypes="$5"

    if test -f "$keytab"; then
        # Get the latest kvno from the keytab so we don't try to update old entries
        # //TODO this can also be achieved by getting a ccache for the object using the new
        # password `echo "$password" | KRB5CCNAME=/tmp/krb5cc_$$ /opt/quest/bin/vastool -s kinit -S $spn $spn (save to temp ccache)
        # echo "Test1234" | KRB5CCNAME=/tmp/krb5cc_100 /opt/quest/bin/vastool -s kinit -S srogers@one.prod srogers@one.prod
        # $ /opt/quest/bin/klist -c /tmp/krb5cc_100 -v | grep -A 3 "Server: srogers@ONE.PROD" | grep kvno | awk '{print $5}'
        # trap 'rm -f /tmp/krb5cc_100' ${TRAP_SIGNAL_LIST}
        #
        # Then cleanup the tmp ccache.
        kvno=`$KTUTIL -k "$keytab" list | sort -rn | awk 'NR==1 {print $1}' | grep [0-9]`
        debug_echo "kvno: $kvno"
    fi

    keytab_entries=`func_get_keytab_spns "$keytab" "$kvno"`

# Not sure why the service_spn needs to be set here based on the objects SPNS
#   service_spn="$spn"

    # Generate a dataset of wanted [etype spn]
    for spn in $ad_object_sps; do
        for etype in $etypes; do
            desired_entries="${desired_entries}$etype "$spn${realm+@"$realm"}"$NEWLINE"
        done
    done

    # get the set complement of the sets

    missing_entries=`echo "$desired_entries" | grep -vxFe "$keytab_entries"`
    missing_ientries=`echo "$desired_entries" | grep -ivxFe "$keytab_entries"`

    OLD_IFS="$IFS"
    IFS="$NEWLINE"

    if test "$missing_entries"; then
        echo ""
        echo "Adding entries to $keytab for:"
        echo ""

        for missing in $missing_entries; do

            m_etype=`echo "$missing" | cut -d ' ' -f1`
            m_spn=`echo "$missing" | cut -d ' ' -f2`

            # This is rest of the statement from above "Addding entries to $keytab for:"
            echo "    "$m_spn" EncryptionType: $m_etype"

            $KTUTIL -k "${keytab}" add -V ${kvno:-1} -p "$m_spn" -e "$m_etype" -w "$password" || die "Cannot add "$m_spn" to service account keytab: ${keytab}"
        done
    fi
    IFS="$OLD_IFS"
}

# Create a keytab based off of an existing AD object.
#
# Get a list of SPN's and if service_type is specified make sure one of the SPN's match it.
# if a service_type is not specified then just create a keytab based on what SPN's are available.
# if no SPN's exists, ask user if they wish to add an spn.  if yes, then add the spn to the AD
# object and update the keytab. If no then clean up and exit.
#
#   etypes (optional)
#
func_create_service_account_keytab()
{
    local service_samAccountName="$1"
    local service_spn="$2"
    local keytab="$3"
    local password="$4"
    local password_reset="$5"
    local etypes="$6"

    local service_type=${SERVICE_TYPE}

    #if etypes are passed in then overwrite the defaults
    if test -z $etypes; then
        etypes="aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 arcfour-hmac-md5 ${USEDES:+"des-cbc-crc des-cbc-md5"}"
    fi

    echo "Creating keytab $keytab for Active Directory object $service_samAccountName"
    kinit "query/modify the Active Directory object $service_samAccountName" "$service_samAccountName" "$password"

    #At this point if -k was specified (ALLOWKINIT=true) the following calls could fail
    #if the KRB5CCACHE is invalid for any reason. 
    realm=`func_determine_realm "$service_samAccountName"`

#    service_spn_exists="0"
    SPNS=`func_get_ad_objects_spns "$service_samAccountName"` 

    if test "$SPNS"; then
        # Add the client principal name to this list
        SPNS=$SPNS$NEWLINE`echo "$service_samAccountName" | cut -d "@" -f1`
        func_update_keytab "$keytab" "$SPNS" "$password" "$realm" "$etypes"
    else
		echo "A servicePrincipalName could not be found for Active Directory object "$service_samAccountName""
        if yesorno "Do you want to add ${service_spn:+"$service_spn as "}a servicePrincipalName?" yes; then
            echo "This will create a servicePrincipalName on the Active Directory object for both the fully qualified domain name and shortname"
			# if the service_spn has not been set then ask for a spn
			if ! test "$service_spn"; then
	            query "ServicePrincipalName"  service_spn
			fi
        fi

        if [ x"$service_spn" != "x" ] || [ x"$derived_spns" != "x" ]; then
            derived_spns="$derived_spns `func_create_canonical_spn "${service_spn}" "$realm"`"
            debug_echo "Derived SPNS: $derived_spns"
            debug_echo "SERVICE_TYPE: $SERVICE_TYPE"
            func_set_ad_objects_spns "$service_samAccountName" "$derived_spns"
            func_create_service_account_keytab "$service_samAccountName" "$service_spn" "$keytab" "$password" "$password_reset"
            return 0
        else
            echo "No servicePrincipalNames available, keytab could not be created"
            password=
            exit 0
        fi
    fi

    # Check to make sure that the service types name exists for the service account
    # At this point we have already updated the keytab with the keys from the AD spns
    # so if this doesn't exist it will be considered an explicit SPN
    if [ "x$service_type" != "x" ]; then
        if echo `func_get_keytab_spns "$keytab"` | grep -i "$service_type/" >/dev/null; then
            service_spn_exists="1"
        fi
    fi

    if [ "x$service_type" != "x" ]; then
	    # If a service for $service_type/ doesn't exist then we will create an explicit one
	    if [ "$service_spn_exists" -ne "1" ]; then
    	    local searchUser=${suflag:+$suflag}
	        if [ ! -n "$searchUser" ]; then
    	        # If KRB5CCNAME has been exported then the user has kinited so use it.
        	    if [ -z "$KRB5CCNAME" ]; then
            	    searchUser="host/"
	            fi
    	    fi
            dnsname=`recordcmd $VASTOOL ${searchUser:+-u "$searchUser"} attrs -q host/ dNSHostName`
	        dnslookup_rc=$?
    	    if [ $dnslookup_rc -eq 0 ]; then
	
                default_service_type="$service_type/$dnsname"
        	    service_spn="$default_service_type"

            	echo "Adding explicit spn for $default_service_type to keytab"
	            echo ""
    	        echo "  WARNING: Explicit service names such as $service_type"
        	    echo "  may not work in all environments."
	            echo ""

                func_update_keytab "$keytab" "$default_service_type" "$password" "$realm" "$etypes"

    	    fi
	    fi
	fi

    #clear the password 
    password=
    
    echo ""

    label "checking new service keytab file exists"

    if test -f "$keytab"; then
        echo "found"
    else
        echo "still not found or could not be created"
        die "Cannot find $keytab"
    fi

    echo ""
}

# Creates a serviceAccount object in AD and writes out a
# keytab file to $KEYTAB
#
# PARAMS:
#  $1 container DN (default if not set)
#  $2 service account name
#  $3 keytab
#
func_create_ad_service_account_and_keytab()
{

    local container="$1"
    local service_spn="$2"
    local keytab="$3"
    local keytab_path=`dirname "$keytab"`

    if test -w "$keytab_path"; then
        kinit "create the service account"
        recordcmd $VASTOOL \
        ${uflag:+-u $uflag} \
        service create ${container:+-c "$container"} ${keytab:+-k "$keytab"} "$service_spn" || \
        die "Cannot create $service_spn service account"

        if [ "x$USEDES" = "xtrue" ]; then
            func_set_use_des_for_ad_account $service_spn $keytab
        fi
    else
        die "user: $USER does not have permissions to create the keytab in "$keytab_path/""
    fi
}

func_set_use_des_for_ad_account()
{
    local service_spn=$1
    local keytab=$2

    # Change the password on the AD object and set DES keys at that time
     recordcmd $VASTOOL \
     ${uflag:+-u $uflag} \
     passwd -er -k $keytab $service_spn || \
     die "Cannot create DES keys in keytab $keytab"
}

func_create_ketyab_for_ad_service_account()
{
    local service_samAccountName="$1"
    local keytab="$2"
    local service_spn="$3"

    func_validate_password()
    {
        local validate=0
        local tries=0

        while [ "$tries" -lt 3 ] && [ "$validate" -eq 0 ]; do
            oldmodes=`stty -g`
            stty -echo
            query_noescape "Password for "$service_samAccountName"" PASSWORD1
            echo
            query_noescape "Validate Password for "$service_samAccountName"" PASSWORD2

            stty $oldmodes

            if [ "$PASSWORD1" != "$PASSWORD2" ]; then
                echo
                echo "  Passwords for "$service_samAccountName" do not match"
                tries=`expr $tries + 1`
            else
                echo
                func_validate_ad_object_exists "$service_samAccountName" "$PASSWORD1"
                validate=1
            fi
        done

        if [ $validate != 1 ]; then
            die "Could not validate password"
        fi
    }

    local keytab_path=`dirname "$keytab"`
    local keytab_name=`basename "$keytab"`

    # If we cannot write the keytab out then do not even bother to go on.
    if ! test -w "$keytab_path"; then
        die "user: $USER does not have permission to create $keytab_name in "$keytab_path/""
    fi

    if yesorno "Do you want to change/set the password for $service_samAccountName" no; then
        if yesorno "Do you want to use $service_samAccountName to change their password" yes; then
            #Prompt for password for $service_samAccountName and validate passwords are the same and is valid 
            func_validate_password
        else
            kinit "set ${service_samAccountName} password"
            # Validate that the ad object exists using the kinit user from above
            set +e
            func_validate_ad_object_exists "$service_samAccountName"
            if [ $? -eq 8 ]; then
                # //TODO the user does not exist in AD do we prompt to create?
                echo ""
            fi
            set -e
        fi

        if yesorno "Do you want to change the password for "$service_samAccountName" to a random secure password?" no; then
            local use_random_passwd=1
        fi
        local setPasswdUser=${spuflag:+$spuflag}
        if [ ! -n "$setPasswdUser" ]; then
            # If KRB5CCNAME has been exported then the user has kinited so use it.
            if [ -z "$KRB5CCNAME" ]; then
                setPasswdUser="$service_samAccountName"
                local isPasswdUser="true"
            fi
        fi

        #Because of BUG # 489417 when using a custome KRB5CCNAME location user will be prompted for a password here.
        PASSWORD1=`$VASTOOL ${setPasswdUser:+-u "$setPasswdUser"} ${isPasswdUser:+-w "$PASSWORD2"} -q passwd -k "$keytab" ${use_random_passwd:+"-r"} -o ${KRB5CCNAME:+"$service_samAccountName"} | sed -e 's/[ \\]/\\&/g;1q'`
        if ! test $PASSWORD1; then
            die "Could not reset password for $service_samAccountName"
        else
            echo "Successfully changed password for $service_samAccountName"
            if yesorno "output new password to screen?" no; then
                echo "$PASSWORD1"
            fi
            password_reset=1
        fi
        echo
    else
        #Prompt for password for $service_samAccountName and validate passwords are the same and is valid 
        func_validate_password
    fi

    func_create_service_account_keytab "$service_samAccountName" "$service_spn" "$keytab" "$PASSWORD1" "$password_reset"
    PASSWORD1=
    PASSWORD2=

}


# Checks the the keytab is useable by authenticating using the keytab and requesting a service ticket from it.
#
#  service_spn = $1 
#  keytab = $2
#
func_check_ad_service_account()
{
    local service_samAccountName=$1
    local keytab=$2
    local results

    label "Can "$USER" read "$keytab""

	if test -r "$keytab"; then
      echo "yes"
	  tmpcc=/tmp/.service_vascc$$
	  old_KRB5CCNAME="${KRB5CCNAME}"
      for spn in `$KTUTIL -k "$keytab" list | awk '{print $3}' | sort -u | grep -vx Principal`; do
	  	label "checking $service_samAccountName can request a service ticket for $spn"

        if results=`KRB5CCNAME=FILE:$tmpcc recordcmd $VASTOOL -u "$service_samAccountName" -k "$keytab" auth -S "$spn" -k "$keytab" </dev/null 2>/dev/null`; then
		  echo "yes"
	  	else
		  echo "no"
          echo "$results"
	  	fi
      done
	  KRB5CCNAME="${old_KRB5CCNAME}"
	  rm -f $tmpcc
	else
      echo "no"
      echo >&2
      echo "Skipping keytab validity check (The user: $USER cannot read the file "$keytab")." >&2
      echo >&2
	fi
}

#
# Setups an AD service account
# $1 service_type: i.e. HTTP/ CIFS/ SAP/ etc...
# $2 keytab. If not set then uses
#    /etc/opt/quest/vas/$service_type.keytab
#
func_setup_ad_service_account()
{

    local container=
    local service_spn="${2}"
    local service_type=`echo $service_spn | cut -d '/' -f1`
    local keytab="${1}"
    SERVICE_TYPE="$service_type"

    if [ -z "$keytab" ]; then
		query "Specify the keytab path: " keytab
    fi

    keytab=`func_verify_keytab_path "$keytab"` || die "Invalid Keytab $keytab"

    # At this point we have a path to a keytab file, we need to
    # - Verify if it points to an existing keytab
    # - If it doesn't verify it points to an existing directory (valid)
    # - Some vastool commands expect an absolute path to the keytab so we should do our
    #   best to set that up.

    KEYTAB_EXISTS=no

    label "looking for keytab $keytab"

    if test -f "$keytab"; then
        KEYTAB_EXISTS=yes
    else
        echo "not found"
    fi

    # Does a keytab already exist?
    if [ $KEYTAB_EXISTS = no ]; then

        if yesorno "Use an existing Active Directory user or service account?" yes; then

        cat <<-.

    This step creates a service keytab for a pre-existing
    service account in Active Directory.
        
    You will need to know the account password for the
    service account or have permissions to reset the accounts
    password.

    Contact your systems administration staff if you do not.

.

            if [ -z "$service_samAccountName" ]; then
                echo "Please specify the samAccountName of the existing service:"
                    query "samAccountName" service_samAccountName
            fi
 
            func_create_ketyab_for_ad_service_account "$service_samAccountName" "${keytab}" "${service_spn}"
		else
            if yesorno "Create the${service_type:+" $service_type"} service account?" yes; then
			    if [ "x$service_spn" = "x" ]; then
			        query "Please specify the servicePrincipalName for this service account" service_spn
			    fi

                if [ "x$keytab" = "x" ]; then
                    echo "Please specify where to create the keytab for service $service_spn"
					query "Service Acount keytab" keytab default
                fi

                echo "Please specify the container DN in which to create the service:"
                query "Service container DN" container default

                test x"$keytab" = x"default" && keytab="/etc/opt/quest/vas/`echo $service_spn | cut -d '/' -f1`.keytab"
    			test x"$container" = x"default" && container=

                func_create_ad_service_account_and_keytab "$container" "$service_spn" "$keytab"
                service_samAccountName="$service_spn"
            else
                echo "(Not creating $service_spn service account)"
			fi
        fi
    else
        echo "already exists."
		if yesorno "Would you like to validate that $keytab is usable?" yes; then
            if [ x"$service_spn" = "x" ]; then
	            query "Please specify the samAccountName of the service account object
that is associated to the keytab "$keytab"" service_samAccountName
            else
                service_samAccountName=$service_spn
            fi
        else
            exit 0
        fi
    fi

	func_check_ad_service_account "$service_samAccountName" "$keytab"
   
}

usage()
{
    cat <<-.
    Usage: $0 [-s ServicePrincipalName ] keytab
        -s ServicePrincipalName
            Specify the ServicePrincipalName to create.
.
}

opterr=false

while test $# -gt 0; do
	case "$1" in
	-e) USEDES=true; shift;;
    -k) ALLOWKINIT=true; shift;;
	-s) if test $# -lt 2; then
          echo "Missing argument to $1"; opterr=true; shift
        else
          service_spn="$2"; shift; shift
        fi;;
    -h) usage; exit 0;;
    -V) echo "$0 version: $VERSION"; exit 0;;
	*) keytab=$1; shift; break;;
	esac 
done

if test $# -gt 0; then
    # don't expect any further arguments
    opterr=true
fi
if $opterr; then
    usage
    exit 1
fi

func_setup_ad_service_account "${keytab}" "${service_spn}"
func_cleanup

