#!/bin/sh
################################################################################
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# bundle.sh
#
# Purpose:      Create a .tar.gz of normal system files and system information to
#               aid in the resolving of issues.
#
# Author(s):    Seth Ellsworth (seth.ellsworth@quest.com)
#
VERSION=0.8.7
#
# This script relies on internal knowledge of vasd's internal cache schema,
# which is undocumented and subject to change between releases.
#
################################################################################

################################################################################
#
# The vas_snapshot.sh script gathers the following information:
#
# Basic:
# Hostname
# Full hostname
# Platform
# uname -a
# Date
#
# VAS Basics if installed:
# Vastool version
# Site version
# Domain
# Date
# Date in AD (Doesn't modify local time)
# If a Kinit works.
# vastool info id
# vastool info site
# Number of users/groups cached.
#
# System commands, patch information:
# ipcs
# df -k
# Solaris:
#     showrev -p
# HP-UX:
#     swlist -l product *,c=patch
# AIX:
#     oslevel -s
#     oslevel -r
#     instfix -i
# vm_stat, w, free, vmstat.
# env
# ifconfig -a ( and HP equiv )
# package dump
# ulimit
# authselect list/current/check
#
# Extended VAS information:
# license info
# host object attrs
# A dump of the misc and srvinfo cache.
# A dump of the access_control cache.
# A dump of the override and mapped_user tables.
# File listings of the VAS directories
# vastool info servers
# vastool info processes
# vastool ktutil list
# preflight output
# vas_status output
# access control output
# AD security info
# Schema information
# rootDSE
# Domains in the forest
# Domain trust msds-supportedencryptiontypes values
#
# System files:
# nsswitch.conf
# /etc/resolv.conf
# /etc/syslog.conf
# /etc/rsyslog.conf
# All files in /etc/rsyslog.d/
# /etc/pam.conf
# /etc/krb5.conf
# /etc/krb5/krb5.conf
# All files in /etc/pam.d/
# /etc/security/user
# /etc/security/limits
# /etc/security/login.cfg
# /etc/default/passwd
# /usr/lib/security/methods.cfg
# /etc/irs.conf
# /etc/inittab
# /etc/nscd.conf
# authselect output
# /usr/share/authselect/
# /etc/authselect/
# ls -laR /usr/share/authselect/ /etc/authselect/
# Darwin:
#     List of files in /Library/Logs/CrashReporter
#     /Library/Preferences/DirectoryService/SearchNodeConfig.plist
#     /Library/Preferences/OpenDirectory/Configurations/Search.plist
#     /Library/Preferences/DirectoryService/ContactsNodeConfig.plist
#     /Library/Preferences/OpenDirectory/Configurations/Contacts.plist
#     /Library/Preferences/edu.mit.Kerberos
#     /etc/authorization
#     All files in /Library/Managed Preferences
#
# VAS files:
# vas.conf
# users.allow|deny
# user-override
# groups-override
# All files in .licenses/
# All files in access.d/
# lastjoin
# vdb files
# /etc/pam_radius_acl.conf
# /etc/defender.conf
# /etc/opt/quest/dnsupdate.conf
# /etc/opt/quest/vas/autogen.passwd
# /etc/opt/quest/vas/autogen.group
# grep :VAS: /etc/passwd ( merged accounts )
# grep :VAS: /etc/group ( merged groups )
# Darwin:
#     /var/root/Library/Preferences/com.quest.qasrecords.plist
#     All files in /var/opt/quest/vgp/cache/mcxsettings
#     All files in /var/opt/quest/vgp/cache_user/mcxsettings
#
# VGP info:
# listgpc
# listgpc -l
# listgpt
# listlinks
# rsop
# It does an apply with full debug, capturing the output.
# register
#
# VASYPD:
# A dump of the db file, just the table names.
# A dump of the xlate table.
# A dump of the vasypinfo table.
# ypwhich -m
#
# OTHER:
#   /opt/quest/sbin/sshd -t
#   /opt/quest/bin/testparm -s
#
# This set of information was chosen to best assist Support with any issue, and
# familiarize them with the system so they can give better support when asking
# for additional information.
#
# The resulting file will be in /tmp/ with a name of
# vas_snapshot.<hostname>.<date>.tar.gz.
#
# If you don't wish Support to have specific gathered information, either
# modify the script to not gather it, or open the archive after and remove
# the file(s) before sending.
#
################################################################################
LC_ALL=C
export LC_ALL
unset GREP_OPTIONS

################################################################################
# Functions.
################################################################################
Prep()
{
    echo "*** This script will be gathering System and VAS information ***"

    # First thing, check for root.
    if [ "`id | sed 's/uid=\([0-9]*\).*/\1/'`" -ne 0 ] ; then
        echo "Must be run as root."
        exit
    fi

    # Set up the variables and prep the directories.
    DATE=`date "+%Y-%m-%d_%H-%M-%S"`
    HOSTNAME=`hostname | cut -d. -f 1`
    DOMAINNAME=`domainname`
    VAS=/opt/quest/bin/vastool
    PREFLIGHT=/opt/quest/bin/preflight
    UPTOOL=/opt/quest/bin/uptool
    VGP=/opt/quest/bin/vgptool
    VGPM=/opt/quest/bin/vgpmod
    SQL3=/opt/quest/libexec/vas/sqlite3
    MISC_DB=/var/opt/quest/vas/vasd/vas_misc.vdb
    VAS_IDENT=/var/opt/quest/vas/vasd/vas_ident.vdb
    VASYPD_DB=/var/opt/quest/vas/vasypd/nismaps/rfc2307_nismaps.vdb
    UPPER=ABCDEFGHIJKLMNOPQRSTUVWXYZ
    LOWER=abcdefghijklmnopqrstuvwxyz
    if [ -x "${VAS}" ] ; then
        HAVE_VAS=1
    else
        HAVE_VAS=0
    fi

    OUT_DIR=/tmp/${DATE}
    OUT_MAIN=${OUT_DIR}/main.txt
    OUT_DIR_CMDS=${OUT_DIR}/cmds_out
    OUT_DIR_FILES=${OUT_DIR}/files
    OUT_BUNDLE=/tmp/vas_snapshot.${HOSTNAME}.${DATE}
    mkdir ${OUT_DIR}
    mkdir ${OUT_DIR_CMDS}
    mkdir ${OUT_DIR_FILES}
}


DeterminePlatform()
{
    unamea=`uname -a`
    name=`echo $unamea | awk '{ print $1 }'`
    case $name in
        "Linux")
            if [ -f /etc/redhat-release ] ; then
                dist=`cat /etc/redhat-release | grep Enterprise`
                if [ $? -eq 0 ]; then
                    level=`cat /etc/redhat-release | sed 's/.*release\ //' | sed 's/\ .*//'`
                    platform="RedHat$level"
                else
                    platform="RedHat"
                fi
            elif [ -f /etc/SuSE-release ] ; then
                level=`cat /etc/SuSE-release | tr "\n" ' ' | sed 's/.*=\ //' | sed 's/\([0-9]*\).*/\1/'`
                platform="SuSE$level"
            elif [ -f /etc/fedora-release ] ; then
                level=`cat /etc/fedora-release | tr "\n" ' ' | sed 's/.*=\ //' | sed 's/\([0-9]*\).*/\1/'`
                platform="Fedora$level"
            else
                platform="Linux - `uname -r`"
            fi
        ;;
        "SunOS")
            level=`echo $unamea | awk '{ print $3 }' | sed 's/[0-9]*\.\([0-9]*\)/\1/'`
            platform="Solaris$level"
            ;;
        "AIX")
            level=`oslevel | sed 's/\([0-9]*\.[0-9]*\).*/\1/'`
            platform="AIX$level"
            ;;
        "HP-UX")
            level=`echo $unamea | awk '{print $3}' | sed 's/[a-zA-Z]*\.\(.*\)/\1/'`
            platform="HP-UX${level}"
            ;;
        "Darwin")
            sw_vers=`sw_vers -productVersion`
            level=`echo $sw_vers | sed 's/\([0-9]*\.[0-9]*\).*/\1/'`
            platform="Darwin$level"
            ;;
        *)
            platform="UNKNOWN"
            ;;
    esac
}

GetCommandOutput()
{
    # Runs command $1, puts the output into file ${OUT_DIR_CMDS}/$2
    LogMainBasic "Saving output of command <${1}>"
    eval "$1" >${OUT_DIR_CMDS}/$2 2>&1
}

LogMain()
{
    echo   "Saving <${1}>"
    printf "${1}\n" >> ${OUT_MAIN}
}

LogMainBasic()
{
    printf "${1}\n"
    printf "${1}\n" >> ${OUT_MAIN}
}

GrabFile()
{
    # If it exists, grab file $1.
    if [ -f "${1}" ] ; then
        cp ${1} ${OUT_DIR_FILES}/ 2>/dev/null
        LogMainBasic "Storing file ${1}"
    fi
}

GrabDirectory()
{
    # If it exists, grab contents of dir $1 and store it at dir $2
    if [ -d "${1}" ] ; then
        cp -r "${1}" ${OUT_DIR_FILES}/${2} 2>/dev/null
        LogMainBasic "Storing directory ${1}"
        chmod 755 ${OUT_DIR_FILES}/${2}
    fi
}

GetSystemBasics()
{
    LogMainBasic "*** Gathering the system basics, script version:$VERSION ***"
    DeterminePlatform
    LogMain "Hostname:          ${HOSTNAME}"
    LogMain "Full Hostname:     `hostname`"
    LogMain "Platform:          ${platform}"
    LogMain "Uname -a:          ${unamea}"
    LogMain "Domainname:        ${DOMAINNAME}"
    LogMain "Date:              ${DATE}"
}

GetVASBasics()
{
    if [ "${HAVE_VAS}" -eq 0 ] ; then
        LogMain "VAS does not appear to be installed, skipping VAS Basics."
        return
    fi
    LogMainBasic "*** Gathering VAS basics ***"
    LogMain "Vastool version:      `${VAS} -v 2>&1 | tr '\n' ' '`"
    if [ -f /opt/quest/sbin/vasypd ] ; then
        LogMain "Vasypd version:       `/opt/quest/sbin/vasypd -v 2>&1 | tr '\n' ' '`"
    else
        LogMain "Vasypd version:       NOT INSTALLED"
    fi
    if [ -f /opt/quest/bin/vgptool ] ; then
        LogMain "Vgptool version:      `/opt/quest/bin/vgptool -v 2>&1 | tr '\n' ' '`"
    else
        LogMain "Vgptool version:      NOT INSTALLED"
    fi
    if [ -f /opt/quest/sbin/vasproxyd ] ; then
        LogMain "VasProxy version:     `/opt/quest/sbin/vasproxyd -v 2>&1 | tr '\n' ' '`"
    else
        LogMain "VasProxy version:     NOT INSTALLED"
    fi
    if [ -f /opt/quest/sbin/smbd ] ; then
        LogMain "Quest Samba version:  `/opt/quest/sbin/smbd --version 2>&1 | tr '\n' ' '`"
    else
        LogMain "Quest Samba version:  NOT INSTALLED"
    fi
    if [ -f /opt/quest/sbin/sshd ] ; then
        LogMain "Quest SSH version:    `/opt/quest/sbin/sshd -~ 2>&1 | grep SSH | tr '\n' ' '`"
    else
        LogMain "Quest SSH version:    NOT INSTALLED"
    fi
    if [ -f /opt/quest/bin/sudo ] ; then
        LogMain "Quest Sudo version:   `/opt/quest/bin/sudo -V 2>&1 | head -1 | tr '\n' ' '`"
    else
        LogMain "Quest Sudo version:   NOT INSTALLED"
    fi
    if [ -f /opt/quest/sbin/dnsupdate ] ; then
        LogMain "Safeguard DNS Update version:   `/opt/quest/sbin/dnsupdate -V 2>&1 | head -1 | tr '\n' ' '`"
    else
        LogMain "Safeguard DNS Update version:   NOT INSTALLED"
    fi
    LogMain "Site:              `${VAS} license -s`"
    DOMAIN=`${VAS} info domain 2>&1`
    LogMain "Domain:            ${DOMAIN}"
    LogMain "Date:              `date`"
    LogMain "AD Date:           `${VAS} timesync -q -d ${DOMAIN}`"
    RESULT="`${VAS} -u host/ kinit 2>&1`"
    if [ "$?" -eq 0 ] ; then
        LogMain "Kinit:             Kinit worked."
    else
        LogMain "Kinit:             Kinit of host/ failed, text: ${RESULT}"
    fi
    LogMain "info id:           `${VAS} -u host/ info id 2>&1 | tr '\n' ' '`"
    LogMain "info site:         `${VAS} -u host/ info site 2>&1`"
    LogMain "Users cached:      `${VAS} list -c users 2>&1 | grep -v '^ERROR:' | wc -l`"
    LogMain "Groups cached:     `${VAS} list -c groups 2>&1 | grep -v '^ERROR:' | wc -l`"
    for file in /opt/quest/sbin/.vasd /opt/quest/sbin/.vasd-site /opt/quest/sbin/.vasd-lic /opt/quest/sbin/vasd; do
        if [ -f $file ] ; then
            LogMain "vasd file type:    `file $file`"
            break
        fi
    done

    # Check for duplicate SPN in AD
    DN="`$VAS -u host/ attrs -q host/ distinguishedName | tr $UPPER $LOWER`"
    SPNquery="`$VAS -u host/ attrs -q host/ servicePrincipalName 2>/dev/null |  awk 'BEGIN {printf \"(|\"} {printf \"(serviceprincipalname=\" $0 \")\"}; END { printf \")\n\" }'`"
    if [ "$SPNquery" = "(|)" ] ; then
        return
    fi
    DNs="`$VAS -u host/ search -q \"$SPNquery\" distinguishedName | tr $UPPER $LOWER | grep -v \"$DN\"`"
    if [ -n "$DNs" ] ; then
        LogMainBasic "\nWARNING: Host's servicePrincipalName found elsewhere in Active Directory on object(s) with DN(s):"
        LogMainBasic "$DNs\n"
    fi
}

GetSystemCommands()
{
    LogMainBasic "*** Gathering output of OS Specific commands ***"
    GetCommandOutput "ipcs -a" "ipcs.a.out"
    GetCommandOutput "df -k" "df.k.out"
    GetCommandOutput "w" "w.out"
    GetCommandOutput "env" "env.out"
    GetCommandOutput "ulimit -a" "ulimit.out"
    if [ -x /usr/bin/authselect ] ; then
        GetCommandOutput "/usr/bin/authselect list" "authselect.list.out"
        GetCommandOutput "/usr/bin/authselect current" "authselect.current.out"
        GetCommandOutput "/usr/bin/authselect check" "authselect.check.out"
    fi
    for file in free vm_stat vmstat; do
        if [ -f /usr/bin/$file ] ; then
            GetCommandOutput "/usr/bin/$file" "$file.out"
        fi
    done
    case ${platform} in
        Solaris*)
            GetCommandOutput "showrev -p" "showrev.p.out"
            GetCommandOutput "pkginfo" "pkginfo.out"
            GetCommandOutput "ifconfig -a" "ifconfig.out"
            ;;
        HP-UX*)
            GetCommandOutput "/usr/sbin/swlist -l product *,c=patch" "swlist.l.out"
            GetCommandOutput "/usr/sbin/swlist" "swlist.out"
            GetCommandOutput "ls -la /tcb/files/auth" "tcb.ls.out"
            GetCommandOutput "for lan in `lanscan | grep lan | awk '{print $5}' | tr '\n' ' '` ; do echo \$lan; ifconfig \$lan; done" "ifconfig.out"
            ;;
        AIX*)
            GetCommandOutput "oslevel -r" "oslevel.r.out"
            GetCommandOutput "oslevel -s" "oslevel.s.out"
            GetCommandOutput "instfix -i" "instfix.i.out"
            GetCommandOutput "ifconfig -a" "ifconfig.out"
            GetCommandOutput "lslpp -L" "lslpp.L.out"
            ;;
        Darwin*)
            GetCommandOutput "ls -laR /Library/Logs/CrashReporter" "ls.crash-reporter.laR.out"
            GetCommandOutput "ifconfig -a" "ifconfig.out"
            GetCommandOutput "/opt/quest/libexec/vgp/.vgp_profile_helper -qa" "profiles.query.out"
            GetCommandOutput "/opt/quest/libexec/vgp/.vgp_profile_helper -P" "profiles.list.out"
            ;;
        *)
            GetCommandOutput "ifconfig -a" "ifconfig.out"
            GetCommandOutput "rpm -qa" "rpm.qa.out"
            GetCommandOutput "dpkg -l" "dpkg.l.out"
            ;;
    esac
    GetCommandOutput "ls -la /etc /etc/krb5 /etc/security /usr/lib/security /etc/pam.d /etc/authselect /usr/share/authselect" "system.ls.out"
}

GetVASCommands()
{
    if [ "${HAVE_VAS}" -eq 0 ] ; then
        LogMain "VAS does not appear to be installed, skipping VAS Commands."
        return
    fi
    LogMainBasic "*** Gathering output of VAS commands ***"
    GetCommandOutput "${VAS} license -qi" "vas.license.qi.out"
    GetCommandOutput "${VAS} license -s" "vas.license.s.out"
    GetCommandOutput "${UPTOOL} -u host/ info" "uptool.info.out"
    GetCommandOutput "${VAS} -d5 -e4 -u host/ attrs host/" "vas.host.attrs.out"
    GetCommandOutput "printf \".timeout 5000\nSELECT * FROM misc;\n.q\n\" |              ${SQL3} ${MISC_DB}"   "vas.misc.dump.out"
    GetCommandOutput "printf \".timeout 5000\nSELECT * FROM access_control;\n.q\n\" |    ${SQL3} ${VAS_IDENT}" "vas.access_control.dump.out"
    GetCommandOutput "printf \".timeout 5000\nSELECT * FROM user_ovrd;\n.q\n\" |         ${SQL3} ${VAS_IDENT}" "vas.user_ovrd.dump.out"
    GetCommandOutput "printf \".timeout 5000\nSELECT * FROM user_ovrd_bygroup;\n.q\n\" | ${SQL3} ${VAS_IDENT}" "vas.user_ovrd_bygroup.dump.out"
    GetCommandOutput "printf \".timeout 5000\nSELECT * FROM group_ovrd;\n.q\n\" |        ${SQL3} ${VAS_IDENT}" "vas.group_ovrd.dump.out"
    GetCommandOutput "printf \".timeout 5000\nSELECT * FROM srvinfo;\n.q\n\" |           ${SQL3} ${MISC_DB}"   "vas.srvinfo.dump.out"
    GetCommandOutput "${VAS} info servers" "vas.info.servers.out"
    GetCommandOutput "${VAS} info processes" "vas.info.processes.out"
    GetCommandOutput "${VAS} ktutil list --timestamp" "vas.ktutil.list.out"
    GetCommandOutput "${VAS} -u host/ -d5 auth -S host/" "vas.auth.out"
    FQDN=`printf ".timeout 5000\nSELECT value from misc where key='computerFQDN';\n.q\n" | ${SQL3} ${MISC_DB}`
    if [ ! -z "$FQDN" ] ; then
        GetCommandOutput "${VAS} -u host/ -d5 auth -S host/${FQDN}" "vas.auth.fqdn.out"
    fi
    GetCommandOutput "ls -laR /var/opt/quest" "ls.var.laR.out"
    GetCommandOutput "ls -laR /etc/opt/quest" "ls.etc.laR.out"
    GetCommandOutput "ls -laR /opt/quest" "ls.opt.laR.out"
    GetCommandOutput "iptables -L || /usr/sbin/iptables -L" "iptables.L.out"
    GetCommandOutput "fuser /var/opt/quest/vas/vasd/* || /usr/sbin/fuser /var/opt/quest/vas/vasd/* || /bin/fuser /var/opt/quest/vas/vasd/*" "fuser.vasd.out"
    if [ "x${platform}" = "xDarwin10.4" ] ; then
        GetCommandOutput "ps -eAuxxx" "ps.eAuxxx.out"
    else
        GetCommandOutput "ps -ef" "ps.ef.out"
    fi
    GetCommandOutput "${PREFLIGHT} -u host/ `${VAS} info domain 2>&1`" "preflight.out"
    if [ -f /etc/opt/quest/vas/host.keytab ] ; then
        GetCommandOutput "${VAS} -u host/ info acl" "vas.info.acl.out"
        GetCommandOutput "${VAS} -u host/ info adsecurity" "vas.info.adsecurity.out"
        if [ -f /var/opt/quest/vas/.starling -a /opt/quest/libexec/vas/starling ] ; then
            GetCommandOutput "${VAS} starling list" "vas.starling.list"
            GetCommandOutput "${VAS} starling check" "vas.starling.check"
            GetCommandOutput "${VAS} -u host/ starling detect" "vas.starling.detect"
            GetCommandOutput "/opt/quest/libexec/vas/starling -check -debug-stderr" "vas.starling.check"
        fi
    fi
    if [ -f /opt/quest/libexec/vas/scripts/vas_status.sh ] ; then
        GetCommandOutput "/opt/quest/libexec/vas/scripts/vas_status.sh" "vas_status.out"
        cp ${OUT_DIR_CMDS}/vas_status.out $OUT_DIR/vas_status.out
    fi
    for file in .vasd .vasypd .vasproxyd .vasd-site .vasd-lic vasd vasypd vasproxyd vasgpd; do
        if [ -f /opt/quest/sbin/$file ] ; then
            GetCommandOutput "file /opt/quest/sbin/$file" "file.$file.out"
            break
        fi
    done
    for file in .vastool-site .vastool-lic .vastool .vgptool .uptool vastool vgptool uptool; do
        if [ -f /opt/quest/bin/$file ] ; then
            GetCommandOutput "file /opt/quest/bin/$file" "file.$file.out"
            break
        fi
    done
    GetCommandOutput "ls -laZ /var/opt/quest" "ls.var.laZ.out"
    if [ -f /opt/quest/bin/testparm ] ; then
        GetCommandOutput "/opt/quest/bin/testparm -s" "samba.testparm.out"
    fi
    if [ -f /opt/quest/sbin/sshd ] ; then
        GetCommandOutput "/opt/quest/sbin/sshd -t" "sshd.t.out"
    fi
    GetCommandOutput "${VAS} schema list" "vas.schema.list.out"
    GetCommandOutput "${VAS} -u host/ schema detect" "vas.schema.detect.out"
    GetCommandOutput "${VAS} -u host/ search -U DC:// -s base -b '' \"(objectClass=*)\"" "vas.rootDSE.out"

    GetCommandOutput "${VAS} -u host/ info domains" "vas.domains.out"
    DOMAINS="`cat ${OUT_DIR_CMDS}/vas.domains.out`"

    for d in $DOMAINS; do
        DomDN="`echo $d | sed -e 's/\(.*\)/DC=\1/' -e 's/\./,DC=/g'`"
        GetCommandOutput "${VAS} -u host/ search -b \"cn=system,$DomDN\" -s one \"(objectClass=trustedDomain)\" dn msds-supportedencryptiontypes" "vas.domains.trusts.$d.out"
    done
}

GetSystemFiles()
{
    LogMainBasic "*** Gathering system files ***"
    GrabFile /etc/nsswitch.conf
    GrabFile /etc/resolv.conf
    GrabFile /etc/syslog.conf
    GrabFile /etc/rsyslog.conf
    if [ -d /etc/rsyslog.d ] ; then
        mkdir ${OUT_DIR_FILES}/rsyslog.d
        cp -r /etc/rsyslog.d/* ${OUT_DIR_FILES}/rsyslog.d
        LogMainBasic "Storing /etc/rsyslog.d/*"
    fi
    GrabFile /etc/pam.conf
    if [ -d /etc/pam.d ] ; then
        mkdir ${OUT_DIR_FILES}/pam.d
        cp -r /etc/pam.d/* ${OUT_DIR_FILES}/pam.d
        LogMainBasic "Storing /etc/pam.d/*"
    fi
    if [ -d /etc/authselect ] ; then
        mkdir ${OUT_DIR_FILES}/etc_authselect
        cp -r /etc/authselect/* ${OUT_DIR_FILES}/etc_authselect
        LogMainBasic "Storing /etc/authselect/*"
    fi

    if [ -d /usr/share/authselect ] ; then
        mkdir ${OUT_DIR_FILES}/usr_authselect
        cp -r /usr/share/authselect/* ${OUT_DIR_FILES}/usr_authselect
        LogMainBasic "Storing /usr/share/authselect/*"
    fi

    for file in /etc/security/user /etc/security/login.cfg /etc/security/limits /usr/lib/security/methods.cfg /etc/default/passwd /etc/nscd.conf /etc/inittab /etc/krb5.conf /etc/krb5/krb5.conf /etc/irs.conf /etc/sia/matrix.conf /etc/netsvc.conf /etc/svc.conf; do
        GrabFile $file
    done
    for d in /etc /etc/ssh /etc/ssh2 /usr/local/etc /usr/local/etc/ssh /usr/local/etc/ssh2 /opt/ssh/etc /etc/opt/quest/ssh /etc/openssh ; do
        GrabFile $d/sshd_config
        GrabFile $d/ssh_config
    done
    case ${platform} in
        Darwin*)
            GrabFile /etc/authorization
            GrabFile /Library/Preferences/DirectoryService/SearchNodeConfig.plist
            GrabFile /Library/Preferences/OpenDirectory/Configurations/Search.plist
            GrabFile /Library/Preferences/DirectoryService/ContactsNodeConfig.plist
            GrabFile /Library/Preferences/OpenDirectory/Configurations/Contacts.plist
            GrabFile /Library/Preferences/edu.mit.Kerberos
            GrabDirectory "/Library/Managed Preferences" preferences
            ;;
    esac
}

GetVASFiles()
{
    if [ "${HAVE_VAS}" -eq 0 ] ; then
        LogMain "VAS does not appear to be installed, skipping VAS files."
        return
    fi
    LogMainBasic "*** Gathering VAS files ***"
    GrabFile /etc/opt/quest/vas/vas.conf
    GrabFile /etc/opt/quest/vas/users.allow
    GrabFile /etc/opt/quest/vas/users.deny
    GrabFile /etc/opt/quest/vas/user-override
    GrabFile /etc/opt/quest/vas/group-override
    GrabFile /etc/opt/quest/vas/lastjoin
    GrabFile /etc/opt/quest/samba/smb.conf
    GrabFile /etc/opt/quest/dnsupdate.conf
    LogMainBasic "Storing any license and access.d files."
    mkdir ${OUT_DIR_FILES}/.licenses 2>/dev/null
    mkdir ${OUT_DIR_FILES}/access.d 2>/dev/null
    cp -r /etc/opt/quest/vas/.licenses/* ${OUT_DIR_FILES}/.licenses 2>/dev/null
    cp -r /etc/opt/quest/vas/access.d/* ${OUT_DIR_FILES}/access.d 2>/dev/null
    USER_MAP_FILES=`cat /etc/opt/quest/vas/vas.conf | grep user-map-files | grep -v "^#" | awk -F= '{print $2}' | sed 's/;/ /g'`
    if [ ! -z "${USER_MAP_FILES}" ] ; then
        for file in $USER_MAP_FILES ; do
            GrabFile $file
        done
    fi
    GrabFile $MISC_DB
    GrabFile $VAS_IDENT
    GrabFile $VASYPD_DB
    GrabFile /etc/pam_radius_acl.conf
    GrabFile /etc/defender.conf
    GrabFile /etc/opt/quest/vas/autogen.passwd
    GrabFile /etc/opt/quest/vas/autogen.group
    GetCommandOutput "grep :VAS: /etc/passwd" "vas.passwd.merged.out"
    GetCommandOutput "grep :VAS: /etc/group" "vas.group.merged.out"

    case ${platform} in
        Darwin*)
            GrabFile /var/root/Library/Preferences/com.quest.qasrecords.plist
            GrabDirectory /var/opt/quest/vgp/cache/mcxsettings computer-mcxsettings
            GrabDirectory /var/opt/quest/vgp/cache_user/mcxsettings user-mcxsettings
            ;;
    esac
}

GetVGPInfo()
{
    if [ ! -x /opt/quest/bin/vgptool ] ; then
        return
    fi
    LogMainBasic "*** Gathering VGP information ***"
    cp /etc/opt/quest/vgp/vgp.conf ${OUT_DIR_FILES}/ 2>/dev/null
    GetCommandOutput "${VGP} listgpc" "vgp.listgpc.out"
    GetCommandOutput "${VGP} listgpc -l" "vgp.listgpc.l.out"
    GetCommandOutput "${VGP} listgpt" "vgp.listgpt.out"
    GetCommandOutput "${VGP} listgpt -l" "vgp.listgpt.l.out"
# This grabs ALL AD GP's, can take a while, and only applies to a few set of issues.
#    GetCommandOutput "${VGPM} listgpos" "vgp.listgpos.out"
    GetCommandOutput "${VGP} rsop" "vgp.rsop.out"
    GetCommandOutput "${VGP} -d 6 -g 9 apply" "vgp.apply.debug.out"
    GetCommandOutput "${VGP} register" "vgp.register.out"
}

GetVASYPDInfo()
{
    if [ "x${platform}" = "xDarwin10.4" ] ; then
        ps -eA | grep vasyp | grep -v grep | grep vasyp 1>/dev/null 2>&1
    else
        ps -ef | grep vasyp | grep -v grep | grep vasyp 1>/dev/null 2>&1
    fi
    if [ $? -ne 0 ] ; then
        return
    fi
    LogMainBasic "*** Gathering VASYPD information ***"
    GetCommandOutput "ypwhich -m" "ypwhich.m.out"
}

Finish()
{
    echo
    LogMainBasic "*** Script is finished ***"
    echo
    LogMainBasic " Please send in the file: ${OUT_BUNDLE}.tar.gz"
    echo
    tar -cf ${OUT_BUNDLE}.tar -C /tmp ${DATE} 2>/dev/null
    gzip ${OUT_BUNDLE}.tar 2>/dev/null
    rm -r ${OUT_DIR} 2>/dev/null
}

################################################################################
# Main
################################################################################
Prep
GetSystemBasics
GetVASBasics
GetSystemCommands
GetVASCommands
GetSystemFiles
GetVASFiles
GetVGPInfo
GetVASYPDInfo
Finish
