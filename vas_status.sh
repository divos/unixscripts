#!/bin/sh
################################################################################
# Copyright 2022 One Identity LLC. ALL RIGHTS RESERVED.
#
# vas_status.sh
#
# Purpose:      Test the SAS join against AD and local configuration for various
#               issues. Report style format and output, useful for status
#               checks on machines and troubleshooting.
#
# Author(s):    Seth Ellsworth (seth.ellsworth@quest.com)
#
VSVERSION=0.8.3
#
################################################################################
# History:
# 0.8.3
#  * Bug 292701 - Setting HOSTINFO on Linux and Darwin has been refined.
#  * Bug 283832 - Test 608 prints out the offending entries.
#
# 0.8.2
#  * Fix: Some tests failed to print a message in CSV mode.
#  * Fix: Some tests had conflicting severity string and severity code.
#
# 0.8.1
#  * Bug 261831 - Add test 727, check vasypd search-base path.
#
# 0.8.0
#  * Bug 258782 - Modify 199536 to also handle Redhat 6 behavior.
#  * Bug 199536 - Check for selinux installed but not applied to vasd dirs.
#  * Bug 231957 - Report test 403 as INFO instead of WARNING.
#  * Bug 235251 - Ignore new includedir directive for test 112.
#  * Bug 232957 - Change 241/242 to INFO if in workstation mode.
#  * Bug 226240 - Don't check sparc nss files on x64 systems.
#
# 0.7.9
#  * Bug 199844 - Add test 726, check sshd_config for AllowUsers, etc.
#  * Bug 199524 - Add test 631, check /var/opt/quest/vas/vasd's owner.
#  * Bug 806318 - 402 - Ignore if empty, probably a delegated join.
#  * Bug 805666 - 506, fix false failure if starling is not in use.
#  * Bug 793614 - Add support for checking starling.
#  * Bug 800453 - Handle new Ubuntu 19 include for su-l.
#  * Bug 799032 - Add test 243, report if load-*-from-gc is set and not
#    all attributes are in the Global Catalog.
#  * Bug 793588 - Ignore pam_localuser if set to sufficient.
#  * Bug 789479 - Add test 630, /etc/nologin check/INFO.
#  * Bug 777193 - Add test 629, pam_localuser check/INFO.
#  * Bug 787543 - Add test 241/242, check for USN entries.
#  * Bug 804258 - Handle System Integrity Protection changes in macOS 10.15.
#  * Bug 777540 - Add sssd-shadowutils to PAM_MASK.
#  * Increase version for 4.1.6 release.
#  * Bug 776172 - Add new test 627 for KRB5_* variables.
#  * Bug 776060 - Add new test 628 for authselect test.
#
# 0.7.8
#  * Bug 772980 - Add [aix_vas] ext-attrs-window.
#  * Bug 737526 - Test 720, better matching the vasd file.
#  * Bug 754303 - Ignore [plugins] section.
#  * Bug 733917 - Test 608, if password isn't configured return INFO.
#  * Bug 653398 - Test 502, ignore cifs/(short/long) SPN mis-matches.
#  * Bug 752251 - Add test 725, check for shortname in computerFQDN.
#  * Bug 641373 - Test 112, Add latest MIT libdefault settings.
#  * Bug 615449 - Test 719, Fix false positive in a global zone.
#  * Bug 597853 - Add test 724, detect if not in a site.
#  * Bug 727684 - Test 225, return WARNING if no actual Native AC set.
#
# 0.7.7
#  * Bug 722967 - Incease allowed DB size for test 220.
#  * Bug 721148 - Add test 626, Check for 0-byte timeout file.
#  * Bug 720151 - Add test 625, fail on user daemon not existing.
#  * Bug 693043 - Don't complain about Solaris 11.3's gdm-autologin.
#  * Bug 690828 - Add test 624, AIX, check max_logname against db.
#  * Bug 668065 - Check more directory permissions.
#  * Bug 653404 - Handle IA package on PA ( in Aeris container ).
#  * Bug 650913 - Add sanity Test 240 for smb-dialect-range.
#  * Bug 615467 - Test 623, check for 0-byte extensions file.
#  * Bug 618630 - Add pam_radius_auth to ignored pam modules.
#  * Bug 599835 - Test 710, Account for large groups, warn at 2x.
#  * Bug 5043   - Test 720, increase limits.
#  * Bug 480341 - Add multihome-loopback-only to allowed settings.
#  * Bug 480912 - Test 421, handle keytab outside default location.
#  * Bug 458289 - Trim whitespace from names.
#  * Bug 474598 - Add test 240 - INFO if force-smb1 is set.
#  * Added support for FreeBSD
#  * Recognize MIT kerberos default_ccache_name setting.
#  * Fixed grep regex when checking for windows line endings.
#
# 0.7.6
#  * Bug 423599 - Don't complain about 617 if running across midnight.
#  * Bug 424289 - Add test 237 - INFO if use-server-refferals is set.
#  * Bug 433104 - Skip test 603 on AIX.
#  * Bug 434379 - Test 238 - INFO if groupname-attr-name not cn/sam.
#  * Bug 434379 - Test 239 - INFO if username-attr-name not sam.
#  * Increase size check for Solaris OS.
#  * Bug 359055 - Better report when vasd is down.
#  * Bug 308284 - On test 720, wait 4 seconds then re-test.
#  * Bug 367592 - Check for too many permissions on a few SAS files.
#  * Bug 428408 - Handle new runuser pam.d file.
#  * Bug 447868 - Test 604, check system-auth-ac file too.
#  * Bug 447793 - Add [vas_auth] password-expiration-warning-message.
#
# 0.7.5
#  * Bug 397937 - Wait/sleep 4/try again for Test 233 - Flush running.
#
# 0.7.4
#  * Bug 388840 - skip 617 when configured to not use dns.
#  * Bug 393212 - Don't make /dev/nill.
#  * Bug 389870 - Use the right ps options for OSX 10.10.
#
# 0.7.3
#  * Bug 355430 - Update pam check for changes with Ubuntu 13.10
#
# 0.7.2
#  * Bug 347348 - New test 723 - Report on ypserv running.
#  * Export LC_ALL=C to fix locale issue.
#  * New test 722 - Report on . (dot) files.
#  * Bug 339615 - Remove case sensitivity on vas_host_services check.
#  * New test 235 - Look for orphaned nudn foreign keys.
#  * New test 236 - Look for orphaned domain foreign keys.
#  * Bug 340866 - non-gnu sed doesn't recognise \t for tab.
#
# 0.7.1
#  * Remove test 234.
#  * Bug 313299 - Look for OSX 10.9.
#  * Bug 28548 - Test 622, test network users can login via login window or ssh.
#  * If vasd is down skip nslookup test.
#  * Ignore pam_tty_audit.
#
# 0.7.0
#  * Bug 28145 - Test 234, Check for vasd domain cache in sync.
#
# 0.6.9
#  * Bug 28208 - vas_host_services tests - Tests 409-421.
#  * Bug 28209 - Test for cause of bug 28123 - Test 233.
#
# 0.6.8
#  * Bug 28059 - Ignore postlogin for pam checks.
#  * Bug 28017 - Follow users-allow/deny-file setting for AC check.
#  * Bug 27972 - Check for 0-byte cached_attributes.xml - Test 621
#  * Bug 27738 - Check on Mac to see if DirectoryServices is configured for SAS,
#    Active Directory, or Open Directory.
#
# 0.6.7
#  * Bug 27722 - postjoin-srvinfo-flush-interval not recognized.
#  * Bug 27624 - Solaris 11.1 - ignore 0-byte pam.conf.
#  * Bug 27538 - ignore pam_access.
#  * Bug 27405 - ignore vmware-authd entry.
#  * Bug 27398 - Memory test account for netgroups as well.
#  * Bug 27379 - Check group override file permissions.
#  * Bug 27213 - uniq access.d/* file entries, test 721 fix.
#
# 0.6.6
#  * Add in a check for permissions on vgp.conf.
#  * Handle () in samaccountname for ldap queries.
#
# 0.6.5
#  * New option, QUICK. Skips some of the slower/expensive checks.
#    Better for running during production. All tests still recommended
#    to be run occasionally.
#  * Test 708 - Ignore white-space in mapped-user file.
#  * Test 721 - Ignore duplicates.
#
# 0.6.4
#  * Test 232 - Make sure joined domain has valid srvinfo entry.
#  * If a run is Ctrl-C'ed, temp files are now cleaned up.
#  * Up the wtmp+ size check to 250MB.
#  * Turn test 402 to INFO. This failure is not relevent to SAS.
#  * Better handle no computerName in the misc cache.
#  * New test for users.allow/deny, 721, checks users/groups.
#
# 0.6.3
#  * Update nss/pam checks for Solaris 11 and Ubuntu 11.10.
#
# 0.6.2
#  * Add a check for SAS Daemon connected state, in conjuction with daemon
#    changing to track an internal disconnected/connected state.
#
# 0.6.1
#  * Lots of little changes, VAS to SAS, spelling.
#  * Check for needed permissions on override files.
#
# 0.6.0
#  * Add the CSV option, csv output for IMU consumption.
#
# 0.5.9
#  * Changes to support OSX Lion
#  * 24483 - Use VSDEBUG instead of DEBUG to enabled debug.
#
# 0.5.8
#  * Report if in UPM.
#  * 24361 - Ignore vmtoolsd for pam checks.
#
# 0.5.7
#  * Add test 720, number of vasd sockets open.
#  * Detect if SELinux is enabled.
#  * 23734 Fixed an error in test 708, it was overwriting instead of appending
#    when processing multiple mapped user files.
#
# 0.5.6
#  * Check for just 555 on / /etc /etc/opt instead of 755.
#  * Typo in test 113 made it fail, fixed.
#
# 0.5.5
#  * 23434 Don't error on /etc/pam.d/<dir>'s on RedHat.
#  * 23469 Check / and /etc and /etc/opt for proper permissions.
#  * 23435 Added 113, Check vas.conf for Windows-style line endings.
#  * 23441 The error message for HP PA 64-bit having the 32-bit only package
#    installed now says INFO and returns the right file.
#  * 23454 Add host_services is-cross-forest, a 4.0.2 option.
#
# 0.5.4
#  * Added realname-attr.
#  * Skip override tests if 4.0, need to re-work them.
#  * Don't check PAM screensaver config for the presence of pam_vas.
#
# 0.5.3
#  * Added script version to the output on the result line.
#
# 0.5.2
#  * Add test 308, kinit check for needing use-tcp-only
#  * Add tests 226/227/228/229, test override entries for proper files.
#  * Fix test 617 for sites with no servers in them.
#
# 0.5.1
#  * Added 225, check for native AC, but no allow policies.
#
# 0.5.0
#  * Added 618, check for AIX rlogin = false.
#
# 0.4.9
#  * 224 VGP Windows access control not applied - new test method
#  * Fix 708, Handle user-map-files in the format <name>:@<domain>
#  * Fix 112 for vasypd nismap entries.
#
# 0.4.8
#  * Use rss for x86_64, will add more as I find new limit values.
#  * New 4.0 vas.conf settings.
#
# 0.4.7
#  * Handle ls -l potentially having a . after the permissions.
#
# 0.4.6
#  * Call GetHostInfo once instead of twice.
#  * When using VGP security skip 222.
#  * Removed all uses of SQL with <<_EOF.
#  * Expanded 606 to include checking /tmp
#
# 0.4.5
#  * 112 vas.conf settings
#  * 617 dns not slow
#  * 719 not multiple vgptool running
#
# 0.4.4
#  * 616: Check for read-only /var/opt/quest/vas/vasd.
#  * Exclude more pam.d files.
#
# 0.4.3
#  * 220: Check for large ident db.
#  * 221: Check for large misc db.
#  * 222: High level users.allow/deny to access_control sanity.
#  * 223: warn if computer name is 'localhost' or 'unknown'.
#  * 407: Computer doesn't have ADS_UF_PASSWD_NOTREQD
#  * 615: warn on /etc/irs.conf vas if netgroup-mode isn't set NSS.
#  * 718: Check for mu_upd pid file conflict.
#  * Better checking for soft lock situation, less false-positives.
#  * Fix for when /etc/pam.d has a directory under it.
#
# 0.4.2
#  * 614:Check 'last' files /var/{adm,log,run}/[wu]tmp{x,s,} for size.
#
# 0.4.1
#  * SAS 4.0 uses a different socket file.
#
# 0.4.0
#  * Support for OSX '10.6'.
#  * New test: 716 Detects un-reaped (zombie/defunct) children of the parent
#    vasd process.
#  * New test: 717 Test for valid licenses beyond VAS_default.
#
# 0.3.9
#  * New test: 111 Other binaries checked for segfaults.
#
# 0.3.8
#  * Better binary version checking, wasn't working with 3.3.1.100
#             version of vasproxyd ( no Version in its -v output ).
#
# 0.3.7
#  * One AD query instead of multiple, more efficient.
#  * The common-*-ac pask was incorrect, fixed.
#  * Memory checking on OS X is fixed.
#
# 0.3.6
#  * The mapped user check was failing if the file was DOS formatted.
#
# 0.3.5
#  * The mapped user check was reporting on blank lined in the mapped user file.
#    This has been fixed ( they are now properly ignored ).
#
# 0.3.4
#  * New tests:
#     612 AIX: /etc/security/user doesn't have default registry entry
#     613 AIX: methods.cfg is ok
#  * Removed test 214, it is covered by 209/212 now.
#  * Support Redhat PAM module substack.
#
# 0.3.3
#  * PRAGMA results were not parsed correctly, fixed.
#
# 0.3.2
#  * Added a ./vas_status.sh -v option to show version.
#  * If a critical error occured, skip the SAS * enabled tests.
#
# 0.3.1
#  * Got false positives on the new PRAGMA integrity_check due to lack of
#    a timeout ( locked cache errors ). Fixed.
#  * New tests:
#     109 If installed, vgptool -v runs without segfault/errors.
#     110 If installed, vasgpd -v runs without segfault/errors.
#     715 If vgp is installed, vasgpd is running.
#
# 0.3.0
#  * On the dup tests, the temp file wasn't cleaned up. Fixed.
#
# 0.2.9
#  * If on VAS 3.0.3, don't run 713/714. Those rely on newer cache.
#  * Better handle test 711 when using VAS 3.0.3.
#    ( NOTE: VAS 3.0.3 is unsupported. )
#
# 0.2.8
#  * Better path detection for test 609 on HP.
#  * When running test 611, need to call GetHostInfo first.
#
# 0.2.7
#  * Use ls -L better follow links when checking perms of files/did.
#  * Moved mapped user and dup user/group tests to 700, not 700b. So if
#             there is a critical failure, they don't still try to run.
#  * Moved the /tmp and /var full tests to critical so they stop the
#             other tests that might need room in /tmp to report correctly.
#  * Improved tests 209/212 with a PRAGMA command, this will catch
#             ALL vdb file issues as far as sqlite3 is concerned.
#
# 0.2.6
#  * New tests:
#     712 Socket file permissions
#     713 duplicate users
#     714 duplicate groups
#
# 0.2.5
#  * Handle test 703 on both 3.3.2 and 3.5 versions of VAS.
#  * Up the memory threshold for test 710 to 60MB across all platforms.
#
# 0.2.4
#  * Ignore vmware-guestd pam.d errors.
#
# 0.2.3
#  * Added test 711, where all installed binary versions are checked.
#
# 0.2.2
#  * Added help dialog when bad arguments passed in, and ignore nvuauth.
#
# 0.2.1
#  * A little speed increase, store a ccache for host/ instead of getting a TGT
#    for each query.
#
# 0.2.0
#  * Better memory handling for OSX. Increase size for some OSes.
#
# 0.1.9
#  * Make SPN matching case insensitive, samAccountName of the joined
#    machine can be lowercased.
#
# 0.1.8
#  * Modify critical failures to say CRITICAL instead of FAILURE.
#
# 0.1.7
#  * Include error number in output for easier automated parsing.
#
# 0.1.6
#  * Slight re-format for easier customization by individual companies.
#
# 0.1.5
#  * check for running vasd processes now faster and more precise.
#
# 0.1.4
#  * New option: SKIP_PAM_SERVICES, if that variable is set to anything then the
#    pam service specific tests will be skipped. i.e.:
#     SKIP_PAM_SERVICES=1 ./vas_status.sh
#
# 0.1.3
#  * Added /etc/hosts to file permission checks.
#  * Handle links during file permission checks.
#  * Skip nss test failures if using mapped users.
#
# 0.1.2
#  * Added 611, tmp/var space free checks
#  * Added 710, process memory size checks.
#
# 0.1.1
#  * Added 609, NSS Link tests.
#  * Added 610, NSS Link tests.
#
# 0.1.0
#  * Skip tests if bc is not found ( ESX servers ).
#  * New option: REPORT, print out each test as run.
#
# 0.0.9
#  * Use timeout when reading misc settings, stopping false failures.
#  * Ignore any pam.f file with a '.' in its name to ignore saved/backup files.
#    This assumes any real service will not have a '.' in its name.
#  * Better support of Suse/Redhat pam_vas service setups.
#
# 0.0.8
#  * Validate each pam service has pam_vas links.
#
# 0.0.7
#  * Little re-works for easier automated testing.
#
# 0.0.6
#  * Re-work a couple of back-tick/re-direction usages to eliminate AIX shell
#    incompatability. ( 'OUT="`$VAS <<_EOF...' style usage )
#
# 0.0.5
#  * Better OS report for host ( instead of just running uname -a )
#  * Return code added: 5:NO VAS
#  * More portable use of tr.
#
# 0.0.4
#  * Cleanup reporting messages more, for easier parsing.
#  * New return code method: 0:SUCCESS 1:WARNINGS 2:FAILURES 3:CRITICAL
#
# 0.0.3
#  * Better response when VAS is not installed.
#  * Better response when VAS is installed but not joined.
#  * Add VAS version to output.
#  * Add joined domain to output.
#  * Check users.allow/deny for permissions.
#  * Add check for the vasd ipc socket file.
#  * Cleaner response for mapped user issues.
#  * Works now on 8.11 (10.4) OSX.
#  * Tru64 testing is working now.
#  * report messages cleaned up.
#  * Reporting style more consistent.
#
# 0.0.2
#  * Re-work the file permission checks to report cleaner.
#  * /etc/nsswitch.conf missing vas, print FAILURE if not mapped.
#  * Change final output.
#  * Skip SPN/UPN tests if misc cache was missing needed elements.
#  * Still run system tests if critical VAS tests fail.
#
# 0.0.1 (2008_05_11):
#  * Initial offering.
#
################################################################################
#
# The vas_status.sh script tests the following situations:
#
#    001 Nothing serious found ( can still have warnings ).
#
# * vas.conf/vastool/keytab
#    101 vastool exists.
#    102 vastool runs ( no segfault/library issues )
#    103 VAS version ( < 3.0.3.17 or so and fail to run, as we won't have vastool auth )
#    104 vas.conf exists
#    105 vas.conf is valid ( ERROR: Could not allocate VAS context, err = 2 )
#    106 Check for missing default_realm setting.
#    107 Keytab file exists
#    108 keytab is valid ( not an empty/corrupted file ( krb5_kt_start_seq_get ) )
#    109 vgptool runs ( if installed, no segfault/library issues )
#    110 vasgpd runs ( if installed, no segfault/library issues )
#    111 Other binaries checked ( if installed, no segfault/library issues )
#    112 vas.conf settings
#    113 vas.conf Windows-style line endings
#
# * Local DB
#    201 misc cache exists.
#    202 ident cache exists.
#    203 misc cache is not locked.
#    204 misc cache is not soft locked.
#    205 ident cache is not locked.
#    206 ident cache is not soft locked.
#    207 Misc cache is a DB file.
#    208 Misc cache is not corrupt.
#    209 Misc cache is not otherwise broken.
#    210 Ident cache is a DB file.
#    211 Ident cache is not corrupt.
#    212 Ident cache is not otherwise broken.
#    213 All needed tables exist. ( No missing tables, careful here, given version differences ).
#    (REMOVED)214 No tables are corrupt.
#    215 machine has found a site, or has an override site set.
#    216 Misc table has defaultRealm
#    217 Misc table has computerfqdn
#    218 Misc table has computername
#    219 Misc table has forestRoot
#    220 Check for large ident db.
#    221 Check for large misc db.
#    222 High level users.allow/deny to access_control sanity.
#    223 warn if computer name is 'localhost' or 'unknown'.
#    224 VGP Windows access control not applied
#    225 VGP Windows access control not applied ( deny only )
#    226 User override consistency. ( No dummy entries. )
#    227 User override by group consistency. ( No dummy entries. )
#    228 User override upn didn't change.
#    229 Group override consistency. ( No dummy entries. )
#    230 Check UPM
#    231 Check vasd connected state
#    232 Default domain has srvinfo entry
#    233 No *FlushRunningSince entry in misc
#    (REMOVED)234 Check domains in cache vs vasd
#    235 Look for orphaned nudn foreign keys
#    236 Look for orphaned domain foreign keys
#    237 Look for use-server-referrals
#    238 Look for schema/groupname-attr-name not cn/sam/altsec
#    239 Look for schema/username-attr-name not sam
#    240 Sanity check for smb-dialect-range
#    241 Sanity check user USN entries.
#    242 Sanity check group USN entries.
#    243 Check for attributes in GC if load-*-from-gc is set.
#
# * kinit results
#    301 Machine can talk to AD ( KDC_UNREACH )
#    302 Object exists in AD. ( client unknown )
#    303 Machine timesync. ( TIME_SKEW )
#    304 The host.keytab knows the right password. ( preauth failed ).
#    305 The host/ account is usable ( CREDENTIALS REVOKED )
#    306 DES is set, but no entries ( KRB5KDC_ERR_PREAUTH_REQUIRED )
#    307 ( Misc kinit error, not one of the above known ones ).
#    308 Kinit required TCP Failover
#
# * Computer account checks.
#    401 Computer can read AD object.
#    402 Computer account has valid UPN.
#    403 Computer account userAccountControl has ADS_UF_DONT_EXPIRE_PASSWD # INFO, might be djoin'ed.
#    404 Computer account userAccountControl has VAS_UF_WORKSTATION_TRUST_ACCOUNT
#    405 Computer account userAccountControl doesn't have ADS_UF_USE_DES_KEY_ONLY
#    406 Computer account userAccountControl doesn't have ADS_UF_DONT_REQUIRE_PREAUTH
#    407 Computer account userAccountControl doesn't have ADS_UF_PASSWD_NOTREQD
#
# * vas_host_services tests
#    409 no duplicate stanzas
#    410 krb5name is set
#    411 keytab exists
#    412 keytab has entry for krb5name
#    413 not joined domain
#    414 SAS can find DC to communicate with
#    415 service exists in AD
#    416 timesync
#    417 right password
#    418 service usable
#    419 DES is set, but no entries ( KRB5KDC_ERR_PREAUTH_REQUIRED )
#    420 ( Misc kinit error, not one of the above known ones )
#    421 If use-for-auth, that auth as a service princ works
#
# * vastool auth/spn and starling.
#    501 Computer account has valid SPNs.
#    502 host.keytab containes matching entries for each SPN in AD.
#    503 SPNs in AD match each entry in host.keytab.
#    504 auth -S host/$FQDN returns KRB5KDC_ERR_S_PRINCIPAL_UNKNOWN, duplicate.
#    505 auth -S host/$FQDN fails.
#    506 Check starling setup.
#
# * Final local stuff.
#    601 File/directory permissions. Not enough.
#    602 File/directory permissions. Too much.
#    603 /etc/nsswitch.conf contains vas3. ( check for map entries ).
#    604 Relevent PAM configuraiton file contains at least one pam_vas3 line.
#    605 AIX: IRS files have SAS configured.
#    606 System file permissions. Not enough.
#    607 System file permissions. Too much.
#    608 Each pam.conf section has pam_vas enabled.
#    609 nss links exist.
#    610 pam links exist.
#    611 var and tmp directories are not full
#    612 AIX: /etc/security/user doesn't have default registry entry
#    613 AIX: methods.cfg is ok
#    614 'last' file size.
#    615 warn on /etc/irs.conf vas if netgroup-mode isn't set NSS.
#    616 Check for read-only /var/opt/quest/vas/vasd/
#    617 dns not slow
#    618 AIX: default rlogin = false isn't set.
#    619 OSX: SAS is configured in DirectoryServices.
#    620 OSX: Active Directory and Open Directory are NOT configured.
#    621 cached_attributes.xml not 0-bytes.
#    622 OSX: Network users can login via login window or ssh.
#    623 Test for existence of extensions file for VGP.
#    624 AIX: Check max_logname vs cached name lengths.
#    625 User daemon exists.
#    626 vasipc_timeout not 0-bytes.
#    627 Any KRB5_* env variables.
#    628 authselect check.
#    629 pam_localuser check.
#    630 /etc/nologin check.
#    631 Make sure daemon owns /var/opt/quest/vas/vasd.
#
# * And whatever else.
#    701 Valid license 1 ( expired )
#    702 Valid license 2 ( no license )
#    703 Valid license 3 ( no directory )
#    (not run)704 Valid license 4 ( invalid file )
#    705 vasd running at all
#    706 vasd running one process
#    707 vasd responding
#    708 Mapped user consistency
#    709 vasd ipc socket file missing
#    710 process memory size
#    711 All binaries are same version
#    712 Socket file permissions
#    713 duplicate users
#    714 duplicate groups
#    715 If vgp is installed, vasgpd is running.
#    716 Defunct children detection
#    717 Test for valid licenses beyond VAS_default.
#    718 mu_upd pid file exists and conflicts with process.
#    719 not multiple vgptool running
#    720 number of vasd sockets ( SAS 4.x )
#    721 users.allow/deny consistency
#    722 Report on . (dot) files in place.
#    723 Report on ypserv running.
#    724 Detect if not in a site.
#    725 Check for shortname in computerFQDN.
#    726 Check for AllowUser/etc in sshd_config.
#    727 Check vasypd search-base path.
#
################################################################################

if [ -z "$VSDEBUG" ] ; then
    DEBUG=false
else
    DEBUG=true
fi

$DEBUG && set -x

ctrlc ()
{
    $SET_CCNAME && $VAS kdestroy 2>/dev/null 1>&2
    rm -rf $fOUT $DBCMD /tmp/_vas_*.$$

}
trap ctrlc INT


# Shhh... look away. This is a testing nomenclature, when called
# with the right option in addition to normal printout, print out
# an arbitraty but unique number, so a testing script can make sure
# the right response was given for a particular situation.

# Now the number is in the normal output too, but testing is already written
# around this usage, so intentionally keeping it.
if [ "x$1" = "xNUMBER" -o "x$2" = "xNUMBER" -o "x$3" = "xNUMBER" ] ; then
    NUM=true
else
    NUM=false
fi

if [ "x$1" = "xREPORT" -o "x$2" = "xREPORT" -o "x$3" = "REPORT" ] ; then
    REPORT=true
else
    REPORT=false
fi

if [ "x$1" = "xCSV" -o "x$2" = "xCSV" -o "x$3" = "xCSV" ] ; then
    CSV=true
else
    CSV=false
fi

if [ "x$1" = "xQUICK" -o "x$2" = "xQUICK" -o "x$3" = "xQUICK" ] ; then
    QUICK=true
else
    QUICK=false
fi

if [ ! -z "$1" ] ; then
    case "$1" in
        CSV)
            ;;
        REPORT)
            ;;
        QUICK)
            ;;
        NUMBER)
            ;;
        -v)
            echo "vas_status: Version $VSVERSION"
            exit 0
            ;;
        *)
            echo "usage: ./vas_status.sh [REPORT | -v]"
            echo ""
            echo "REPORT:    Print success as each test passes"
            echo "QUICK:     Skip slower tests"
            echo "-v:        Print version and exit"
            exit 1
            ;;
    esac
fi

VAS=/opt/quest/bin/vastool
VGP=/opt/quest/bin/vgptool
VGPD=/opt/quest/sbin/vasgpd
SQL=/opt/quest/libexec/vas/sqlite3
SQL3="$SQL -noheader -list -separator '|'"
VASIPC=/var/opt/quest/vas/vasd/.vasd_ipc_sock
ASDCOM=/opt/quest/libexec/vas/sugi/asdcom
if [ -f $ASDCOM ] ; then
    VASIPC=/var/opt/quest/vas/vasd/.vasd40_ipc_sock
fi
IDENTDB=/var/opt/quest/vas/vasd/vas_ident.vdb
MISCDB=/var/opt/quest/vas/vasd/vas_misc.vdb
VASCONF=/etc/opt/quest/vas/vas.conf
VGPCONF=/etc/opt/quest/vgp/vgp.conf
KEYTAB=/etc/opt/quest/vas/host.keytab
UALLOW=/etc/opt/quest/vas/users.allow
UDENY=/etc/opt/quest/vas/users.deny
TWOFAINFO=/var/opt/quest/vas/.starling
TWOFABIN=/opt/quest/libexec/vas/starling
TWOFAFILE=/etc/opt/quest/vas/users.starling
FAILURE=false
WARNING=false
CRITICAL_FAILURE=false
ADFAILURE=false
STARTTIME=
MappedFile=
fOUT=/tmp/_tmp.vs.$$
DBCMD=/tmp/_tmp.db.$$
CLEANUP_FILES="$fOUT $DBCMD"
HAVE_MISC=1
HAVE_IDENT=1
PLATFORM=UNKNOWN
HOSTINFO=UNKNOWN
PAM_MASK="screensaver|\\.|-auth-ac|common-.*-.c|runuser|postlogin|keycat|nvuauth|fingerprint|init|smartcard|vmware-authd|vmware-guestd|vmtoolsd|pam-ssh-|authorization|sssd-shadowutils"
EXIT_VALUE=3
VASVERMAJOR=
VASVERMINOR=
VASVERREVISION=
VASVERBUILD=
CATTRS=
ACGOOD=true
SET_CCNAME=false
TVASVERSION=

UPPER=ABCDEFGHIJKLMNOPQRSTUVWXYZ
LOWER=abcdefghijklmnopqrstuvwxyz

KRB5_KTNAME_SAVE="KRB5_KTNAME=$KRB5_KTNAME"
KRB5_CONFIG_SAVE="KRB5_CONFIG=$KRB5_CONFIG"
unset KRB5_KTNAME KRB5_CONFIG

LS=ls
if [ -f /bin/ls ] ; then
LS=/bin/ls
elif [ -f /usr/bin/ls ] ; then
LS=/usr/bin/ls
fi

PS=ps
if [ -f /bin/ps ] ; then
PS=/bin/ps
elif [ -f /usr/bin/ps ] ; then
PS=/usr/bin/ps
fi

PATH=/usr/xpg4/bin:$PATH:/usr/sbin
export PATH
LC_ALL=C
export LC_ALL
unset GREP_OPTIONS

check_vas_conf ()
{
    TFILE1=/tmp/_vas_conf_test.1.$$
    TFILE2=/tmp/_vas_conf_test.2.$$
    case $PLATFORM in
		AIX*)
    		awk '{ if ($0 ~ /^[ 	]*nismaps[ 	]*=[ 	]*\{[ 	]*$/) {in_nismaps=1}; if (in_nismaps==1 && $0 ~ /^[ 	]*}[ 	]*$/) {in_nismaps=0} else if (in_nismaps==0) {print $0}}' < $VASCONF | sed -e 's/#.*$//' -e '/^[ 	]*$/d' -e '/\=[ 	]*{[ 	]*$/d' -e '/}[ 	]*$/d' -e '/=.*:.*\[.*]/d' -e '/^includedir /d' | awk '{ if ($0 ~ /^\[/) {header=$1} else { print header, $1}}' | cut -d= -f1 | grep -v -e '^\[appdefaults\]' -e '^\[capaths\]' -e '^\[deleted_check\]' -e '^\[plugins\]' -e '^\[domain_realm\]' -e '^\[logging\]' -e '^\[realms\]' | sort | uniq > $TFILE1
			;;
		*)
    		awk '{ if ($0 ~ /^[ 	]*nismaps[ 	]*=[ 	]*\{[ 	]*$/) {in_nismaps=1}; if (in_nismaps==1 && $0 ~ /^[ 	]*}[ 	]*$/) {in_nismaps=0} else if (in_nismaps==0) {print $0}}' < $VASCONF | sed -e 's/#.*$//' -e '/^[ 	]*$/d' -e '/\=[ 	]*{[ 	]*$/d' -e '/}[ 	]*$/d' -e '/=.*:.*\[.*]/d' -e '/^includedir /d' | awk '{ if ($0 ~ /^\[/) {header=$1} else { print header, $1}}' | cut -d= -f1 | egrep -v '\[(appdefaults|capaths|deleted_check|domain_realm|logging|plugins|realms)\]' | sort | uniq > $TFILE1
			;;
	esac

sort > $TFILE2 <<_EOF
[aix_vas] auth-debug
[aix_vas] auth-helper-timeout
[aix_vas] check-gid-conflicts
[aix_vas] create-homedir
[aix_vas] disable-password-expiration-warning
[aix_vas] ext-attrs-window
[aix_vas] include-local-group-memberships
[aix_vas] mapped-user-no-file-changes
[aix_vas] merge-user
[aix_vas] nss-debug
[aix_vas] pw-expiration-warning-window
[aix_vas] trust-ftpd
[aix_vas] trust-sshd
[aix_vas] use-dynamic-buffers
[libdefaults] accept_null_addresses
[libdefaults] allow_weak_crypto
[libdefaults] ap_req_checksum_type
[libdefaults] canonicalize
[libdefaults] capath
[libdefaults] ccache_type
[libdefaults] check-rd-req-server
[libdefaults] clockskew
[libdefaults] computer_name_override
[libdefaults] date_format
[libdefaults] default_cc_name
[libdefaults] default_ccache_name
[libdefaults] default_client_keytab_name
[libdefaults] default_etypes
[libdefaults] default_etypes_des
[libdefaults] default_keytab_modify_name
[libdefaults] default_keytab_name
[libdefaults] default_realm
[libdefaults] default_tgs_enctypes
[libdefaults] default_tkt_enctypes
[libdefaults] dns_canonicalize_hostname
[libdefaults] dns_fallback
[libdefaults] dns_lookup_kdc
[libdefaults] dns_lookup_realm
[libdefaults] dns_lookup_realm_labels
[libdefaults] dns_proxy
[libdefaults] dns_uri_lookup
[libdefaults] egd_socket
[libdefaults] encrypt
[libdefaults] err_fmt
[libdefaults] extra_addresses
[libdefaults] fcache_version
[libdefaults] fcc-mit-ticketflags
[libdefaults] forward
[libdefaults] forwardable
[libdefaults] http_proxy
[libdefaults] ignore_acceptor_hostname
[libdefaults] ignore_addresses
[libdefaults] k5login_authoritative
[libdefaults] k5login_directory
[libdefaults] kcm_mach_service
[libdefaults] kcm_socket
[libdefaults] kdc_default_options
[libdefaults] kdc_req_checksum_type
[libdefaults] kdc_timeout
[libdefaults] kdc_timesync
[libdefaults] log_utc
[libdefaults] maxretries
[libdefaults] max_retries
[libdefaults] noaddresses
[libdefaults] no-addresses
[libdefaults] permitted_enctypes
[libdefaults] plugin_base_dir
[libdefaults] preferred_preauth_types
[libdefaults] proxiable
[libdefaults] rdns
[libdefaults] realm_try_domains
[libdefaults] renewable
[libdefaults] renew_lifetime
[libdefaults] safe_checksum_type
[libdefaults] scan_interfaces
[libdefaults] srv_lookup
[libdefaults] srv_try_txt
[libdefaults] ticket_lifetime
[libdefaults] time_format
[libdefaults] transited_realms_reject
[libdefaults] udp_preference_limit
[libdefaults] v4_instance_resolve
[libdefaults] v4_name_convert
[libdefaults] verify_ap_req_nofail
[libvas] add-netbios-addr
[libvas] auth-helper-timeout
[libvas] base64-encoded-attrs
[libvas] enable-gssapi-acceptor-authz
[libvas] enable-smb3-encryption
[libvas] force-ipv
[libvas] ldap-bind-timeout
[libvas] ldap-gsssasl-security-layers
[libvas] mit-realm
[libvas] mscldap-timeout
[libvas] server-unreachable-retry-max
[libvas] service-pw-chars
[libvas] service-pw-length
[libvas] site-only-servers
[libvas] site-name-override
[libvas] smb-dialect-range
[libvas] smb3-prefer-gcm
[libvas] use-dns-srv
[libvas] use-server-referrals
[libvas] use-srvinfo-cache
[libvas] use-tcp-only
[libvas] vascache-ipc-timeout
[nss_vas] access-denied-shell
[nss_vas] check-host-access
[nss_vas] check-uid-conflicts
[nss_vas] cross-domain-user-full-upn
[nss_vas] disabled-user-pwhash
[nss_vas] enable-debug
[nss_vas] expired-account-pwhash
[nss_vas] getent-use-memory-cache
[nss_vas] group-append-domain
[nss_vas] groupsbymember-process-local-duplicates
[nss_vas] groups-for-user-update
[nss_vas] groups-for-user-update-all-sids
[nss_vas] groups-skip-wpg
[nss_vas] group-update-mode
[nss_vas] grset-group-update-mode
[nss_vas] include-implicit-members
[nss_vas] locked-out-pwhash
[nss_vas] logon-hours-restricted-pwhash
[nss_vas] lowercase-homedirs
[nss_vas] lowercase-names
[nss_vas] provide-password-hash
[nss_vas] provide-shadow-hash
[nss_vas] resolve-gid
[nss_vas] resolve-uid
[nss_vas] root-update-mode
[nss_vas] unix-disabled-pwhash
[nss_vas] user-full-upn
[nss_vas] user-hide-if-denied
[nss_vas] virtual-primary-groups
[nss_vas] virtual-primary-groups-set-gid
[pam_vas] auth-fail-script
[pam_vas] ignore-script
[pam_vas] log-all-auths
[pam_vas] log-session-info
[pam_vas] post-auth-script
[pam_vas] pre-auth-script
[pam_vas] prompt-ad-lockout-msg
[pam_vas] prompt-local-pw
[pam_vas] prompt-vas-ad-disauth-pwcache
[pam_vas] prompt-vas-ad-disauth-ticket
[pam_vas] prompt-vas-ad-pw
[pam_vas] prompt-vassc-pin
[pam_vas] prompt-vassc-user
[pam_vas] pw-expiration-warning-window
[pam_vas] service-access-dir
[pam_vas] show-lockout-message
[pam_vas] skip-local-check
[pkcs11] pkcs11-lib
[pkcs11] pkcs11-slot
[pkcs11] timeout
[pkinit] auto-crl-download
[pkinit] auto-crl-download-bind-type
[pkinit] auto-crl-removal
[pkinit] bootstrap-trusted-certs
[pkinit] trusted-certs-update-interval
[siad_vas] check-gid-conflicts
[siad_vas] create-homedir
[siad_vas] enable-debug
[siad_vas] estab-in-authent
[siad_vas] pw-expiration-warning-window
[starling] prompt
[starling] choices
[starling] debug-level
[starling] fail-strict
[starling] mobile-attr-name
[starling] email-attr-name
[vas_auth] allow-disabled-shell
[vas_auth] allow-disconnected-auth
[vas_auth] allowed-unlinked-login-services
[vas_auth] bad-password-max
[vas_auth] checkaccess-use-implicit
[vas_auth] disable-implicit-group-membership
[vas_auth] enable-nonroot-disconnected-cache
[vas_auth] enable-self-enrollment
[vas_auth] enrollment-failure-allowed-message
[vas_auth] enrollment-failure-disallowed-message
[vas_auth] enrollment-required-for-login
[vas_auth] enrollment-success-message
[vas_auth] expand-ac-groups
[vas_auth] force-ac-group-update-on-login
[vas_auth] force-cache-pac-groups
[vas_auth] homedir-creation-script
[vas_auth] homedir-perms
[vas_auth] map-from-nss
[vas_auth] mapped-root-user
[vas_auth] mapped-user-directory-auth-optional
[vas_auth] mapped-users-skip-access-check
[vas_auth] max-wake-from-sleep-wait
[vas_auth] no-cred-cleanup
[vas_auth] non-interactive-screensavers
[vas_auth] nonroot-disconnected-cache-dir
[vas_auth] nonvas-user-allowed-shells
[vas_auth] nonvas-user-disallowed-uids
[vas_auth] password-cache-age
[vas_auth] password-change-message
[vas_auth] password-expiration-warning-message
[vas_auth] perm-disconnected-users
[vas_auth] self-enrollment-ad-password-prompt
[vas_auth] self-enrollment-ad-username-prompt
[vas_auth] self-enrollment-interface-binary
[vas_auth] self-enrollment-uid-ranges
[vas_auth] send-new-group-upd-request
[vas_auth] skip-pac-processing-service-list
[vas_auth] ssh-no-extra-prompt
[vas_auth] strict-account-mode
[vas_auth] uid-check-limit
[vas_auth] use-log-on-to
[vas_auth] user-map-files
[vas_auth] users-allow-file
[vas_auth] users-deny-file
[vasd] allow-upn-login
[vasd] alt-auth-realms
[vasd] auto-ticket-renew-interval
[vasd] autogen-id-generation-algorithm
[vasd] autogen-posix-attrs
[vasd] autogen-posix-default-shell
[vasd] autogen-posix-homedir-base
[vasd] cache-unix-password
[vasd] configuration-refresh-interval
[vasd] cross-domain-user-groups-member-search
[vasd] cross-forest-domains
[vasd] debug-level
[vasd] delusercheck-interval
[vasd] delusercheck-script
[vasd] deluser-check-timelimit
[vasd] gecos-attr-name
[vasd] gid-number-attr-name
[vasd] group-member-attr-name
[vasd] groupname-attr-name
[vasd] group-override-dir
[vasd] group-override-file
[vasd] group-search-path
[vasd] home-dir-attr-name
[vasd] ipc-queue-size
[vasd] lazy-cache-update-interval
[vasd] ld-close-age
[vasd] ldap-timeout
[vasd] load-groups-from-gc
[vasd] load-groups-ignore-path
[vasd] load-users-from-gc
[vasd] load-users-ignore-path
[vasd] login-shell-attr-name
[vasd] memberof-attr-name
[vasd] negative-cache-lifetime
[vasd] netgroup-mode
[vasd] netgroup-search-base
[vasd] ns-update-interval
[vasd] override-check-interval
[vasd] password-change-interval
[vasd] password-change-script
[vasd] password-change-script-timelimit
[vasd] password-policy-sync-interval
[vasd] perm-disconnected-update
[vasd] postjoin-srvinfo-flush-interval
[vasd] preload-nested-memberships
[vasd] realmscache-sync-interval
[vasd] realname-attr
[vasd] renewal-patterns
[vasd] require-global-config
[vasd] site-only-usn
[vasd] timesync-interval
[vasd] uid-number-attr-name
[vasd] unix-password-attr-name
[vasd] unresolve-cache-timelimit
[vasd] update-interval
[vasd] upm-allow-unlinked-gpp
[vasd] upm-allow-unlinked-upp
[vasd] upm-computerou-attr
[vasd] upm-ignore-unlinked-upp
[vasd] upm-search-path
[vasd] upm-username-use-cn
[vasd] username-attr-name
[vasd] user-override-by-group-apply-all
[vasd] user-override-dir
[vasd] user-override-file
[vasd] user-override-name-allow-original
[vasd] user-search-path
[vasd] workstation-mode
[vasd] workstation-mode-group-do-member
[vasd] workstation-mode-groups-skip-update
[vasd] workstation-mode-users-preload
[vasd] ws-resolve-uid
[vas_host_services] keytab
[vas_host_services] krb5name
[vas_host_services] is-cross-forest
[vas_host_services] password-change-interval
[vas_host_services] password-change-script
[vas_host_services] password-change-script-timelimit
[vas_host_services] use-for-auth
[vas_macos] admin-users
[vas_macos] authentication-hint
[vas_macos] dslog-components
[vas_macos] dslog-libvas
[vas_macos] dslog-mode
[vas_macos] dslog-requests
[vas_macos] dslog-traces
[vas_macos] filevault-users
[vas_macos] map-homedir-to-Users
[vas_macos] mapped-user-displayname-format
[vas_macos] nethome
[vas_macos] nethome-local-mount-dir
[vas_macos] nethome-mount-protocol
[vas_macos] require-smartcard
[vasproxyd] allow-deny-name
[vasproxyd] bind-uri
[vasproxyd] connection-timeout
[vasproxyd] daemon-user
[vasproxyd] debug-level
[vasproxyd] dump-io
[vasproxyd] enable-anonymous
[vasproxyd] enable-disconnected
[vasproxyd] largest-ldap-message
[vasproxyd] listen-addrs
[vasproxyd] post-auth-script
[vasproxyd] proxy-to-gc
[vasproxyd] search-cache-entry-max-size
[vasproxyd] search-cache-negative-entry-ttl
[vasproxyd] search-cache-ttl
[vasproxyd] service-principal
[vasypd] client-addrs
[vasypd] debug-level
[vasypd] disable-netgroup-byhost
[vasypd] disable-netgroup-byuser
[vasypd] domainname-override
[vasypd] dup-auto-maps
[vasypd] full-update-interval
[vasypd] load-nisnetgroups
[vasypd] multihome-loopback-only
[vasypd] page-size
[vasypd] provide-password-hash
[vasypd] rfc2307-nismap-child-only
[vasypd] script-user
[vasypd] search-base
[vasypd] split-groups
[vasypd] update-interval
[vasypd] update-process
[vasypd] use-nisobjects-for-std-maps
_EOF
    OUTPUT="`comm -23 $TFILE1 $TFILE2`"
    if [ -n "$OUTPUT" ] ; then
        printf "%s\n" "$OUTPUT" | while read line; do
            $CSV || printf "WARNING: Unrecognized setting: $line\n"
            $CSV && printf "\"STATUS\",112,\"vas.conf settings\",1,\"Unrecognized vas.conf setting: $line\"\n"
        done
        $NUM && printf "NUMBER:112\n"
        $CSV || echo "WARNING: 112 vas.conf settings"
        WARNING=true
    else
        R "112 vas.conf settings"
    fi
    rm $TFILE1 $TFILE2
}

pam_conf ()
{
# Use this for pam.conf version:
    if [ -f /etc/pam.conf ] ; then
        vTMPFILE1=/tmp/_vas_pc_test.1.$$
        vTMPFILE2=/tmp/_vas_pc_test.2.$$
        cat /etc/pam.conf | sed -e 's/#.*//' -e '/^[ 	]*$/d' | grep -v pam_seos | grep -v pam_prohibit | grep -v gdm-autologin | awk '{print $1 "><" $2}' | sort | uniq > $vTMPFILE1
        cat /etc/pam.conf | sed -e 's/#.*//' -e '/^[ 	]*$/d' | grep pam_vas | awk '{print $1 "><" $2}' | sort | uniq > $vTMPFILE2
        PCFAILURES="`comm -23 $vTMPFILE1 $vTMPFILE2 | grep -v nvuauth`"
        rm -f $vTMPFILE1 $vTMPFILE2
        if [ ! -z "$PCFAILURES" ] ; then
            for service in $PCFAILURES ; do
                $CSV || printf "FAILURE: 608 Pam <$service> not configured for SAS.\n"
                $CSV && printf "\"STATUS\",608,\"pam check\",2,\"Pam service <$service> not configured for SAS\"\n"
            done
            FAILURE=true
            return 1
        fi
    fi
}

pam_redhat_modules ()
{
# $1 file
    F="~`sed 's/#.*//' < /etc/pam.d/$1 | tr '\n' '~'`~"
    for m in account auth password session ; do
        # Has service=system-auth, pam_vas, pam_permit, or pam_rhosts.
        # Any service that could return success and is ok with SAS.
        echo "$F" | egrep "~$m[^~]*(service=system-auth|include|substack|pam_vas|pam_permit|pam_rhosts|pam_env)" >/dev/null
#        sed 's/#.*//' < /etc/pam.d/$1 | egrep "^$m.*service=system-auth|^$m.*pam_vas|^$m.*pam_permit|^$m.*pam_rhosts" >/dev/null
        if [ $? -ne 0 ] ; then
            # Silly exception cases. Not certain why this module needs pam_unix for session.
            if [ "$1" = "runuser" -a "$m" = "session" ] ; then
                return
            fi
            # Any service that could return failure explicitly or does nothing, regardless of SAS.
            echo "$F" | sed -e "s/~$m[^~]*pam_warn[^~]*~/~/" -e "s/~$m[^~]*pam_access[^~]*~/~/" -e "s/~$m[^~]*pam_deny[^~]*~/~/" -e "s/~$m[^~]*pam_limits[^~]*~/~/" -e "s/~$m[^~]*pam_console[^~]*~/~/" -e "s/~$m[^~]*pam_loginuid[^~]*~/~/" -e "s/~$m[^~]*pam_rootok[^~]*~/~/" -e "s/~$m[^~]*pam_keyinit[^~]*~/~/" -e "s/~$m[^~]*pam_namespace[^~]*~/~/" -e "s/~$m[^~]*pam_xauth[^~]*~/~/" -e "s/~$m[^~]*pam_timestamp[^~]*~/~/" -e "s/~$m[^~]*pam_tty_audit[^~]*~/~/" -e "s/~$m[^~]*pam_radius_auth[^~]*~/~/" | grep "~$m[^~]*~" >/dev/null
            if [ $? -eq 0 ] ; then
                if [ "$m" = "password" ] ; then
                    # Bug 733917 - Password not configured could be intentional, don't error on it.
                    $CSV || printf "INFO: 608 Pam <$1><$m> not configured for SAS.\n"
                else
                    $CSV || printf "FAILURE: 608 Pam <$1><$m> not configured for SAS.\n"
                    $CSV && printf "\"STATUS\",608,\"pam check\",2,\"Pam service <$1><$m> not configured for SAS\"\n"
                    PAM_FAILED=1
                fi
            fi
        fi
    done
}

pam_redhat()
{
# Use this for /etc/pam.d/system-auth setup.
    PAM_FAILED=0
    CWD="`pwd`"
    cd /etc/pam.d
    for file in `$LS | egrep -v "$PAM_MASK"` ; do
        # ignore directories
        if [ ! -d $file ] ; then
            pam_redhat_modules $file
        fi
    done
    cd "$CWD"
    return $PAM_FAILED
}

pam_suse_modules ()
{
    $DEBUG && set -x
# $1 file
    for m in account auth password session ; do
        # Has include common-<module>
        sed 's/#.*//' < /etc/pam.d/$1 | egrep "^($m|@).*(include|substack).*(common-$m|system|[	 ]su).*" >/dev/null
        if [ $? -ne 0 ] ; then
            sed 's/#.*//' < /etc/pam.d/$1 | egrep "^$m.*pam_(permit|freerdp|rootok|vas|rhosts).*" >/dev/null
            if [ $? -ne 0 ] ; then
                # The idea is to catch any module that has a line other then warn/deny, meaning
                # it is still possible to get in without SAS.
                OFFENDING_ENTRIES=`sed 's/#.*//' < /etc/pam.d/$1 | grep "^$m" | grep -v pam_access | grep -v pam_allow | grep -v pam_user_policy | grep -v pam_unix_cred | grep -v pam_warn | grep -v pam_deny | grep "[a-zA-Z]"`
                if [ $? -eq 0 ] ; then
                    if [ "$m" = "password" ] ; then
                        # Bug 733917 - Password not configured could be intentional, don't error on it.
                       $CSV || printf "INFO: 608 Pam <$1><$m> not configured for SAS.\n"
                   else
                        $CSV || printf "FAILURE: 608 Pam <$1><$m> not configured for SAS.\nOffending entries in /etc/pam.d/$1:\n$OFFENDING_ENTRIES\n"
                        OFFENDING_ENTRIES=`echo "$OFFENDING_ENTRIES" | tr -s '\n' ' '`
                        $CSV && printf "\"STATUS\",608,\"pam check\",2,\"Pam service <$1><$m> not configured for SAS. Offending entries in /etc/pam.d/$1: $OFFENDING_ENTRIES\"\n"
                        PAM_FAILED=1
                   fi
                fi
            fi
        fi
    done
}

pam_suse()
{
    $DEBUG && set -x
# Use this for /etc/pam.d/common-* setup.
    PAM_FAILED=0
    CWD="`pwd`"
    cd /etc/pam.d
    for file in `$LS | egrep -v "$PAM_MASK"` ; do
        # ignore directories
        if [ ! -d $file ] ; then
            pam_suse_modules $file
        fi
    done
    cd "$CWD"
    return $PAM_FAILED
}

# don't use this for now, but keeping in case we go this route.
# Run time 1.2s went to 1.8 with pam_suse, this was an attempt
# to run faster. As-is it runs in 1.6, and doesn't handle the 'other'
# case. Its not worth it to me to continue down this path.
pam_suse2()
{
# Use this for /etc/pam.d/common-* setup.
    CWD="`pwd`"
    vTMPFILE1=/tmp/_vas_pc_test.1.$$
    vTMPFILE2=/tmp/_vas_pc_test.2.$$
    rm -rf $vTMPFILE1
    cd /etc/pam.d
    for file in * ; do
        sed -e 's/#.*//' -e 's/^[ 	]*$//' -e '/^$/d' < $file | awk "{printf \"$file~\" \$1 \"\\n\"}" | sort | uniq >> $vTMPFILE1
        sed -e 's/#.*//' -e 's/^[ 	]*$//' -e '/^$/d' < $file | egrep "pam_vas|include|pam_permit" | awk "{printf \"$file~\" \$1 \"\\n\"}" | sort | uniq >> $vTMPFILE2
    done
    PCFAILURES="`comm -23 $vTMPFILE1 $vTMPFILE2 | grep -v nvauth`"
    for service in $PCFAILURES ; do
        $CSV || printf "FAILURE: Pam 608 <$service> not configured for SAS.\n"
        $CSV && printf "\"STATUS\",608,\"pam check\",2,\"Pam service <$service> not configured for SAS\"\n"
        FAILURE=true
    done
#    vTMPFILE2=/tmp/_vas_pc_test.2.$$
#    sed -e 's/#.*//' -e '/^[ 	]*$/d' < $vTMPFILE | awk '{print $1 "><" $2}' | sort | uniq > $vTMPFILE1
#    cat /etc/pam.conf | sed -e 's/#.*//' -e '/^[ 	]*$/d' | grep pam_vas | awk '{print $1 "><" $2}' | sort | uniq > $vTMPFILE2
#    rm -rf $vTMPFILE1 $vTMPFILE2 $vTMPFILE3 $vTMPFILE4
    echo $vTMPFILE1 $vTMPFILE2 $vTMPFILE3 $vTMPFILE4
    cd "$CWD"
}

ac_check ()
{
    $DEBUG && set -x
    COUNT="`printf \".timeout 5000\nselect count(*) from access_control where rule_type='$1' and source='$2';\n.q\n\" | $SQL $IDENTDB 2>/dev/null`"
    if [ $COUNT -eq 0 ] ; then
        ACGOOD=false
        $CSV || echo "FAILURE: 222 No entries in access_control for <$3>"
        $CSV && printf "\"STATUS\",222,\"access control check\",2,\"No entries in access_control for <$3>\"\n"
        FAILURE=true
    fi
}

ac_check2 ()
{
    $DEBUG && set -x
    COUNT="`printf \".timeout 5000\nselect count(*) from access_control where rule_type='$1' and source='$2';\n.q\n\" | $SQL $IDENTDB 2>/dev/null`"
    if [ $COUNT -eq 0 ] ; then
        ACGOOD=false
    fi
}

validate_ac ()
{
    $DEBUG && set -x

    FILECOUNTA=`cat /etc/opt/quest/vas/access.d/*.allow $UALLOW 2>/dev/null | grep -v "^@" | grep -vi "^[CDO][CNU]=" | grep -v "^[ 	]*#" | sed -e 's/^\([^#]*\)#.*/\1/' -e 's/[ 	]*$//' | grep -v "^[ 	]*$" | tr  $LOWER $UPPER | sort | uniq | wc -l| awk '{print $1}'`
    FILECOUNTD=`cat /etc/opt/quest/vas/access.d/*.deny $UDENY 2>/dev/null | grep -v "^@" | grep -vi "^[CDO][CNU]=" | grep -v "^[ 	]*#" | sed 's/^\([^#]*\)#.*/\1/' | grep -v "^[ 	]*$" | tr  $LOWER $UPPER | sort | uniq | wc -l| awk '{print $1}'`
    CACHECOUNTA=`printf ".timeout 5000\nselect count(distinct rule)  from access_control where rule_type='A' and level in ('U','G');\n.q\n" |$SQL3 $IDENTDB`
    CACHECOUNTD=`printf ".timeout 5000\nselect count(distinct rule)  from access_control where rule_type='D' and level in ('U','G');\n.q\n" |$SQL3 $IDENTDB`
    BADGROUPCOUNT=`printf ".timeout 5000\nselect count(rule) from access_control where level='G' and alt_rule_name not in (select domain_sids.domainsid || '-' || group_ad.lridpart from group_ad join domain_sids on group_ad.domainsidkey=domain_sids.domainsidkey);\n.q\n" |$SQL3 $IDENTDB`

    RVAL=0
    if [ $FILECOUNTA != $CACHECOUNTA ] ; then
        $CSV || printf "FAILURE: 721 In-consistent access control ALLOW cache, check syslog for exact entry\n"
        $CSV && printf "\"STATUS\",721,\"access control allow check\",2,\"In-consistent access control ALLOW cache\"\n"
        FAILURE=true
        RVAL=1
    fi
    if [ $FILECOUNTD != $CACHECOUNTD ] ; then
        $CSV || printf "FAILURE: 721 In-consistent access control DENY cache, check syslog for exact entry\n"
        $CSV && printf "\"STATUS\",721,\"access control allow check\",2,\"In-consistent access control DENY cache\"\n"
        FAILURE=true
        RVAL=1
    fi
    if [ $FILECOUNTA -gt 0 -o $FILECOUNTD -gt 0 ] ; then
        if [ "x$BADGROUPCOUNT" != "x0" ] ; then
            $CSV || printf "FAILURE: 721 Group entry with unknown SID, please examine access control files\n"
            $CSV && printf "\"STATUS\",721,\"access control allow check\",2,\"Group entry with unknown SID, check access control files\"\n"
            FAILURE=true
            RVAL=1
        fi
    fi
    return $RVAL
}

nss_link_tests ()
{
    NSS_PATHS=
    MISSING_NSS_PATHS=0
    case $PLATFORM in
        LINUX_S390X)
            NSS_PATHS="/lib64/libnss_vas[34].so.2"
            ;;
        LINUX*)
            for p in /lib/i386-linux-gnu /lib /lib32 /lib/x86_64-linux-gnu /lib64 ; do
                if [ -d $p ] ; then
                    ls $p/*nss_file* >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then
                        NSS_PATHS="$NSS_PATHS $p/libnss_vas[34].so.2"
                    fi
                fi
            done
            ;;
        SOLARIS*)
            if [ -d /lib/amd64 ] ; then
                NSS_PATHS="$NSS_PATHS /lib/amd64/nss_vas[34].so.1 /lib/nss_vas[34].so.1"
            elif [ -d /usr/lib ] ; then
                NSS_PATHS="$NSS_PATHS /usr/lib/nss_vas[34].so.1"
            fi

            # Bug 226240 - Only check sparcv9 dir if actually on sparc.
            uname -p | grep sparc >/dev/null 2>&1
            if [ "$?" -eq 0 ] ; then
                NSS_PATHS="$NSS_PATHS /usr/lib/sparcv9/nss_vas[34].so.1"
            fi
            ;;
        HPUX*)
            if [ -f /opt/quest/lib/pa20_64/nss/libnss_vas4.1 ] ; then
                NSS_PATHS="/usr/lib/libnss_vas[34].1 /usr/lib/pa20_64/libnss_vas[34].1"
            else
                NSS_PATHS="/usr/lib/libnss_vas[34].1 /usr/lib/hpux32/libnss_vas[34].so.1 /usr/lib/hpux64/libnss_vas[34].so.1"
            fi
            ;;
        AIX*)
            grep "^netgroup.*vas" /etc/irs.conf >/dev/null 2>&1
            if [ $? -eq 0 ] ; then
                NSS_PATHS="/usr/lib/netsvc/dynload/vas.so /usr/lib/netsvc/dynload/vas_64.so"
            fi
            ;;
        FREEBSD*)
            NSS_PATHS="/lib/nss_vas4.so.1"
            ;;
    esac

    if [ -z "$MappedFile" ] ; then
        MSG="FAILURE: 609"
    else
        MSG="INFO: 609"
    fi

    if [ ! -z "$NSS_PATHS" ] ; then
        for p in $NSS_PATHS ; do
            $LS $p >/dev/null 2>&1
            if [ $? -ne 0 ] ; then
                echo "$MSG Missing expected NSS path <$p>"
                if [ -z "$MappedFile" ] ; then
                    $CSV && printf "\"STATUS\",609,\"NSS check\",2,\"Missing expected NSS path <$p>\"\n"
                fi
                MISSING_NSS_PATHS=1
            fi
        done
    fi

    if [ $MISSING_NSS_PATHS -eq 0 ] ; then
        return 0
    else
        return 1
    fi
}

pam_link_tests ()
{
    PAM_PATHS=
    MISSING_PAM_PATHS=0
    case $PLATFORM in
        LINUX_S390X)
            PAM_PATHS="/lib64/security/pam_vas[34].so"
            ;;
        LINUX*)
            if [ -d /lib/i386-linux-gnu/security ] ; then
                PAM_PATHS="/lib/i386-linux-gnu/security/pam_vas[34].so"
            else
                if [ -d /lib ] ; then
                    PAM_PATHS="/lib/security/pam_vas[34].so"
                fi
                if [ -d /lib32 ] ; then
                    PAM_PATHS="/lib32/security/pam_vas[34].so"
                fi
            fi
            if [ -d /lib/x86_64-linux-gnu/security ] ; then
                PAM_PATHS="/lib/x86_64-linux-gnu/security/pam_vas[34].so"
            else
                if [ -d /lib64/security ] ; then
                    PAM_PATHS="/lib64/security/pam_vas[34].so"
                fi
            fi
            if [ -d /lib/aarch64-linux-gnu/security ]; then
                PAM_PATHS="/lib/aarch64-linux-gnu/security/pam_vas[34].so"
            fi
            ;;
        SOLARIS*)
            if [ -d /lib/security/amd64 ] ; then
                PAM_PATHS="$PAM_PATHS /lib/security/amd64/pam_vas[34].so /lib/security/pam_vas[34].so"
            elif [ -d /usr/lib/security ] ; then
                PAM_PATHS="$PAM_PATHS /usr/lib/security/pam_vas[34].so"
            fi
            if [ -d /usr/lib/security/sparcv9 ] ; then
                PAM_PATHS="$PAM_PATHS /usr/lib/security/sparcv9/pam_vas[34].so"
            fi
            ;;
        HPUX*)
            if [ -d /usr/lib/security ] ; then
                PAM_PATHS="/usr/lib/security/libpam_vas[34].*1"
            fi
            if [ -d /usr/lib/security/hpux32 ] ; then
                PAM_PATHS="$PAM_PATHS /usr/lib/security/hpux32/libpam_vas[34].so.1"
            fi
            if [ -d /usr/lib/security/hpux64 ] ; then
                PAM_PATHS="$PAM_PATHS /usr/lib/security/hpux64/libpam_vas[34].so.1"
            elif [ -d /usr/lib/security/pa20_64 ] ; then
                if [ `uname -r | cut -d. -f3` -gt 11 ] ; then
                    # Just info, because this depends on package used.
                    $LS /usr/lib/security/pa20_64/libpam_vas[34].1 >/dev/null 2>&1
                    if [ $? -ne 0 ] ; then
                        $CSV || echo "INFO: Missing PAM lib/link </usr/lib/security/pa20_64/libpam_vas[34].1>, vasclnt_9000 package used instead of vasclnt_pa-11.11, 64-bit PAM unavailable"
                    fi
                fi
            fi
            ;;
        AIX*)
            if [ -f /etc/pam.conf ] ; then
                PAM_PATHS="/usr/lib/security/pam_vas[34].so /usr/lib/security/pam_vas[34]64.so"
                if [  ${VASVERMAJOR}${VASVERMINOR} -ge 35 ] ; then
                    PAM_PATHS="/usr/lib/security/pam_vas[34].so /usr/lib/security/64/pam_vas[34].so"
                fi

            fi
            ;;
    esac

    if [ ! -z "$PAM_PATHS" ] ; then
        for p in $PAM_PATHS ; do
            $LS $p >/dev/null 2>&1
            if [ $? -ne 0 ] ; then
                $CSV || echo "FAILURE: 610 Missing PAM path <$p>"
                $CSV && printf "\"STATUS\",610,\"PAM path check\",2,\"Missing PAM path <$p>\"\n"
                MISSING_PAM_PATHS=1
            fi
        done
    fi

    if [ $MISSING_PAM_PATHS -eq 0 ] ; then
        return 0
    else
        return 1
    fi
}

dir_full_tests ()
{
    case $PLATFORM in
        LINUX*)
            TMPUSED="`df -k /tmp | grep '[0-9]%' | sed 's/.* \([0-9]*\)% .*/\1/' `"
            VARUSED="`df -k /var/opt/quest/vas | grep '[0-9]%' | sed 's/.* \([0-9]*\)% .*/\1/' `"
        ;;
        SOLARIS*)
            TMPUSED="`df -k /tmp | grep '[0-9]%' | sed 's/.* \([0-9]*\)% .*/\1/' `"
            VARUSED="`df -k /var/opt/quest/vas | grep '[0-9]%' | sed 's/.* \([0-9]*\)% .*/\1/' `"
        ;;
        HPUX*)
            TMPUSED="`df -k /tmp 2>/dev/null | grep '%' | awk '{print $1}'`"
            VARUSED="`df -k /var/opt/quest/vas 2>/dev/null | grep '%' | awk '{print $1}'`"
        ;;
        AIX*)
            TMPUSED="`df -k /tmp | grep '^/' | awk '{print $4}' | sed 's/%$//' `"
            VARUSED="`df -k /var/opt/quest/vas | grep '^/' | awk '{print $4}' | sed 's/%$//' `"
        ;;
        OSX*)
            TMPUSED="`df -k /tmp | grep '^/' | awk '{print $5}' | sed 's/%$//' `"
            VARUSED="`df -k /var/opt/quest/vas | grep '^/' | awk '{print $5}' | sed 's/%$//' `"
        ;;
    esac

    RVAL=0

    if [ -d /tmp -a ! -z "$TMPUSED" ] ; then
        if [ "x$TMPUSED" = "x100" ] ; then
            $CSV || echo "CRITICAL: 611 /tmp is full"
            $CSV && printf "\"STATUS\",611,\"Free disk space check\",3,\"/tmp is full\"\n"
            CRITICAL_FAILURE=true
            FAILURE=true
            RVAL=2
        elif [ "x$TMPUSED" = "x98" -o "x$TMPUSED" = "x99" ] ; then
            $CSV || echo "WARNING: 611 /tmp is almost full"
            $CSV && printf "\"STATUS\",611,\"Free disk space check\",1,\"/tmp is almost full\"\n"
            WARNING=true
            RVAL=1
        fi
    fi

    if [ -d /var/opt/quest/vas -a ! -z "$VARUSED" ] ; then
        if [ "x$VARUSED" = "x100" ] ; then
            $CSV || echo "CRITICAL: 611 /var/opt/quest/vas is full"
            $CSV && printf "\"STATUS\",611,\"Free disk space check\",3,\"/var/opt/quest/vas is full\"\n"
            CRITICAL_FAILURE=true
            FAILURE=true
            RVAL=2
        elif [ "x$VARUSED" = "x98" -o "x$VARUSED" = "x99" ] ; then
            $CSV || echo "WARNING: 611 /var/opt/quest/vas is almost full"
            $CSV && printf "\"STATUS\",611,\"Free disk space check\",1,\"/var/opt/quest/vas is almost full\"\n"
            WARNING=true
            RVAL=1
        fi
    fi

    return $RVAL
}

mem_tests ()
{
    SZL=120000
    PROCESSES=""
    case $PLATFORM in
        AIX*)
            PROCESSES="`$PS -eo vsz,pid,comm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
        ;;
        LINUX_X64)
            SZL=95000
            PROCESSES="`$PS -eo rss,pid,comm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
        ;;
        LINUX_IA64)
            PROCESSES="`$PS -eo vsz,pid,comm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
        ;;
        HPUX_*)
            SZL=149000
            F=/tmp/_vs_$$
            rm -f $F 2>/dev/null
            COUNT="`$PS -eo pid | wc -l`"
            top -d1 -s1 -n`expr $COUNT + 10` -q -u -f $F 2>/dev/null
            if [ -f $F ] ; then
                grep "^CPU" $F >/dev/null
                if [ $? -eq 0 ] ; then
                    PROCESSES="`cat $F | grep \"[ /.][v]as[gproxy]*d\" | tr -d 'KM' | awk '{print $7 \"~\" $3 \"~\" $13 }'`"
                else
                    PROCESSES="`cat $F | grep \"[ /.][v]as[gproxy]*d\" | tr -d 'KM' | awk '{print $6 \"~\" $2 \"~\" $12 }'`"
                fi
                rm -f $F
            else
                PROCESSES=''
                printf "INFO: Skipping vasd memory usage test, incompatible top found"
            fi
        ;;
        OSX*)
            PROCESSES="`$PS -eAo rss,pid,ucomm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
            SZL=68000
            ;;
        SOLARIS1*)
            PROCESSES="`$PS -eo rss,pid,comm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
            ;;
        FREEBSD*)
            PROCESSES="`$PS ax -o vsz,pid,comm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
        ;;
        *)
            PROCESSES="`$PS -eo vsz,pid,comm | grep \"[ /.][v]as[gproxy]*d\" | awk '{print $1 \"~\" $2 \"~\" $3}'`"
        ;;
    esac

    UCOUNT=`printf ".timeout 5000\nSELECT count(*) from user_ad;\n.q\n" | ${SQL} ${IDENTDB} 2>/dev/null`
    if [ "x$UCOUNT" != "x" ] ; then
        SZL=`expr $SZL  + \( $UCOUNT \* 2 \)`
    fi

    GCOUNT=`printf ".timeout 5000\nSELECT count(*) from group_ad;\n.q\n" | ${SQL} ${IDENTDB} 2>/dev/null`
    if [ "x$GCOUNT" != "x" ] ; then
        SZL=`expr $SZL  + \( $GCOUNT \* 2 \)`
    fi

    NGCOUNT=`printf ".timeout 5000\nSELECT count(*) from ngentity;\n.q\n" | ${SQL} ${IDENTDB} 2>/dev/null | grep -v "SQL error" | grep -v " from ngentity"`
    if [ "x$NGCOUNT" != "x" ] ; then
        SZL=`expr $SZL  + \( $NGCOUNT \* 2 \)`
    fi

    RVAL=0
    PNAMES="`$VAS info processes 2>/dev/null`"
    SZL2=`expr $SZL \* 2`
    for proc in $PROCESSES ; do
        SZ="`echo $proc | cut -d~ -f1`"
        PD="`echo $proc | cut -d~ -f2`"
        PN="`echo $proc | cut -d~ -f3`"
        if [ -n "$PNAMES" ] ; then
            PTYPE="/`echo \"$PNAMES\" | grep $PD | cut -d: -f1`"
        fi

        if [ $SZ -ge $SZL2 ] ; then
            $CSV || echo "WARNING: 710 Process <$PD><$PN$PTYPE> is too large <${SZ} KB>"
            $CSV && printf "\"STATUS\",710,\"process memory size check\",1,\"Process <$PD><$PN> is too large <${SZ} KB>\"\n"
            WARNING=true
            RVAL=1
        elif [ $SZ -ge $SZL ] ; then 
            $CSV || echo "INFO: 710 Process <$PD><$PN$PTYPE> is getting larger than expected <${SZ} KB>"
        fi
    done

    return $RVAL
}

get_time ()
{
    date +"%Y_%m_%d %H:%M:%S"
}

get_vasconf_setting ()
{
# $1 section
# $2 setting
# Returns: value set, nothing if nothing is set

    $DEBUG && set -x

    SECTION="$1"
    SETTING="$2"

    if [ -z "$1" -o -z "$2" ] ; then
        return
    fi

    SETTING="`sed -e '/^[ 	]*#/d' -e 's/#.*//' -e 's/^[ 	]*//' < $VASCONF | grep \"^$2 \" | head -1`"
    RESULT="`echo $SETTING | sed 's/.* = \(.*\)[ 	]*/\1/'`"
    if [ ! -z "$RESULT" ] ; then echo "$RESULT" ; fi
}

VerifyRoot ()
{
    $DEBUG && set -x
# Test for root access.
    if [ "`id | sed 's/uid=\([0-9]*\).*/\1/'`" -ne 0 ] ; then
        echo "Must be root to run."
        exit 1
    fi
}

# Portable way of computing a second count for elapsed time calculations.
GetTime ()
{
    $DEBUG && set -x
    date +%j:%H:%M:%S | awk -F: '{printf "%d\n", $1 * 86400 + $2 * 3600 + $3 * 60 + $4}'
}
GetTimeDiff ()
{
    $DEBUG && set -x
    expr `GetTime` - $1
}

check_dups ()
{
    $DEBUG && set -x
    vDBFILE=/tmp/_vas_dup_test.DB.$$

    if [ ! "$1" = "user" -a ! "$1" = "group" ] ; then
        printf "Called with $1, not user/group"
        return 1
    fi

    rm -rf $vDBFILE
    echo ".timeout 5000" >> $vDBFILE
    echo "select 1 from $1_ad where guid is not null group by guid having count(*) > 1;" >> $vDBFILE
    echo ".q" >> $vDBFILE
    COUNT="`echo | $SQL -init $vDBFILE $IDENTDB | wc -l`"
    rm -rf $vDBFILE

    if [ $COUNT -gt 0 ] ; then
        return 1
    fi
    return 0
}

validate_db ()
{
    $DEBUG && set -x
    vDBFILE=/tmp/_vas_mu_test.DB.$$
    vTMPFILE1=/tmp/_vas_mu_test.1.$$
    vTMPFILE2=/tmp/_vas_mu_test.2.$$
    vMAPPEDFILE=/tmp/_vas_mu_test.map.$$

    rm -rf $vTMPFILE1 $vTMPFILE2 $vDBFILE $vMAPPEDFILE

    echo ".timeout 5000" >> $vDBFILE
    echo "BEGIN EXCLUSIVE TRANSACTION;" >> $vDBFILE
    echo "select value from misc where key='userMappings';" >> $vDBFILE
    echo "END TRANSACTION;" >> $vDBFILE
    echo ".q" >> $vDBFILE
    FILES="`echo | $SQL3 -init $vDBFILE $MISCDB`"


    FILES="`echo $FILES | tr ';' ' '`"
    LOCALCOUNT=0
    TMPCOUNT=0
    DID_ONE=0
    for file in $FILES ; do
        if [ -f $file ] ; then
            cat $file 2>/dev/null | tr -d '\r' | sed 's/[ 	]*$//' | sed 's/^\([^:]*\):@/\1:\1@/' | grep -v "^[ 	]*$" >> $vTMPFILE1
            vTMPCOUNT=`wc -l < $file`
            LOCALCOUNT=`expr $LOCALCOUNT + $vTMPCOUNT`
            DID_ONE=1
        fi
    done

    if [ "$DID_ONE" = "0" ] ; then
        $CSV || printf "FAILURE: 708 No mapped files existed: <$FILES>.\n"
        $CSV && printf "\"STATUS\",708,\"mapped files check\",2,\"No mapped files existed: <$FILES>\"\n"
        FAILURE=true
        rm -rf $vTMPFILE1 $vTMPFILE2 $vDBFILE $vMAPPEDFILE
        return 1
    fi

    sort < $vTMPFILE1 > $vTMPFILE2
    uniq < $vTMPFILE2 > $vMAPPEDFILE
    printf ".timeout 5000\n.separator :\nselect loginname, userprincipalname from mapped_user;\n.q\n" | $SQL3 $IDENTDB >$vTMPFILE1 2>/dev/null
    DBCOUNT=`wc -l < $vTMPFILE1`
    sort < $vTMPFILE1 > $vTMPFILE2
    uniq < $vTMPFILE2 > $vDBFILE

    comm -23 $vMAPPEDFILE $vDBFILE | awk '{print $1}' > $vTMPFILE1
    UNIQTOFILECOUNT="`wc -l < $vTMPFILE1`"

    comm -13 $vMAPPEDFILE $vDBFILE | awk '{print $1}' > $vTMPFILE2
    UNIQTODBCOUNT="`wc -l < $vTMPFILE2`"

    rm -rf $vTMPFILE1 $vTMPFILE2 $vDBFILE $vMAPPEDFILE

    RVAL=`expr $UNIQTOFILECOUNT + $UNIQTODBCOUNT`

    if [  $LOCALCOUNT -eq 0 ] ; then
        $CSV || printf "WARNING: 708 Local files <$FILES> empty of valid entries.\n"
        $CSV && printf "\"STATUS\",708,\"mapped files check\",1,\"Local files <$FILES> empty of valid entries\"\n"
        WARNING=true
        return 1
    fi

    if [ $RVAL -ne 0 ] ; then
        $CSV || printf "FAILURE: 708 In-consistent mapped user cache.\n"
        $CSV && printf "\"STATUS\",708,\"mapped files check\",2,\"In-consistent mapped user cache\"\n"
        FAILURE=true
    fi
    return $RVAL
}

get_setting ()
{
    echo ".timeout 5000" > $DBCMD 2>/dev/null
    echo "select value from misc where key='$1';">> $DBCMD 2>/dev/null
    echo ".q" >> $DBCMD 2>/dev/null
    echo | $SQL3 -init $DBCMD $MISCDB 2>&1
}

R ()
{
    $REPORT && printf "SUCCESS: $1\n"
}

GetHostInfo ()
{
    case `uname -s` in
        Linux)
            if [ -e /etc/os-release ];then
                HOSTINFO=`cat /etc/os-release | grep "^PRETTY_NAME" | sed -e 's/PRETTY_NAME=//;s/"//g'`

            elif [ -e /etc/SuSE-release ];then
                HOSTINFO=`cat /etc/SuSE-release | head -1`

            elif [ -e /etc/fedora-release ];then
                HOSTINFO=`cat /etc/fedora-release | head -1`

            elif [ -e /etc/redhat-release ];then
                HOSTINFO=`cat /etc/redhat-release | head -1`

            elif [ -e /etc/centos-release ];then
                HOSTINFO=`cat /etc/centos-release | head -1`

            elif [ -e /etc/oracle-release ];then
                HOSTINFO=`cat /etc/oracle-release | head -1`

            elif [ -e /etc/system-release ];then
                HOSTINFO=`cat /etc/system-release | head -1`

            else
                HOSTINFO=`uname -s -m`

            fi
            HOSTINFO="$HOSTINFO"
            case `uname -m` in
                ia64)
                    PLATFORM="LINUX_IA64"
                    ;;
                x86_64)
                    PLATFORM="LINUX_X64"
                    ;;
                s390)
                    PLATFORM="LINUX_S390"
                    ;;
                s390x)
                    PLATFORM="LINUX_S390X"
                    ;;
                aarch64)
                    PLATFORM="LINUX_ARM64"
                    ;;
                *)
                    PLATFORM="LINUX"
                    ;;
            esac
            ;;
        SunOS)
            HOSTINFO="`uname -s -r -p`"
            PLATFORM="SOLARIS_`uname -r|sed 's/[0-9]*\.\([0-9]*\)/\1/'`"
            uname -p | grep sparc >/dev/null 2>&1
            if [ "$?" -eq 0 ] ; then
                PLATFORM="${PLATFORM}_SPARC"
            else
                if [ -d "/usr/lib/64" ] ; then
                    PLATFORM="${PLATFORM}_X64"
                else
                    PLATFORM="${PLATFORM}_X86"
                fi
            fi
            ;;
        AIX)
            HOSTINFO="AIX `oslevel -r`"
            PLATFORM="AIX_`uname -v`_`uname -r`"
            ;;
        HP-UX)
            uname -m | grep "ia64" >/dev/null 2>&1
            if [ "$?" -eq 0 ] ; then
                PLATFORM="HPUX_IA64"
            else
                PLATFORM="HPUX_9000"
            fi
            HOSTINFO="`uname -s -r -m`"
            UNIX95=
            export UNIX95
            ;;
        Darwin)
            R=`uname -r | cut -d. -f1`
            V=`expr $R + 6`
            PLATFORM="OSX_${V}_`uname -r | cut -d. -f2`"
            HOSTINFO="`sw_vers -productName` `sw_vers -productVersion`"
            ;;
        FreeBSD)
            HOSTINFO="`uname -s -m`"
            case `uname -m` in
                amd64)
                    PLATFORM="FREEBSD_64"
                    ;;
                *)
                    PLATFORM="FREEBSD"
                    ;;
            esac
        ;;
        *)
            HOSTINFO="`uname -a`"
            ;;
    esac
}

t000 ()
{
    $DEBUG && set -x
    STARTTIME="`GetTime`"
    GetHostInfo
    $CSV || printf "Host:   <`hostname`, $HOSTINFO>\n"
    $CSV || printf "Date:   <`date`>\n"
    D="N/A"
    NOVAS=false
    if [ -f $VAS ] ; then
        TVASVERSION="`$VAS -v | grep -i version | head -1 | sed 's/vastool: .AS Version \([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)/\1.\2.\3.\4/'`"
        $CSV || printf "SAS:    <$TVASVERSION>\n"
        if [ ! -f $MISCDB ] ; then
            HAVE_MISC=0
        fi
        if [ ! -f $IDENTDB ] ; then
            HAVE_IDENT=0
        fi
        if [ "$NUM" = "false" ] ; then
            D="`$VAS info domain 2>/dev/null`"
        fi
        if [ -z "$D" ] ; then
            D="N/A"
        fi
    else
#   101 vastool exists.
        $NUM && printf "NUMBER:101\n"
        $CSV || printf "SAS:    <101 No Binary>\n"
        $CSV && printf "\"STATUS\",101,\"vastool exists\",5,\"No vastool found, is SAS installed?\"\n"
        if [ ! -f $SQL ] ; then
            NOVAS=true
            if [ -f $VASCONF -o -f $IDENTDB ] ; then
                $CSV || printf "INFO: 101 SAS related files on machine\n"
            fi
        fi
    fi
    $CSV || printf "Domain: <$D>\n"
    $CSV && printf "\"INFO\",\"Host:`hostname`\",\"Hostinfo:$HOSTINFO\",\"Date:`date`\",\"SAS:$TVASVERSION\",\"Domain:$D\",\"ScriptVersion:$VSVERSION\"\n"
    if [ !$CSV -a -x /usr/sbin/selinuxenabled ] ; then
		if [ !$CSV -a -x /usr/sbin/getenforce ] ; then
            DETAILED_SELINUX="(`/usr/sbin/getenforce 2>/dev/null`)"
	    fi
        VASD_SELINUX="NOT "
        if [ -x /opt/quest/libexec/vas/selinux/configure_vas_selinux.sh ]; then
            /opt/quest/libexec/vas/selinux/configure_vas_selinux.sh status >/dev/null && VASD_SELINUX=""
        fi
        /usr/sbin/selinuxenabled
        setstatus=$?
        if [ $setstatus -eq 0 ]; then
            printf "INFO: SELinux enabled ${DETAILED_SELINUX:+$DETAILED_SELINUX}, vasd policy is ${VASD_SELINUX}installed.\n"
            if [ "${VASD_SELINUX}" != "" -a -x "$TWOFABIN" -a -f "$TWOFAINFO" -a -f "$TWOFAFILE" ]; then
                ls -Z "$TWOFAINFO" | grep ":vasd_var_t" >/dev/null
                if [ $? -ne 0 ] ; then
                    printf "WARNING: vasd policy is NOT installed and Starling Two-Factor Authentication has been configured.\n"
                    printf "This will cause issues with Two-Factor authentication. Please run vastool configure selinux to fix this issue.\n"
                    WARNING=true;
                fi
            fi
            if [ "x${VASD_SELINUX}" == "x" ]; then
                # Bug 258782, this was giving a false positive on Redhat 6.
                # To support both RH 6 and 7 behavior, accept vasd_var_auth_t and var_auth_t.
                # This is really here for Bug 199536, but needed some work for 6's 'attempt' to also
                # support Authentication Services.
                ls -Zd "/var/opt/quest/vas/vasd" | grep "var_auth_t:" >/dev/null
                if [ $? -ne 0 ] ; then
                    printf "WARNING: Incorrect policy applied to vasd state directory.\n"
                    printf "To fix this, please run:\n$VAS configure selinux\n\n"
                    WARNING=true;
                fi
            fi
        fi
    fi
    $NOVAS && return 1
    R "101 $VAS exists"
    return 0
}

t100 ()
{
    $DEBUG && set -x

#   102 vastool runs ( no segfault/library issues )
    OUT="`$VAS -v 2>&1 | tr '\"\n' '~ '`"
    echo "$OUT" | grep -i copyright >/dev/null
    if [ $? -ne 0 ] ; then
        $NUM && printf "NUMBER:102\n"
        $CSV || printf "CRITICAL: 102 $VAS -v failed <$OUT>.\n"
        $CSV && printf "\"STATUS\",102,\"vastool -v works\",3,\"vastool -v: $OUT\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    fi
    R "102 $VAS runs"

#    103 SAS version ( < 3.0.3.17 or so and fail to run, as we won't have vastool auth )
    VASVERSION="`$VAS -v | grep -i version | head -1 | sed 's/vastool: .AS Version \([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)\.\([0-9]*\)/\1 \2 \3 \4/'`"
    VASVERMAJOR="`echo $VASVERSION | awk '{print $1}'`"
    VASVERMINOR="`echo $VASVERSION | awk '{print $2}'`"
    VASVERREVISION="`echo $VASVERSION | awk '{print $3}'`"
    VASVERBUILD="`echo $VASVERSION | awk '{print $4}'`"
    if [ "$VASVERMAJOR" -eq "3" -a "$VASVERMINOR" = "0" -a -n "$VASVERREVISION" -a $VASVERREVISION -lt 3 ] ; then
        $NUM && printf "NUMBER:103\n"
        $CSV || printf "FAILURE: 103 SAS version <$VASVERSION> too low\n"
        $CSV && printf "\"STATUS\",103,\"Verify SAS version is at least version 3.1\",2,\"SAS is version $VASVERSION\"\n"
        FAILURE=true
    else
        R "103 usable SAS Version"
    fi

#    104 vas.conf exists
    if [ ! -f $VASCONF ] ; then
        $NUM && printf "NUMBER:104\n"
        $CSV || printf "CRITICAL: 104 No $VASCONF, is SAS joined?\n"
        $CSV && printf "\"STATUS\",104,\"Checking for vas.conf\",3,\"No $VASCONF found, is SAS joined?\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "104 $VASCONF exists"
    fi

#    105 vas.conf is valid ( ERROR: Could not allocate VAS context, err = 2 )
    $VAS ktutil list | grep krb5_init_context >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:105\n"
        $CSV || printf "CRITICAL: 105 $VASCONF is an invalid file or misconfigured.\n"
        $CSV && printf "\"STATUS\",105,\"Checking for valid vas.conf\",3,\"$VASCONF is invalid or misconfigured\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "105 $VASCONF valid format"
    fi

#    106 Check for missing default_realm setting.
    REALM="`get_vasconf_setting libdefaults default_realm`"
    if [ -z "$REALM" ] ; then
        $NUM && printf "NUMBER:106\n"
        $CSV || printf "CRITICAL: 106 $VASCONF missing default_realm setting, is SAS joined?\n"
        $CSV && printf "\"STATUS\",106,\"Checking for default_realm setting in vas.conf\",3,\"$VASCONF missing default_realm setting, is SAS joined?\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "106 $VASCONF default_realm"
    fi

#    107 Keytab file exists
    if [ ! -f $KEYTAB ] ; then
        $NUM && printf "NUMBER:107\n"
        $CSV || printf "CRITICAL: 107 $KEYTAB does not exist.\n"
        $CSV && printf "\"STATUS\",107,\"Checking for $KEYTAB\",3,\"$KEYTAB does not exist\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "107 $KEYTAB exists"
    fi

#    108 keytab is valid ( not an empty/corrupted file ( krb5_kt_start_seq_get ) )
    $VAS ktutil list | grep krb5_kt_start_seq_get >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:108\n"
        $CSV || printf "CRITICAL: 108 $KEYTAB is invalid\n"
        $CSV && printf "\"STATUS\",108,\"Checking for valid keytab\",3,\"$KEYTAB is invalid\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "108 $KEYTAB not empty/corrupt"
    fi
#    109 vgptool runs ( if installed, no segfault/library issues )
    if [ -f $VGP ] ; then
        OUT="`$VGP -v 2>&1 | tr '\"\n' '~ '`"
        echo "$OUT" | grep -i copyright >/dev/null
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:109\n"
            $CSV || printf "CRITICAL: 109 $VGP -v failed, OUTPUT: <$OUT>\n"
            $CSV && printf "\"STATUS\",109,\"vgptool -v works\",3,\"vgptool -v: $OUT\"\n"
            FAILURE=true
            CRITICAL_FAILURE=true
            return 1
        fi
    fi
    R "109 $VGP runs"

#    110 vasgpd runs ( if installed, no segfault/library issues )
    if [ -f $VGPD ] ; then
        if [ ${VASVERMAJOR}${VASVERMINOR} -ge 40 ] ; then
            $CSV || printf "CRITICAL: 110 $VGPD should not exist in version 4.0+\n"
            $CSV && printf "\"STATUS\",110,\"vasgpd doesn't exist\",3,\"$VGPD exists, shouldn't in SAS 4.X\"\n"
            FAILURE=true
            CRITICAL_FAILURE=true
            return 1
        fi
        OUT="`$VGPD -v 2>&1 | tr '\"\n' '~ '`"
        echo "$OUT" | grep -i copyright >/dev/null
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:110\n"
            $CSV || printf "CRITICAL: 110 $VGPD -v failed, OUTPUT: <$OUT>\n"
            $CSV && printf "\"STATUS\",110,\"vasgpd -v works\",3,\"vasgpd -v: $OUT\"\n"
            FAILURE=true
            CRITICAL_FAILURE=true
            return 1
        fi
        R "110 $VGPD runs"
    else
        R "110 $VGPD test is not applicable"
    fi

#    sbin/vasd sbin/vasypd sbin/vasgpd bin/vgptool bin/uptool sbin/vasproxyd libexec/vas/vasldapd
#   111 Other binaries run.
    $QUICK || for F in sbin/vasd sbin/vasypd bin/uptool sbin/vasproxyd ; do
        if [ -f /opt/quest/$F ] ; then
            OUT="`/opt/quest/$F -v 2>&1 | tr '\n' ' '`"
            echo "$OUT" | grep -i copyright >/dev/null
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:111\n"
                $CSV || printf "CRITICAL: 111 /opt/quest/$F -v failed, OUTPUT: <$OUT>\n"
                $CSV && printf "\"STATUS\",111,\"/opt/quest/$F -v works\",3,\"$F -v output: $OUT\"\n"
                FAILURE=true
                CRITICAL_FAILURE=true
            fi
        fi
    done
    if $CRITICAL_FAILURE ; then
        return 1
    fi

    R "111 Other binaries run"

#   113 vas.conf Windows line endings
    for F in $VASCONF ; do
        if cat -ve $F | grep '\^\M\$$' >/dev/null 2>&1 ; then
            $NUM && printf "NUMBER:113\n"
            $CSV || printf "CRITICAL: 113 <$VASCONF> has Windows-style line endings, SAS will be unable to parse it\n"
            $CSV && printf "\"STATUS\",113,\"<$VASCONF> has Windows-style line endings\",3,\"$VASCONF has Windows-style line endings and will not be parsed correctly\"\n"
            FAILURE=true
            CRITICAL_FAILURE=true
        fi
    done
    if $CRITICAL_FAILURE ; then
        return 1
    fi

    R "113 vas.conf Windows-style line endings"

#   112 vas.conf settings
    check_vas_conf

#   611 var and tmp directories are not full
    $QUICK || dir_full_tests
    RVAL=$?
    $QUICK || if [ $RVAL -ne 0 ] ; then
        $NUM && printf "NUMBER:611\n"
        if [ $RVAL -eq 2 ] ; then
            CRITICAL_FAILURE=true
            return 1
        fi
    else
        R "611 tmp/var directories ok"
    fi

    return 0
}

t200 ()
{
    $DEBUG && set -x
# * Local DB
#    201 misc cache exists.
    if [ ! -f $MISCDB -o "$HAVE_MISC" = "0" ] ; then
        $NUM && printf "NUMBER:201\n"
        $CSV || printf "CRITICAL: 201 $MISCDB does not exist.\n"
        $CSV && printf "\"STATUS\",201,\"vas_misc.vdb exists\",3,\"$MISCDB doesn't exist\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "201 $MISCDB exists"
    fi

#    202 ident cache exists.
    if [ ! -f $IDENTDB -o "$HAVE_IDENT" = "0" ] ; then
        $NUM && printf "NUMBER:202\n"
        $CSV || printf "CRITICAL: 202 $IDENTDB does not exist.\n"
        $CSV && printf "\"STATUS\",202,\"vas_ident.vdb exists\",3,\"$IDENTDB doesn't exist\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "202 $IDENTDB exists"
    fi

#    203 misc cache is not hard locked.
    printf ".timeout 10500\n.tables\n.q\n" | $SQL3 $MISCDB 2>&1 | grep "database is locked" >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:203\n"
        $CSV || printf "CRITICAL: 203 The $MISCDB file is hard locked.\n"
        $CSV && printf "\"STATUS\",203,\"vas_misc.vdb isn't hard locked\",3,\"$MISCDB is hard locked\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "203 $MISCDB not hard locked"
    fi


#    204 misc cache is not soft locked.
    printf ".timeout 1000\nbegin exclusive transaction;\nend transaction;\n.q\n" | $SQL3 $MISCDB 2>&1 | grep "database is locked" >/dev/null
    if [ $? -eq 0 ] ; then
        sleep 4
# Second try, wait a while to avoid conflicting lock-race conditions.
        printf ".timeout 5000\nbegin exclusive transaction;\nend transaction;\n.q\n" | $SQL3 $MISCDB 2>&1 | grep "database is locked" >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:204\n"
            $CSV || printf "WARNING: 204 The $MISCDB file is soft locked.\n"
            $CSV && printf "\"STATUS\",204,\"vas_misc.vdb isn't soft locked\",1,\"$MISCDB is soft locked\"\n"
            WARNING=true
        else
            R "204 $MISCDB not soft locked"
        fi
    else
        R "204 $MISCDB not soft locked"
    fi



#    205  ident cache is not hard locked.
    printf ".timeout 10000\n.tables\n.q\n" | $SQL3 $IDENTDB 2>&1 | grep "database is locked" >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:205\n"
        $CSV || printf "CRITICAL: 205 The $IDENTDB file is hard locked.\n"
        $CSV && printf "\"STATUS\",205,\"vas_ident.vdb isn't hard locked\",3,\"$IDENTDB is hard locked\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "205 $IDENTDB not hard locked"
    fi

#    206 ident cache is not soft locked.
    printf ".timeout 1000\nbegin exclusive transaction;\nend transaction;\n.q\n" | $SQL3 $IDENTDB 2>&1 | grep "database is locked" >/dev/null
    if [ $? -eq 0 ] ; then
        sleep 4
        printf ".timeout 5000\nbegin exclusive transaction;\nend transaction;\n.q\n" | $SQL3 $IDENTDB 2>&1 | grep "database is locked" >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:206\n"
            $CSV || printf "WARNING: 206 The $IDENTDB file is soft locked.\n"
            $CSV && printf "\"STATUS\",206,\"vas_ident.vdb isn't soft locked\",1,\"$IDENTDB is soft locked\"\n"
            WARNING=true
        else
            R "206 $IDENTDB not soft locked"
        fi
    else
        R "206 $IDENTDB not soft locked"
    fi

#    207 Misc cache is a DB file.
    printf ".timeout 10500\n.tables\n.q\n" | $SQL3 $MISCDB >$fOUT 2>&1
    cat "$fOUT" | grep "is not a database" >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:207\n"
        $CSV || printf "CRITICAL: 207 The $MISCDB file is not a valid database file.\n"
        $CSV && printf "\"STATUS\",207,\"vas_misc.vdb isn't valid\",3,\"$MISCDB isn't a valid vdb file\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "207 $MISCDB is a valid file"
    fi

#    208 Misc cache is not corrupt.
    cat "$fOUT" | grep "malformed" >/dev/null
    if [ $?  -eq 0 ] ; then
        $NUM && printf "NUMBER:208\n"
        $CSV || printf "CRITICAL: 208 The $MISCDB cache is corrupt.\n"
        $CSV && printf "\"STATUS\",208,\"vas_misc.vdb isn't corrupt\",3,\"$MISCDB is corrupt\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "208 $MISCDB is not corrupt"
    fi

    if [ "$QUICK" = "true" -a -f $ASDCOM ] ; then
        PRAGMA=quick_check
    else
        PRAGMA=integrity_check
    fi
#   209 Misc cache is not otherwise broken...
    printf ".timeout 10500\nPRAGMA $PRAGMA;\n.q\n" | $SQL3 $MISCDB 2>&1 | grep -i "error" >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:209\n"
        $CSV || printf "CRITICAL: 209 The $MISCDB cache is invalid, $PRAGMA failed.\n"
        $CSV && printf "\"STATUS\",209,\"vas_misc.vdb isn't invalid\",3,\"$MISCDB $PRAGMA failed\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "208 $MISCDB is not otherwise broken"
    fi


#   210 ident cache is a DB file.
    printf ".timeout 10500\n.tables\n.q\n" | $SQL3 $IDENTDB >$fOUT 2>&1
    cat "$fOUT" | grep "is not a database" >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:210\n"
        $CSV || printf "CRITICAL: 210 The $IDENTDB file is not a valid database file.\n"
        $CSV && printf "\"STATUS\",210,\"vas_ident.vdb isn't valid\",3,\"$IDENTDB isn't a valid vdb file\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "210 $IDENTDB is a valid file"
    fi

#   211 Ident cache is not corrupt.
    cat "$fOUT" | grep "malformed" >/dev/null
    if [ $?  -eq 0 ] ; then
        $NUM && printf "NUMBER:211\n"
        $CSV || printf "CRITICAL: 211 The $IDENTDB cache is corrupt.\n"
        $CSV && printf "\"STATUS\",211,\"vas_ident.vdb isn't corrupt\",3,\"$IDENTDB is corrupt\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "211 $IDENTDB is not corrupt"
    fi

#   212 Ident cache is not otherwise broken...
    printf ".timeout 10500\nPRAGMA $PRAGMA;\n.q\n" | $SQL3 $IDENTDB 2>&1 | grep -i "error" >/dev/null
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:212\n"
        $CSV || printf "CRITICAL: 212 The $IDENTDB cache is invalid, $PRAGMA failed.\n"
        $CSV && printf "\"STATUS\",212,\"vas_ident.vdb isn't invalid\",3,\"$IDENTDB $PRAGMA failed\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "212 $IDENTDB is not otherwise broken"
    fi

#    213 All needed tables exist. ( No missing tables, careful here, given version differences ).
    MISCTABLES="misc srvinfo usn_cache table_ctrl"
    IDENTTABLES="user_ad user_posix user_ovrd user_ovrd_bygroup group_ad group_posix group_ovrd group_member domain_sids nudn table_ctrl"
    MISSINGTABLE=0
    CURRENTMTABLES="`printf \".timeout 5000\n.tables\n.q\n\" | $SQL3 $MISCDB 2>&1`"
    for table in $MISCTABLES ; do
        echo $CURRENTMTABLES | grep $table >/dev/null
        if [ $? -ne 0 ] ; then
            $CSV || printf "CRITICAL: Unable to locate table $table in $MISCDB\n"
            $CSV && printf "\"STATUS\",213,\"Checking for expected tables\",3,\"$MISCDB missing table $table\"\n"
            MISSINGTABLE=1
        fi
    done

    CURRENTITABLES="`printf \".timeout 5000\n.tables\n.q\n\" | $SQL3 $IDENTDB 2>&1`"
    for table in $IDENTTABLES ; do
        echo $CURRENTITABLES | grep $table >/dev/null
        if [ $? -ne 0 ] ; then
            $CSV || printf "CRITICAL: Unable to locate table $table in $IDENTDB\n"
            $CSV && printf "\"STATUS\",213,\"Checking for expected tables\",3,\"$IDENTDB missing table $table\"\n"
            MISSINGTABLE=1
        fi
    done

    HASAC=false
    echo $CURRENTITABLES | grep access_control >/dev/null
    if [ $? -eq 0 ] ; then
        HASAC=true
    fi

    if [ "$MISSINGTABLE" = "1" ] ; then
        $NUM && printf "NUMBER:213\n"
        $CSV || printf "CRITICAL: 213 The local DB cache is missing one or more needed tables.\n"
        $CSV && printf "\"STATUS\",213,\"Checking for expected tables\",3,\"The local DB cache is missing one or more needed tables.\"\n"
        FAILURE=true
        CRITICAL_FAILURE=true
        return 1
    else
        R "213 all required tables found"
    fi

    FORESTROOT="`get_setting forestRoot`"
    COMPUTERFQDN="`get_setting computerFQDN`"
    COMPUTERNAME="`get_setting computerName`"
    LOCALSITE="`get_setting localSite`"
    DEFAULTREALM="`get_setting defaultRealm`"
    UPMPATH="`get_setting upmSearchBase`"

#    215 machine has found a site, or has an override site set.
    if [ -z "$LOCALSITE" ] ; then
        $NUM && printf "NUMBER:215\n"
        $CSV || printf "WARNING: 215 The computer object is not in a site.\n"
        $CSV && printf "\"STATUS\",215,\"Checking for site\",1,\"Machine is not in a site\"\n"
        WARNING=true
    else
        R "215 computer object in site"
    fi

#    216 Misc table has defaultRealm
    if [ -z "$DEFAULTREALM" ] ; then
        $NUM && printf "NUMBER:216\n"
        $CSV || printf "FAILURE: 216 Missing defaultRealm|<DOMAIN> setting in the misc DB.\n"
        $CSV && printf "\"STATUS\",216,\"Checking for defaultRealm\",2,\"misc cache missing defaultRealm value, is the machine joined?\"\n"
        FAILURE=true
    else
        R "216 misc cache has defaultRealm"
    fi


#    217 Misc table has computerfqdn
    if [ -z "$COMPUTERFQDN" ] ; then
        $NUM && printf "NUMBER:217\n"
        $CSV || printf "FAILURE: 217 The misc cache is missing the computerFQDN setting for this machine.\n"
        $CSV && printf "\"STATUS\",217,\"Checking for computerFQDN\",2,\"misc cache missing computerFQDN value, is the machine joined?\"\n"
        FAILURE=true
    else
        R "217 misc cache has computerFQDN"
    fi

#    218 Misc table has computername
    if [ -z "$COMPUTERNAME" ] ; then
        $NUM && printf "NUMBER:218\n"
        $CSV || printf "FAILURE: 218 The misc cache is missing the computerName setting for this machine.\n"
        $CSV && printf "\"STATUS\",218,\"Checking for computerName\",2,\"misc cache missing computerName value, is the machine joined?\"\n"
        FAILURE=true
    else
        R "218 misc cache has computerName"
    fi

#    219 Misc table has forestRoot
    if [ -z "$FORESTROOT" ] ; then
        $NUM && printf "NUMBER:219\n"
        $CSV || printf "FAILURE: 219 The misc cache is missing the forestRoot setting for this machine.\n"
        $CSV && printf "\"STATUS\",219,\"Checking for forestRoot\",2,\"misc cache missing forestRoot value\"\n"
        FAILURE=true
    else
        R "219 misc cache has forestRoot"
    fi

#   220 Check for large ident db.
    SZ="`$LS -Llad $IDENTDB | awk '{print $5}'`"
    if [ "$SZ" -ge 500000000 ] ; then
        $NUM && printf "NUMBER:220\n"
        $CSV || echo "WARNING: 220 Ident DB is larger than 500MB <$SZ>"
        $CSV && printf "\"STATUS\",220,\"Ident DB file size\",1,\"$IDENTDB is <$SZ> bytes, bigger than 500MB\"\n"
        WARNING=true
    else
        R "220 Ident db not big"
    fi

#   221 Check for large misc db.
    SZ="`$LS -Llad $MISCDB | awk '{print $5}'`"
    if [ "$SZ" -ge 20000000 ] ; then
        $NUM && printf "NUMBER:221\n"
        $CSV || echo "WARNING: 221 Misc DB is larger than 20MB <$SZ>"
        $CSV && printf "\"STATUS\",221,\"Misc DB file size\",1,\"$MISCDB is <$SZ> bytes, bigger than 20MB\"\n"
        WARNING=true
    else
        R "221 Misc db not big"
    fi

# Switch out UALLOW/UDENY for the vas.conf settings.
    TMPA="`get_setting pamUsersAllow`"
    if [ -n "$TMPA" ] ; then
        UALLOW="$TMPA"
    fi
    TMPD="`get_setting pamUsersDeny`"
    if [ -n "$TMPD" ] ; then
        UDENY="$TMPD"
    fi

#    222 High level users.allow/deny to access_control sanity.
    if [ ! "x`get_setting accessControlMode`" = "xVGP" ] ; then
        if [ -f $UALLOW ] ; then
            ac_check A LOCAL $UALLOW
        fi
        $LS /etc/opt/quest/vas/access.d/*.allow 2>/dev/null | while IFS= read file; do
            ac_check A "`basename \"$file\"`" "$file"
        done
        if [ -f $UDENY ] ; then
            ac_check D LOCAL $UDENY
        fi
        $LS /etc/opt/quest/vas/access.d/*.deny 2>/dev/null | while IFS= read file; do
            ac_check D "`basename \"$file\"`" "$file"
        done
#   224 If using Windows policy, make sure misc is set that way.
        if [ "x$HASAC" = "xtrue" -a -f $VGPCONF ] ; then
            grep "^[ 	]*ApplyWindowsHostAccess[ 	]*=[ 	]*[tT][rR][uU][eE]" < $VGPCONF >/dev/null
            if [ $? -eq 0 ] ; then
                $NUM && printf "NUMBER:224\n"
                $CSV || echo "FAILURE: 224 VGP Windows access control not applied in misc setting"
                $CSV && printf "\"STATUS\",224,\"If ApplyWindowsHostAccess in vgp.conf, vas_misc is set correctly\",2,\"Native AC enabled in vgp.conf but vasd isn't using\"\n"
                FAILURE=true
            else
                R "224 VGP Windows access control not applied"
            fi
        else
            R "224 VGP Windows access control not applied"
        fi
    fi

    if $ACGOOD ; then
        R "222 High level access control test"
    else
        $NUM && printf "NUMBER:222\n"
    fi

#    223 warn if computer name is 'localhost' or 'unknown'.
    COMPUTERNAME="`get_setting computerName | tr  $LOWER $UPPER`"
    if [ "$COMPUTERNAME" = "LOCALHOST" -o "$COMPUTERNAME" = "UNKNOWN" -o "$COMPUTERNAME" = "LINUX" ] ; then
            $NUM && printf "NUMBER:223\n"
            $CSV || printf "WARNING: 223 Computer object joined with default name <$COMPUTERNAME>.\n"
            $CSV && printf "\"STATUS\",223,\"If ApplyWindowsHostAccess in vgp.conf, vas_misc is set correctly\",1,\"Native AC enabled in vgp.conf but vasd isn't using\"\n"
            WARNING=true
    else
        R "223 Computer joined with unique name"
    fi

#   225 If using Windows policy, make sure some are set.
    if [ -f $VGPCONF ] ; then
        grep "^[ 	]*ApplyWindowsHostAccess[ 	]*=[ 	]*[tT][rR][uU][eE]" < $VGPCONF >/dev/null
        if [ $? -eq 0 ] ; then
            ACGOOD=true
            ac_check2 A VGP
            if $ACGOOD ; then
                R "225 VGP Windows access control not applied"
            else
                # No allow entries, check deny entries.
                ACGOOD=true
                ac_check2 D VGP
                if $ACGOOD ; then
                    $NUM && printf "NUMBER:225\n"
                    $CSV || echo "FAILURE: 225 VGP Windows access control applied, but no ALLOW policy found"
                    $CSV && printf "\"STATUS\",225,\"If using Native AC, check for an ALLOW policy\",2,\"Native AC enabled, but no ALLOW policy found in cache\"\n"
                    FAILURE=true
                else
                    # No allow OR deny rules. Now check VGP.
                    $VGP rsop | grep "Host access .* list:" >/dev/null
                    if [ $? -ne 0 ] ; then
                        # No actual Native AC policies applied to the system.
                        $NUM && printf "NUMBER:225\n"
                        $CSV || echo "WARNING: 225 VGP ApplyWindowsHostAccess enabled, but no ALLOW/DENY Policies apply to this system"
                        $CSV && printf "\"STATUS\",225,\"If using Native AC, check for an ALLOW policy\",1,\"ApplyWindowsHostAccess enabled, but no ALLOW/DENY policies apply to this system\"\n"
                        WARNING=true
                    else
                        # VGP has policies listed, but they are not cached.
                        $NUM && printf "NUMBER:225\n"
                        $CSV || echo "FAILURE: 225 VGP Windows access control seen, but not in the cache, check vgptool rsop and vastool info acl"
                        $CSV && printf "\"STATUS\",225,\"If using Native AC, check for an ALLOW policy\",2,\"Native AC enabled, but no ALLOW policy found in cache\"\n"
                        FAILURE=true
                    fi
               fi
            fi
        else
            R "225 VGP Windows access control not applied"
        fi
    else
        R "225 VGP Windows access control not applied"
    fi

    if [ ! -z "$UPMPATH" ] ; then
        $NUM && printf "NUMBER:230\n"
        $CSV || printf "INFO: 230 In UPM, path <$UPMPATH>\n"
    else
        R "230 UPM check"
    fi

    COUNT=0
    COUNT="`printf \".timeout 5000\nselect count(*) from srvinfo where realm='\`$VAS info domain 2>/dev/null\`' and status is not 'Y';\n.q\n\" | $SQL $MISCDB 2>/dev/null`"
    if [ "x$COUNT" = "x0" ] ; then
        $NUM && printf "NUMBER:232\n"
        $CSV || echo "INFO: 232 No srvinfo entry for joined domain"
    else
        R "232 Checking srvinfo entry for joined domain"
    fi

    UFLUSH="`get_setting userFlushRunningSince`"
    AFLUSH="`get_setting anyFlushRunningSince`"
    if [ -n "$UFLUSH" -o -n "$AFLUSH" ] ; then
        sleep 4
        UFLUSH="`get_setting userFlushRunningSince`"
        AFLUSH="`get_setting anyFlushRunningSince`"
        if [ -n "$UFLUSH" -o -n "$AFLUSH" ] ; then
            $NUM && printf "NUMBER:233\n"
            $CSV || printf "WARNING: 233 misc set that a flush is running\n"
            $CSV && printf "\"STATUS\",233,\"misc set that a flush is running\",1,\"Misc has set that a flush is running\"\n"
            WARNING=true
        else
            R "233 Checking that a flush isn't running"
        fi
    else
        R "233 Checking that a flush isn't running"
    fi

    NUCOUNT="`printf \".timeout 5000\\nselect count(nudnkey) from user_ad where nudnkey not in (select nudnkey from nudn);\\n\" | $SQL3 $IDENTDB`"
    NGCOUNT="`printf \".timeout 5000\\nselect count(nudnkey) from group_ad where nudnkey not in (select nudnkey from nudn);\\n\" | $SQL3 $IDENTDB`"
    if [ $NUCOUNT -ne 0 -o $NGCOUNT -ne 0 ] ; then
        $NUM && printf "NUMBER:235\n"
        $CSV || printf "FAILURE: 235 Orphaned NUDN key(s), flush needed\n"
        $CSV && printf "\"STATUS\",235,\"orphaned nudn keys\",2,\"Orphaned NUDN entries, flush needed\"\n"
        FAILURE=true
    else
        R "235 Checking for no orphaned NUDN keys"
    fi

    DUCOUNT="`printf \".timeout 5000\\nselect count(domainsidkey) from user_ad where domainsidkey not in (select domainsidkey from domain_sids);\\n\" | $SQL3 $IDENTDB`"
    DGCOUNT="`printf \".timeout 5000\\nselect count(domainsidkey) from group_ad where domainsidkey not in (select domainsidkey from domain_sids);\\n\" | $SQL3 $IDENTDB`"
    if [ $DUCOUNT -ne 0 -o $DGCOUNT -ne 0 ] ; then
        $NUM && printf "NUMBER:236\n"
        $CSV || printf "FAILURE: 236 Orphaned DOMAIN key(s), flush needed\n"
        $CSV && printf "\"STATUS\",236,\"orphaned domain keys\",2,\"Orphaned DOMAIN entries, flush needed\"\n"
        FAILURE=true
    else
        R "236 Checking for no orphaned DOMAIN keys"
    fi

    if [ "x`$VAS inspect libvas use-server-referrals 2>/dev/null | tr $LOWER $UPPER`" = "xTRUE" ] ; then
        $NUM && printf "NUMBER:237\n"
        $CSV || printf "INFO: use-server-referrals is set to true\n"
    else
        R "237 use-server-referrals check"
    fi

    if [ "x`$VAS inspect libvas smb-dialect-range`" != "x" ] ; then
        RESULT=0
        MIN_DIALECT="`$VAS inspect libvas smb-dialect-range | awk -F'-' '{gsub(/ /, "", $1); print $1}'`"
        MAX_DIALECT="`$VAS inspect libvas smb-dialect-range | awk -F'-' '{gsub(/ /, "", $2); print $2}'`"

        printf ",1,2.0.2,2.1,3,3.1.1,\n" | grep ",${MIN_DIALECT}," 2>&1 >/dev/null
        RESULT=`expr $RESULT + $?`
        printf ",1,2.0.2,2.1,3,3.1.1,+,\n" | grep ",${MAX_DIALECT}," 2>&1 >/dev/null
        RESULT=`expr $RESULT + $?`
        printf ",1,2.0.2,2.1,3,3.1.1,+,\n" | grep ",${MIN_DIALECT}.*${MAX_DIALECT}," 2>&1 >/dev/null || test ${MIN_DIALECT} = ${MAX_DIALECT}
        RESULT=`expr $RESULT + $?`

        if [ $RESULT -ne 0 ] ; then
            $NUM && printf "NUMBER:240\n"
            $CSV || printf "WARNING: 240 smb-dialect-range '%s - %s' is invalid\n" ${MIN_DIALECT} ${MAX_DIALECT}
            $CSV && printf "\"STATUS\",240,\"smb-dialect-range sanity check\",1,\"smb-dialect-range '%s - %s' is invalid\"\n" ${MIN_DIALECT} ${MAX_DIALECT}
        else
            R "240 smb-dialect-range sanity check"
        fi
    fi

    ATTR="`$VAS schema list | awk '{if( \$1 == "GroupName" ) print \$4}' | grep -vi \"^cn\" | grep -vi \"^samaccountname\" | grep -vi \"^altSecurityIdentities\" | tr '\n' ' '`"
    if [ -n "$ATTR" ] ; then
        $NUM && printf "NUMBER:238\n"
        $CSV || printf "INFO: schema/groupname-attr-name not using cn/sam/schemaless: <$ATTR>\n"
    else
        R "238 schema/groupname-attr-name check"
    fi

    ATTR="`$VAS schema list | awk '{if( \$1 == "UserName" ) print \$4}' | grep -vi \"^samaccountname\" | tr '\n' ' '`"
    if [ -n "$ATTR" ] ; then
        $NUM && printf "NUMBER:239\n"
        $CSV || printf "INFO: schema/username-attr-name not using sam: <$ATTR>\n"
    else
        R "239 schema/username-attr-name check"
    fi

    WSMODE=0
    WS="`get_setting workstationMode`"
    echo $WS | grep -i true >/dev/null 2>&1
    if [ "$?" -eq 0 ] ; then
        WSMODE=1
    fi

    UUSNCOUNT="`printf \".timeout 5000\nselect count(*) from usn_cache where objtype='U';\n.q\n\" | $SQL $MISCDB 2>/dev/null`"
    if [ $UUSNCOUNT -eq 0 ] ; then
        if [  $WSMODE -eq 0 ] ; then
            $NUM && printf "NUMBER:241\n"
            $CSV || printf "WARNING: 241 No USN entries for users\n"
            $CSV && printf "\"STATUS\",241,\"no usn entries for users\",1,\"USN cache is missing entries for users\"\n"
            WARNING=true
        else
            $NUM && printf "NUMBER:241\n"
            $CSV || printf "INFO: 241 No USN entries for users, in workstation mode\n"
        fi
    else
        R "241 Checking for User USN entries"
    fi

    GUSNCOUNT="`printf \".timeout 5000\nselect count(*) from usn_cache where objtype='G';\n.q\n\" | $SQL $MISCDB 2>/dev/null`"
    if [ $GUSNCOUNT -eq 0 ] ; then
        $NUM && printf "NUMBER:242\n"
        $CSV || printf "WARNING: 242 No USN entries for groups\n"
        $CSV && printf "\"STATUS\",242,\"no usn entries for groups\",1,\"USN cache is missing entries for groups\"\n"
        WARNING=true
    else
        R "242 Checking for Group USN entries"
    fi

    if [ "x`$VAS inspect vasd load-users-from-gc 2>/dev/null | tr $LOWER $UPPER`" = "xTRUE" -o \
         "x`$VAS inspect vasd load-groups-from-gc 2>/dev/null | tr $LOWER $UPPER`" = "xTRUE" ] ; then
        $VAS schema list 2>&1 | grep "Some attributes used for storing Unix identity are not in the global catalog" >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:243\n"
            $CSV || printf "INFO: 243 load-*-from-gc is in use, not all attributes are in the Global Catalog\n"
        else
            R "243 load-*-from-gc check"
        fi
    else
        R "243 load-*-from-gc check"
    fi


    if [ -f $ASDCOM ] ; then
#   231 Warn if vasd reports that is operating in disconnected mode.
        $ASDCOM | grep GetConnectedStatus > /dev/null
        if [ $? = 0 ] ; then
            CONOUT=`$ASDCOM GetConnectedStatus`
            if [ $? = 0 ]; then
                $NUM && printf "NUMBER:231\n"
                $CSV || printf "WARNING: 231 $CONOUT\n"
                $CSV && printf "\"STATUS\",231,\"SAS Daemon Connected State Check\",1,\"$CONOUT\"\n"
                WARNING=true
            fi
        else
            R "231 vasd in a connected state"
        fi
        #for now, skip, since naming works differently these will have to be re-worked.
        return 0
    fi

    if [ -f /etc/opt/quest/vas/user-override -o -f /etc/opt/quest/vas/group-override ] ; then
        if [ -f /etc/opt/quest/vas/user-override ] ; then
            U_LIST="`printf \".timeout 5000\nselect ua.userPrincipalName from user_ovrd as uo join user_ad as ua on uo.userkey=ua.userkey where ua.cn is null;\n.q\n\" | $SQL $IDENTDB 2>/dev/null | tr '\n' ',' | sed 's/,$//'`"
            if [ -n "$U_LIST" ] ; then
                WARNING=true
                $NUM && printf "NUMBER:226\n"
                $CSV || echo "WARNING: 226 user override has unknown entry(s) <$U_LIST>"
                $CSV && printf "\"STATUS\",226,\"Checking user-override\",1,\"Unknown entry(s) found in user-override <$U_LIST>\"\n"
            else
                R "226 User override consistency, no dummy entries"
            fi
            UG_LIST="`printf \".timeout 5000\nselect ga.samaccountname from user_ovrd_bygroup as go join group_ad as ga on go.groupkey=ga.groupkey where ga.cn is null;\n.q\n\" | $SQL $IDENTDB 2>/dev/null | tr '\n' ',' | sed 's/,$//'`"
            if [ -n "$UG_LIST" ] ; then
                WARNING=true
                $NUM && printf "NUMBER:227\n"
                $CSV || echo "WARNING: 227 user override by group has unknown entry(s) <$UG_LIST>"
                $CSV && printf "\"STATUS\",227,\"Checking user-override\",1,\"Unknown entry(s) found in user-override by group <$UG_LIST>\"\n"
            else
                R "227 User override by group consistency, no dummy entries"
            fi
            UP_LIST="`printf \".timeout 5000\nselect uo.userPrincipalName from user_ovrd as uo join user_ad as ua on uo.userkey=ua.userkey where ua.userprincipalname != uo.userprincipalname;\n.q\n\" | $SQL $IDENTDB 2>/dev/null | tr '\n' ',' | sed 's/,$//'`"
            if [ -n "$UP_LIST" ] ; then
                WARNING=true
                $NUM && printf "NUMBER:228\n"
                $CSV || echo "WARNING: 228 user override by entries with changed UPN(s) <$UP_LIST>"
                $CSV && printf "\"STATUS\",228,\"Checking user-override\",1,\"Override entries with changed UPN: <$UG_LIST>\"\n"
            else
                R "228 User override consistency, changed upn"
            fi
        else
            R "226 User override consistency, no dummy entries"
            R "227 User override by group consistency, no dummy entries"
            R "228 User override consistency, changed upn"
        fi

        if [ -f /etc/opt/quest/vas/group-override ] ; then
            F_LIST="`printf \".timeout 5000\nselect ga.samaccountname from group_ovrd as go join group_ad as ga on go.groupkey=ga.groupkey where ga.cn is null;\n.q\n\" | $SQL $IDENTDB 2>/dev/null | tr '\n' ',' | sed 's/,$//'`"
            if [ -n "$F_LIST" ] ; then
                WARNING=true
                $NUM && printf "NUMBER:229\n"
                $CSV || echo "WARNING: 229 group override has unknown entry(s) <$F_LIST>"
                $CSV && printf "\"STATUS\",229,\"Checking group-override\",1,\"Unknown group-override entries: <$F_LIST>\"\n"
            else
                R "229 Group override consistency, no dummy entries"
            fi
        else
            R "229 Group override consistency, no dummy entries"
        fi

    else
        R "226 User override consistency, no dummy entries"
        R "227 User override by group consistency, no dummy entries"
        R "228 User override consistency, changed upn"
        R "229 Group override consistency, no dummy entries"
    fi

return 0
}

t300 ()
{
    $DEBUG && set -x
# * kinit results
# First, kdestroy just in case, so anything left in the credentials cache isn't
# interfearing with the testing, which occasionally might fix things, but not
# sure how to check/report that, so will jsut deal with it if it happens.
    KRB5CCNAME=/tmp/_vas_status_ccache_$$
    export KRB5CCNAME
    $VAS kdestroy >/dev/null 2>&1
    SET_CCNAME=true
    RESULTS2="`$VAS -d5 kinit host/ 2>&1`"
    RVAL=$?
    RESULTS="`printf \"%s\" \"$RESULTS2\" | tr '\"\n' '~ '`"
    if [ $RVAL -ne 0 ] ; then
        ADFAILURE=true
        FAILURE=true
#   301 Machine can talk to AD ( KDC_UNREACH )
        echo "$RESULTS" | grep 1765328228 >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:301\n"
            $CSV || printf "FAILURE: 301 SAS cannot find a Domain Controller (DC) that it can communicate with.\n"
            $CSV && printf "\"STATUS\",301,\"vastool kinit processing\",2,\"Unable to find a DC to contact\"\n"
            return 0
        fi

#   302 Object exists in AD. ( client unknown )
        echo "$RESULTS" | grep 1765328378 >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:302\n"
            $CSV || printf "FAILURE: 302 SAS cannot find its host/ object in AD\n"
            $CSV && printf "\"STATUS\",302,\"vastool kinit processing\",2,\"Unable to find machine's host/ object in AD\"\n"
            return 0
        fi
    else
        R "301 kdc reachable"
        R "302 computer object in AD"
    fi

#   303 Machine timesync. ( TIME_SKEW )
#   kinit may print this debug message even if the exit status of kinit is 0:
#   _send_and_recv_srvinfo: KDC <skynet-dc.qasdev.oi> returned error <KRB5KRB_AP_ERR_SKEW>
    echo "$RESULTS" | grep KRB5KRB_AP_ERR_SKEW >/dev/null
    if [ $? -eq 0 ] ; then
        ADFAILURE=true
        FAILURE=true
        $NUM && printf "NUMBER:303\n"
        $CSV || printf "FAILURE: 303 SAS is not in time sync with the AD controller it is contacting.\n"
        $CSV && printf "\"STATUS\",303,\"vastool kinit processing\",2,\"Out of time sync with DC contacted\"\n"
        return 0
    else
        R "303 timesync ok"
    fi

#   if kinit failed
    if [ $RVAL -ne 0 ] ; then
#   304 The host.keytab knows the right password. ( preauth failed ).
        echo "$RESULTS" | grep 1765328360 >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:304\n"
            $CSV || printf "FAILURE: 304 SAS does not know the correct password for the AD object.\n"
            $CSV && printf "\"STATUS\",304,\"vastool kinit processing\",2,\"Invalid password for host/ object\"\n"
            return 0
        fi

#   305 The host/ account is usable ( CREDENTIALS REVOKED )
        echo "$RESULTS" | grep 1765328366 >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:305\n"
            $CSV || printf "FAILURE: 305 The AD object is not usable at this time(revoked credentials).\n"
            $CSV && printf "\"STATUS\",305,\"vastool kinit processing\",2,\"Machine's host/ credentials have been revoked\"\n"
            return 0
        fi

#   306 DES is set, but no entries ( KRB5KDC_ERR_PREAUTH_REQUIRED )
        echo "$RESULTS" | grep 1765328359 >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:306\n"
            $CSV || printf "FAILURE: 306 The AD object is requiring unknown key type.\n"
            $CSV && printf "\"STATUS\",306,\"vastool kinit processing\",2,\"Machine's host/ requiring unknown Kerberos key type\"\n"
            return 0
        fi

#   307 ( Misc kinit error, not one of the above known ones ).
        $NUM && printf "NUMBER:307\n"
        $CSV || printf "FAILURE: 307 Unknown vastool kinit result/error: <$RVAL><$RESULTS>.\n"
        $CSV && printf "\"STATUS\",307,\"vastool kinit processing\",2,\"Unknown vastool -u host/ kinit error <$RVAL><$RESULTS>\"\n"
    else
        R "304 can access computer object"
        R "305 valid credentials"
        R "306 correct key type in kinit"
        R "307 no unknown errors talking to AD"
    fi
    echo "$RESULTS" | grep "SOCK_DGRAM" >/dev/null
    if [ $? -eq 0 ] ; then
        echo "$RESULTS" | grep "SOCK_STREAM" >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:308\n"
                $CSV || printf "WARNING: 308 TCP failover detected, [libvas] use-tcp-only = true recommended if this consistently fails\n"
                $CSV && printf "\"STATUS\",308,\"vastool kinit processing\",1,\"vastool kinit used udp then tcp, use-tcp-only suggested if this is consistent\"\n"
                WARNING=true
        else
            R "308 tcp used"
        fi
    else
        R "308 tcp used"
    fi
    return 0
}

t400 ()
{
    $DEBUG && set -x
    $ADFAILURE && return 0
# * Computer account checks.
#   401 Computer can read AD object.
    BASE="`$VAS info domain-dn`"
    if [ -z "$COMPUTERNAME" ] ; then
        FQDN=`$VAS ktutil list | grep "host/.*\..*@" | head -1 | awk '{print $3}' | sed 's/host\/\([^@]*\)@.*/\1/'`
        COMPUTERNAME=`echo $FQDN | cut -d. -f1 | tr $LOWER $UPPER`
    fi
    C="`printf \"%s\\n\" \"$COMPUTERNAME\" | sed -e 's/(/\\\\(/g' -e 's/)/\\\\)/g'`"
    CATTRS="`$VAS search -U DC://@$DEFAULTREALM -b \"$BASE\" \"(samaccountname=${C}$)\" userPrincipalName userAccountControl servicePrincipalName 2>&1`"
    RVAL=$?
#    echo "$VAS search -U DC://@$DEFAULTREALM \"(samaccountname=${COMPUTERNAME}$)\" userPrincipalName userAccountControl servicePrincipalName"
    echo "$CATTRS" | grep -i "could not resolve Service"
    if [ $? -eq 0 ] ; then
        $NUM && printf "NUMBER:401\n"
        $CSV || printf "WARNING: 401 The AD permissions do not allow the host to read its own attributes.\n"
        $CSV && printf "\"STATUS\",401,\"Check host/ object permissions\",1,\"host/ object cannot read itself\"\n"
        WARNING=true
        return 0
    else
        if [ $RVAL -ne 0 ] ; then
            $NUM && printf "NUMBER:401\n"
            $CSV || printf "FAILURE: 401 Was unable to query AD for host/ attributes, output: <$CATTRS>.\n"
            $CSV && printf "\"STATUS\",401,\"Check host/ object permissions\",2,\"host/ object cannot read itself\"\n"
            FAILURE=true
            return 0
        else
            R "401 host/ can read self"
        fi
    fi

#   402 Computer account has valid UPN.
    if [ ! -z "$COMPUTERFQDN" ] ; then
        UPN="`echo \"$CATTRS\" | grep \"^userPrincipalName\" | cut -d: -f2 | sed 's/^[ 	]*//'`"
        EXPECTEDUPN="host/$COMPUTERFQDN@`echo $DEFAULTREALM | tr  $LOWER $UPPER`"
        U1="`echo $UPN | tr $UPPER $LOWER`"
        U2="`echo $EXPECTEDUPN | tr $UPPER $LOWER`"
        # Bug 806318, it can be empty. This is common for a delgated join situation, and doesn't affect SAS.
        # Still report if it exists, but isn't the expected value.
        if [ "x$U1" != "x" -a ! "$U1" = "$U2" ] ; then
            $NUM && printf "NUMBER:402\n"
            $CSV || printf "INFO: 402 Computer object has UPN of: <$UPN> (expected <$EXPECTEDUPN>).\n"
        else
            R "402 host/ has valid upn"
        fi
    fi

    echo | bc >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
#   403 Computer account userAccountControl has ADS_UF_DONT_EXPIRE_PASSWD
        UAC="`echo \"$CATTRS\" | grep \"^userAccountControl\" | cut -d: -f2 | sed 's/^[ 	]*//'`"
# The 'No password change required' flag is kept in the 17th bit.
        NOPASSWD=17
#echo $UAC
        BINUAC="`echo \"obase=2; $UAC\" | bc`"
        NOPWSET=0
        LEN="`printf \"$BINUAC\" | wc -m | awk '{print $1}'`"
        if [ $LEN -eq $NOPASSWD ] ; then
            NOPWSET=1
        elif [ $LEN -gt $NOPASSWD ] ; then
            LEN2=`expr $LEN - $NOPASSWD + 1`
            if [ `echo $BINUAC | cut -c$LEN2` -eq 1 ] ; then
                NOPWSET=1
            fi
        fi

# Just INFO on this, it's not set on offline join computers.
        if [ $NOPWSET -eq 0 ] ; then
            $NUM && printf "NUMBER:403\n"
            $CSV || printf "INFO: 403 Computer object userAccountControl does not have DONT_EXPIRE_PASSWORD set.\n"
        else
            R "403 host/ has DONT_EXPIRE_PASSWORD set"
        fi

#   404 Computer account userAccountControl has VAS_UF_WORKSTATION_TRUST_ACCOUNT
        WSTRUSTBIN=13
        WSTRUST=0
        LEN="`printf \"$BINUAC\" | wc -m | awk '{print $1}'`"
        if [ $LEN -eq $WSTRUSTBIN ] ; then
            WSTRUST=1
        elif [ $LEN -gt $WSTRUSTBIN ] ; then
            LEN2=`expr $LEN - $WSTRUSTBIN + 1`
            if [ `echo $BINUAC | cut -c$LEN2` -eq 1 ] ; then
                WSTRUST=1
            fi
        fi

        if [ $WSTRUST -eq 0 ] ; then
            $NUM && printf "NUMBER:404\n"
            $CSV || printf "WARNING: 404 Computer object userAccountControl does not have ADS_UF_WORKSTATION_TRUST_ACCOUNT set.\n"
            $CSV && printf "\"STATUS\",404,\"Check for ADS_UF_WORKSTATION_TRUST_ACCOUNT\",1,\"Computer object userAccountControl does not have ADS_UF_WORKSTATION_TRUST_ACCOUNT set\"\n"
            WARNING=true
        else
            R "404 host/ has ADS_UF_WORKSTATION_TRUST_ACCOUNT set"
        fi

#   405 Computer account userAccountControl doesn't have ADS_UF_USE_DES_KEY_ONLY
        DESBIN=22
        USEDES=0
        LEN="`printf \"$BINUAC\" | wc -m | awk '{print $1}'`"
        if [ $LEN -eq $DESBIN ] ; then
            USEDES=1
        elif [ $LEN -gt $DESBIN ] ; then
            LEN2=`expr $LEN - $DESBIN + 1`
            if [ `echo $BINUAC | cut -c$LEN2` -eq 1 ] ; then
                USEDES=1
            fi
        fi

        if [ $USEDES -eq 1 ] ; then
            $NUM && printf "NUMBER:405\n"
            $CSV || printf "WARNING: 405 The computer object userAccountControl has USE_DES_KEY_ONLY set.\n"
            $CSV && printf "\"STATUS\",405,\"Check for USE_DES_KEY_ONLY\",1,\"Computer object userAccountControl has USE_DES_KEY_ONLY set\"\n"
            WARNING=true
        else
            R "405 host/ doesn't have USE_DES_KEY_ONLY set"
        fi

#   406 Computer account userAccountControl doesn't have ADS_UF_DONT_REQUIRE_PREAUTH
        NOPREAUTHBIN=23
        NOPREAUTH=0
        LEN="`printf \"$BINUAC\" | wc -m | awk '{print $1}'`"
        if [ $LEN -eq $NOPREAUTHBIN ] ; then
            NOPREAUTH=1
        elif [ $LEN -gt $NOPREAUTHBIN ] ; then
            LEN2=`expr $LEN - $NOPREAUTHBIN + 1`
            if [ `echo $BINUAC | cut -c$LEN2` -eq 1 ] ; then
                NOPREAUTH=1
            fi
        fi

        if [ $NOPREAUTH -eq 1 ] ; then
            $NUM && printf "NUMBER:406\n"
            $CSV || printf "WARNING: 406 Computer object userAccountControl has ADS_UF_DONT_REQUIRE_PREAUTH set.\n"
            $CSV && printf "\"STATUS\",406,\"Check for ADS_UF_DONT_REQUIRE_PREAUTH\",1,\"Computer object userAccountControl has ADS_UF_DONT_REQUIRE_PREAUTH set\"\n"
            WARNING=true
        else
            R "406 host/ doesn't have ADS_UF_DONT_REQUIRE_PREAUTH set"
        fi

#    407 Computer account userAccountControl doesn't have ADS_UF_PASSWD_NOTREQD
        PWNOTREQBIN=6
        NOPW=0
        LEN="`printf \"$BINUAC\" | wc -m | awk '{print $1}'`"
        if [ $LEN -eq $PWNOTREQBIN ] ; then
            NOPW=1
        elif [ $LEN -gt $PWNOTREQBIN ] ; then
            LEN2=`expr $LEN - $PWNOTREQBIN + 1`
            if [ `echo $BINUAC | cut -c$LEN2` -eq 1 ] ; then
                NOPW=1
            fi
        fi

        if [ $NOPW -eq 1 ] ; then
            $NUM && printf "NUMBER:407\n"
            $CSV || printf "WARNING: 407 Computer object userAccountControl has ADS_UF_PASSWD_NOTREQD set.\n"
            $CSV && printf "\"STATUS\",407,\"Check for ADS_UF_PASSWD_NOTREQD\",1,\"Computer object userAccountControl has ADS_UF_PASSWD_NOTREQD set\"\n"
            WARNING=true
        else
            R "407 host/ doesn't have ADS_UF_PASSWD_NOTREQD set"
        fi
    fi
    DOMAINDUPES="`cat $VASCONF | sed -e 's/#.*//' -e '/^[ 	]*$/d' | awk '{{if ($1~/^[ 	]*\[vas_host_services]/) IN=1; else if ($1~/^[ 	]*\[/) IN=0; }; if (IN==1 && $0~/.*= *\{ *$/) print $1;}' | cut -d= -f1 | sort | uniq -d| wc -l`"
    if [ $DOMAINDUPES -gt 0 ] ; then
        $NUM && printf "NUMBER:409\n"
            $CSV || printf "FAILURE: 409 vas_host_services multiple entries for one (or more) domain(s), processing of vas_host_services stopped.\n"
            $CSV && printf "\"STATUS\",410,\"vas_host_services one entry per domain\",2,\"vas_host_services multiple entries for one (or more) domain(s)\"\n"
            FAILURE=true
            return 0
    else
        R "410 vas_host_services one entry per domain"
    fi
    CDOMAINS="`cat $VASCONF | sed -e 's/#.*//' -e '/^[ 	]*$/d'| awk '{{if ($1~/^[ 	]*\[vas_host_services]/) IN=1; else if ($1~/^[ 	]*\[/) IN=0; }; if (IN==1 && $0~/.*= *\{ *$/) print $1;}' | cut -d= -f1| tr '\n' ' '`"
    $QUICK || if [ -n "$CDOMAINS" ] ; then
        #echo "<$CDOMAINS>"
        for D in $CDOMAINS; do
            KRB5NAME="`awk \"{{if (\\\$0~/^[ \	]*$D *= *\{/) IN=1; else if (\\\$1~/^[ 	]*\\}/) IN=0;}; {if ( IN==1 ) { if ( \\\$0~/^ *krb5name/) print \\\$0  }}}\" < /etc/opt/quest/vas/vas.conf | sed 's/=/ = /'| awk '{print \$3}'`"
            KEYTAB="`awk \"{{if (\\\$0~/^[ \	]*$D *= *\{/) IN=1; else if (\\\$1~/^[ 	]*\\}/) IN=0;}; {if ( IN==1 ) { if ( \\\$0~/^ *keytab/) print \\\$0  }}}\" < /etc/opt/quest/vas/vas.conf | sed 's/=/ = /'| awk '{print \$3}'`"
            USEFORAUTH="`awk \"{{if (\\\$0~/^[ \	]*$D *= *\{/) IN=1; else if (\\\$1~/^[ 	]*\\}/) IN=0;}; {if ( IN==1 ) { if ( \\\$0~/^ *use-for-auth/) print \\\$0  }}}\" < /etc/opt/quest/vas/vas.conf | sed 's/=/ = /'| awk '{print \$3}'| tr $UPPER $LOWER`"
            if [ -z "$KEYTAB" ] ; then
                KEYTAB="/etc/opt/quest/vas/`echo $KRB5NAME | sed -e 's~/.*$~~'`.keytab"
            fi
            #printf "Domain: <%s>\nkrb5name: <%s>\nKeytab: <%s>\nUse-for-auth: <%s>\n" "$D" "$KRB5NAME" "$KEYTAB"  "$USERFORAUTH"

#    410 krb5name is set
            if [ -z "$KRB5NAME" ] ; then
                $NUM && printf "NUMBER:410\n"
                $CSV || printf "FAILURE: 410 vas_host_services entry for domain <$D> missing krb5name setting.\n"
                $CSV && printf "\"STATUS\",410,\"vas_host_services check krb5name\",2,\"vas_host_services entry for domain <$D> missing krb5name setting\"\n"
                FAILURE=true
                continue
            else
                R "410 vas_host_services has krb5name"
            fi

#    411 keytab exists
            if [ ! -f "$KEYTAB" ] ; then
                $NUM && printf "NUMBER:411\n"
                $CSV || printf "FAILURE: 411 vas_host_services entry for domain <$D> missing keytab <$KEYTAB>.\n"
                $CSV && printf "\"STATUS\",411,\"vas_host_services check keytab\",2,\"vas_host_services entry for domain <$D> missing keytab\"\n"
                FAILURE=true
                continue
            else
                R "411 vas_host_services keytab exists"
            fi
#    412 keytab has entry for krb5name
            $VAS ktutil -k $KEYTAB list 2>/dev/null | grep -i "$KRB5NAME" >/dev/null 2>&1
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:412\n"
                $CSV || printf "FAILURE: 412 vas_host_services entry for domain <$D> keytab <$KEYTAB> missing entry for <$KRB5NAME>.\n"
                $CSV && printf "\"STATUS\",412,\"vas_host_services check keytab has krb5name\",2,\"vas_host_services entry for domain <$D> keytab <$KEYTAB> missing entry for <$KRB5NAME>\"\n"
                FAILURE=true
                continue
            else
                R "412 vas_host_services keytab has krb5name entry"
            fi
#    413 not joined domain
            DOMAIN="`$VAS info domain|tr $UPPER $LOWER`"
            if [ "$DOMAIN" = "$D" ] ; then
                $NUM && printf "NUMBER:413\n"
                $CSV || printf "FAILURE: 413 vas_host_services has entry for joined domain <$D>.\n"
                $CSV && printf "\"STATUS\",413,\"vas_host_services entry for joined domain\",2,\"vas_host_services has entry for joined domain <$D>\"\n"
                FAILURE=true
                continue
            else
                R "413 vas_host_services entry for joined domain"
            fi
# * kinit results
# First, kdestroy just in case, so anything left in the credentials cache isn't
# interfearing with the testing, which occasionally might fix things, but not
# sure how to check/report that, so will jsut deal with it if it happens.
            KRB5CCNAME=/tmp/_vas_status_ccache_$$
            export KRB5CCNAME
            $VAS kdestroy >/dev/null 2>&1
            SET_CCNAME=true
            RESULTS2="`$VAS -d5 -k $KEYTAB kinit $KRB5NAME 2>&1`"
            RVAL=$?
            RESULTS="`printf \"%s\" \"$RESULTS2\" | tr '\"\n' '~ '`"
            if [ $RVAL -ne 0 ] ; then
                ADFAILURE=true
                FAILURE=true
#    414 SAS can find DC to communicate with
                echo "$RESULTS" | grep 1765328228 >/dev/null
                if [ $? -eq 0 ] ; then
                    $NUM && printf "NUMBER:414\n"
                    $CSV || printf "FAILURE: 414 vas_host_services Unable to find a DC to contact for principal <$KRB5NAME>.\n"
                    $CSV && printf "\"STATUS\",414,\"vas_host_services contacting DC\",2,\"vas_host_services Unable to find a DC to contact for principal <$KRB5NAME>\"\n"
                    return 0
                fi

#    415 service exists in AD
                echo "$RESULTS" | grep 1765328378 >/dev/null
                if [ $? -eq 0 ] ; then
                    $NUM && printf "NUMBER:415\n"
                    $CSV || printf "FAILURE: 415 vas_host_services SAS cannot find principal <$KRB5NAME> in AD\n"
                    $CSV && printf "\"STATUS\",415,\"vas_host_services service exists\",2,\"vas_host_services SAS cannot find principal <$KRB5NAME> in AD\"\n"
                    return 0
                fi

#    416 timesync
                echo "$RESULTS" | grep 1765328347 >/dev/null
                if [ $? -eq 0 ] ; then
                    $NUM && printf "NUMBER:416\n"
                    $CSV || printf "FAILURE: 416 vas_host_services out of time sync with DC for <$KRB5NAME>.\n"
                    $CSV && printf "\"STATUS\",416,\"vas_host_services timesync\",2,\"vas_host_services out of time sync with DC for <$KRB5NAME>\"\n"
                    return 0
                fi

#    417 right password
                echo "$RESULTS" | grep 1765328360 >/dev/null
                if [ $? -eq 0 ] ; then
                    $NUM && printf "NUMBER:417\n"
                    $CSV || printf "FAILURE: 417 vas_host_services Password in file <$KEYTAB> for principal <$KRB5NAME> is not correct.\n"
                    $CSV && printf "\"STATUS\",417,\"vas_host_services correct password\",2,\"vas_host_services Password in file <$KEYTAB> for principal <$KRB5NAME> is not correct\"\n"
                    return 0
                fi

#    418 service usable
                echo "$RESULTS" | grep 1765328366 >/dev/null
                if [ $? -eq 0 ] ; then
                    $NUM && printf "NUMBER:418\n"
                    $CSV || printf "FAILURE: 418 vas_host_services principal <$KRB5NAME> is unusable(revoked credentials).\n"
                    $CSV && printf "\"STATUS\",418,\"vas_host_services check credentials\",2,\"vas_host_services principal <$KRB5NAME> is unusable(revoked credentials)\"\n"
                    return 0
                fi

#    419 DES is set, but no entries ( KRB5KDC_ERR_PREAUTH_REQUIRED )
                echo "$RESULTS" | grep 1765328359 >/dev/null
                if [ $? -eq 0 ] ; then
                    $NUM && printf "NUMBER:419\n"
                    $CSV || printf "FAILURE: 419 vas_host_services principal <$KRB5NAME> is requiring unknown key type.\n"
                    $CSV && printf "\"STATUS\",419,\"vas_host_services preauth fail\",2,\"vas_host_services principal <$KRB5NAME> is requiring unknown key type\"\n"
                    return 0
                fi

#    420 ( Misc kinit error, not one of the above known ones )
                $NUM && printf "NUMBER:420\n"
                $CSV || printf "FAILURE: 420 vas_host_services For principal <$KRB5NAME> unknown vastool kinit result/error: <$RVAL><$RESULTS>.\n"
                $CSV && printf "\"STATUS\",420,\"vas_host_services unknown error\",2,\"vas_host_services For principal <$KRB5NAME> unknown vastool kinit result/error: <$RVAL><$RESULTS>\"\n"
            else
                R "414 vas_host_services contacting DC"
                R "415 vas_host_services service exists"
                R "416 vas_host_services timesync"
                R "417 vas_host_services correct password"
                R "418 vas_host_services check credentials"
                R "419 vas_host_services preauth fail"
                R "420 vas_host_services unknown errors"
            fi

#    421 If use-for-auth, that auth as a service princ works
            if [ "$USEFORAUTH" = "true" ] ; then
                OUT="`$VAS -d5 -u $KRB5NAME -k $KEYTAB auth -S $KRB5NAME -k $KEYTAB 2>&1`"
                if [ $? -ne 0 ] ; then
                    $NUM && printf "NUMBER:421\n"
                    $CSV || printf "FAILURE: 421 vas_host_services use-for-auth for principal <$KRB5NAME> for domain <$D> failed with <$OUT>.\n"
                    $CSV && printf "\"STATUS\",421,\"vas_host_services check use-for-auth\",2,\"vas_host_services  use-for-auth for principal <$KRB5NAME> for domain <$D> failed with <$OUT>\"\n"
                    FAILURE=true
                    continue
                else
                    R "410 vas_host_services check use-for-auth"
                fi
            fi
        done
    fi

}

t500 ()
{
    $DEBUG && set -x
    $ADFAILURE && return 0
    $QUICK || if [ ! -z "$COMPUTERFQDN" -a ! -z "$COMPUTERNAME" ] ; then
#   501 Computer account has valid SPNs.
        ADSPNs="`echo \"$CATTRS\" | grep \"^servicePrincipalName\" | grep -v \"cifs/$COMPUTERFQDN\" | grep -v \"cifs/$COMPUTERNAME\" | cut -d: -f2- | sed 's/^[ 	]*//' | tr '\n' ' '`"
        EXPECTEDSPNS="host/$COMPUTERFQDN host/$COMPUTERNAME"
        MISSINGSPN=0
        for spn in $EXPECTEDSPNS ; do
            echo $ADSPNs | grep -i "$spn" >/dev/null
            if [ $? -ne 0 ] ; then
                $CSV || printf "WARNING: Did not find SPN <$spn> in list of SPNs <$ADSPNs>\n"
                $CSV && printf "\"STATUS\",501,\"SPN checks\",1,\"Computer object missing SPN <$spn>, current SPNs: <$ADSPNs>\"\n"
                MISSINGSPN=1
            fi
        done

        if [ $MISSINGSPN -eq 1 ] ; then
            $NUM && printf "NUMBER:501\n"
            $CSV || printf "WARNING: 501 The computer object is missing servicePrincipalName entry(s).\n"
            $CSV && printf "\"STATUS\",501,\"SPN checks\",1,\"The computer object is missing servicePrincipalName entry(s).\"\n"
            WARNING=true
        else
            R "501 host/ has servicePrincipalName"
        fi

#   502 host.keytab contains matching entries for each SPN in AD.
        KEYTABSPNS="`$VAS ktutil list | grep -v '^Vno' | awk '{print $3}' | sort | uniq | cut -d@ -f1 | grep -iv \"^$COMPUTERNAME\" | grep -iv \"cifs/\" | grep -v '^[ 	]*$' | tr '\n' ' '`"
        MISSINGSPN=0
        for spn in $ADSPNs; do
            case $spn in
                as/*)
                    # ignore this SPN
                    ;;
                *)
                    echo $KEYTABSPNS | grep -i "$spn" >/dev/null
                    if [ $? -ne 0 ] ; then
                        $CSV || printf "WARNING: Did not find AD SPN <$spn> in list of keytab SPNs <$KEYTABSPNS>\n"
                        $CSV && printf "\"STATUS\",502,\"SPN checks\",1,\"Keytab missing SPN computer object has, keytab: <$KEYTABSPNS>, object SPN: <$spn>\"\n"
                        MISSINGSPN=1
                    fi
                    ;;
            esac
        done

        if [ $MISSINGSPN -eq 1 ] ; then
            $NUM && printf "NUMBER:502\n"
            $CSV || printf "WARNING: 502 host.keytab is missing entries for AD SPN entries.\n"
            $CSV && printf "\"STATUS\",502,\"host.keytab checks\",1,\"host.keytab is missing entries for AD SPN entries.\"\n"
            WARNING=true
        else
            R "502 host.keytab has entries for each servicePrincipalName"
        fi

#   503 SPNs in AD match each entry in host.keytab.
        MISSINGSPN=0
        for spn in $KEYTABSPNS; do
            echo $ADSPNs | grep -i "$spn" >/dev/null
            if [ $? -ne 0 ] ; then
                $CSV || printf "WARNING: Did not find keytab SPN <$spn> in list of AD SPNs <$ADSPNs>\n"
                $CSV && printf "\"STATUS\",503,\"SPN checks\",1,\"Keytab has SPN that computer object does not: <$spn>\"\n"
                MISSINGSPN=1
            fi
        done

        if [ $MISSINGSPN -eq 1 ] ; then
            $NUM && printf "NUMBER:503\n"
            $CSV || printf "WARNING: 503 host.keytab has SPN entries that are not in AD.\n"
            $CSV && printf "\"STATUS\",503,\"host.keytab checks\",1,\"host.keytab has SPN entries that are not in AD.\"\n"
            WARNING=true
        else
            R "503 host.keytab has no extra entries"
        fi

        OUT2="`$VAS -u host/ auth -S host/$COMPUTERFQDN 2>&1`"
        RVAL=$?
        OUT="`printf \"%s\" \"$OUT2\" | tr '\"\n' '~ '`"
        if [ $RVAL -ne 0 ] ; then
#   504 auth -S host/$FQDN returns KRB5KDC_ERR_S_PRINCIPAL_UNKNOWN, duplicate.
            echo "$OUT" | grep 1765328377 >/dev/null
            if [ $? -eq 0 ] ; then
                $NUM && printf "NUMBER:504\n"
                $CSV || printf "WARNING: 504 AD is not able to find the specified SPN <host/$COMPUTERFQDN>.\n"
                $CSV && printf "\"STATUS\",504,\"SPN checks\",1,\"Query for SPN <host/$COMPUTERFQDN> failed\"\n"
                WARNING=true
            else
#   505 auth -S host/$FQDN fails.
                $NUM && printf "NUMBER:505\n"
                $CSV || printf "FAILURE: 505 Unrecognized auth result/error <$RVAL><$OUT>.\n"
                $CSV && printf "\"STATUS\",505,\"SPN checks\",2,\"Unrecognized result/error <$RVAL><$OUT>\"\n"
                FAILURE=true
            fi
        else
            R "504 vastool auth can find fqdn"
            R "505 no failure with auth"
        fi
    fi

    if [ ! -f /var/opt/quest/vas/.disable_starling -a -f "$TWOFABIN" -a -f "$TWOFAINFO" -a -f "$TWOFAFILE" ] ; then
        # Make sure the binary even runs
        $TWOFABIN -version >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            $CSV || printf "INFO: 506 $TWOFABIN failed to execute properly\n"
            R "506 Starling check skipped"
        else
            /opt/quest/libexec/vas/starling -check >/dev/null 2>&1
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:506\n"
                $CSV || printf "WARNING: 506 Starling check failed.\n"
                $CSV && printf "\"STATUS\",506,\"Starling check\",1,\"Starling check failed\"\n"
                WARNING=true
            else
                R "506 Starling enabled"
            fi
        fi
    else
        R "506 Starling check skipped"
    fi
}

t622 ()
{
#    622.
    if [ -f /usr/bin/dscl ] ; then
        /usr/bin/dscl /Local/Default -list /Groups/$1 >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            NETACCOUNT="`/usr/bin/dscl /Local/Default -read /Groups/netaccounts GeneratedUID | sed 's/GeneratedUID: //g'`"
            NESTEDGROUPS="`/usr/bin/dscl /Local/Default -read /Groups/$1 NestedGroups 2>&1 | sed 's/NestedGroups: //g'`"
            FINALRESULT="`echo \"${NESTEDGROUPS}\" | grep \"${NETACCOUNT}\"`"
            if [ "$NESTEDGROUPS" != "$FINALRESULT" ] ; then
                $NUM && printf "NUMBER:622\n"
                $CSV || echo "FAILURE: 622 Network users cannot login through $2."
                $CSV && printf "\"STATUS\",622,\"network user logon check\",2,\"Network users cannot login through $2.\"\n"
                FAILURE=true
            fi
        fi
    fi
}

t600 ()
{
    $DEBUG && set -x
    BADPERMS1=0
    BADPERMS2=0
    DP="drwxr-xr-x(755)"
    for D in /etc/opt/quest /etc/opt/quest/vas /var/opt/quest /var/opt/quest/vas /var/opt/quest/vas/vasd ; do
        if [ -d $D ] ; then
            $LS -Llad $D | cut -c2,3,4,5,7,8,10 | grep "\-" >/dev/null
            if [ $? -eq 0 ] ; then
                BADPERMS1=1
                $CSV || printf "FAILURE: 601 Missing needed permissions on <$D>, currently: <`$LS -Llad $D | awk '{print $1}'`> should be:<$DP>.\n"
                $CSV && printf "\"STATUS\",601,\"Permission checks\",2,\"Missing permissions on <$D>, at <`$LS -Llad $D | awk '{print $1}'`> should be:<$DP>\"\n"
            fi
            $LS -Llad $D | cut -c9 | grep "\-" >/dev/null
            if [ $? -ne 0 ] ; then
                BADPERMS2=1
                $CSV || printf "FAILURE: 602 'other' has write permissions on: <$D><`$LS -Llad $D | awk '{print $1}'`> That permission should be removed.\n"
                $CSV && printf "\"STATUS\",602,\"Permission checks\",2,\"'other' has write permissions on <$D><`$LS -Llad $D | awk '{print $1}'`>\"\n"
            fi
       fi
    done

    DP="dr-xr-xr-x(555)"
    for D in / /etc /etc/opt /etc/opt/quest /opt /opt/quest /var /var/opt /var/opt/quest ; do
        if [ -d $D ] ; then
            $LS -Llad $D | cut -c2,4,5,7,8,10 | grep "\-" >/dev/null
            if [ $? -eq 0 ] ; then
                BADPERMS1=1
                $CSV || printf "FAILURE: 601 Missing needed permissions on <$D>, currently: <`$LS -Llad $D | awk '{print $1}'`> should be:<$DP>.\n"
                $CSV && printf "\"STATUS\",601,\"Permission checks\",2,\"Missing permissions on <$D>, at <`$LS -Llad $D | awk '{print $1}'`> should be:<$DP>\"\n"
            fi
            $LS -Llad $D | cut -c9 | grep "\-" >/dev/null
            if [ $? -ne 0 ] ; then
                BADPERMS2=1
                $CSV || printf "FAILURE: 602 'other' has write permissions on: <$D><`$LS -Llad $D | awk '{print $1}'`> That permission should be removed.\n"
                $CSV && printf "\"STATUS\",602,\"Permission checks\",2,\"'other' has write permissions on on <$D><`$LS -Llad $D | awk '{print $1}'`>\"\n"
            fi
       fi
    done

    DP="drwxrwxrw(x|t)"
    for D in /tmp ; do
        if [ -d $D ] ; then
            $LS -Llad $D | cut -c2-10 | grep "\-" >/dev/null
            if [ $? -eq 0 ] ; then
                BADPERMS1=1
                $CSV || printf "FAILURE: 601 Missing needed permissions on <$D>, currently: <`$LS -Llad $D | awk '{print $1}'`> should be:<$DP>.\n"
                $CSV && printf "\"STATUS\",601,\"Permission checks\",2,\"Missing permissions on <$D>, at <`$LS -Llad $D | awk '{print $1}'`> should be:<$DP>\"\n"
            fi
       fi
    done

    OVRDUFILE="`get_setting userOvrdFile`"
    if [ -z "$OVRDUFILE" ] ; then
        OVRDUFILE=/etc/opt/quest/vas/user-override
    fi
    OVRDGFILE="`get_setting groupOvrdFile`"
    if [ -z "$OVRDGFILE" ] ; then
        OVRDGFILE=/etc/opt/quest/vas/group-override
    fi

    FP="-rw-r--r--(644)"
    for F in $OVRDUFILE $OVRDGFILE $VASCONF $VGPCONF $MISCDB $IDENTDB $UALLOW $UDENY ; do
        if [ -f $F ] ; then
            $LS -Lla $F | cut -c2,3,5,8 | grep "\-" >/dev/null
            if [ $? -eq 0 ] ; then
                BADPERMS1=1
                $CSV || printf "FAILURE: 601 Missing needed permissions on <$F>, currently: <`$LS -Lla $F | awk '{print $1}'`> should be: <$FP>.\n"
                $CSV && printf "\"STATUS\",601,\"Permission checks\",2,\"Missing permissions on <$F>, at <`$LS -Lla $F | awk '{print $1}'`> should be:<$FP>\"\n"
            fi
            $LS -Lla $F | cut -c9 | grep "\-" >/dev/null
            if [ $? -ne 0 ] ; then
                BADPERMS2=1
                $CSV || printf "FAILURE: 602 'other' has write permissions on: <$F>(`$LS -Lla $F | awk '{print $1}'`) That permission should be removed.\n"
                $CSV && printf "\"STATUS\",602,\"Permission checks\",2,\"'other' has write permissions on on <$F><`$LS -Lla $F | awk '{print $1}'`>\"\n"
            fi
        fi
    done

    if [ -f $MISCDB ] ; then
        MappedFile="`get_setting userMappings`"
    fi

#   601 File/directory permissions. Not enough.
    if [ $BADPERMS1 -eq 1 ] ; then
        $NUM && printf "NUMBER:601\n"
        FAILURE=true
    else
        R "601 file permissions ok (not enough)"
    fi

#   602 File/directory permissions. Too much.
    if [ $BADPERMS2 -eq 1 ] ; then
        $NUM && printf "NUMBER:602\n"
        FAILURE=true
    else
        R "602 file permissions ok (too much)"
    fi

    BADPERMS1=0
    BADPERMS2=0
    FP="-r--r--r--(444)"
    for F in /etc/netsvc.cfg /etc/nsswitch.conf /etc/resolv.conf /etc/hosts /etc/passwd /etc/group /usr/lib/security/methods.cfg /etc/pam.conf /etc/pam.d/system-auth /etc/pam.d/common-auth /opt/quest/libexec/vas/scripts/vas_status.sh /opt/quest/bin/vastool /opt/quest/bin/.vastool  ; do
        file=
#        if [ -h $F -a FALSE ] ; then
#            f="`$LS -Lla $F | cut -d\> -f2 | tr -d ' '`"
#            if [ "`echo $f | cut -c1`" = "." ] ; then
#                file="`dirname $F`/$f"
#            else
#                file=$f
#            fi
#        elif [ -f $F ] ; then
            file=$F
#        fi

        if [ -f "$file" ] ; then
            $LS -laL $file | cut -c2,5,8 | grep "\-" >/dev/null
            if [ $? -eq 0 ] ; then
                BADPERMS1=1
                $CSV || printf "FAILURE: 606 Missing needed permissions on <$file>, currently: <`$LS -Lla $file | awk '{print $1}'`> should be at least: <$FP>.\n"
                $CSV && printf "\"STATUS\",606,\"Permission checks\",2,\"Missing permissions on <$file>, at <`$LS -Llad $file | awk '{print $1}'`> should be: <$FP>\"\n"
            fi
            $LS -laL $file | cut -c9 | grep "\-" >/dev/null
            if [ $? -ne 0 ] ; then
                BADPERMS2=1
                $CSV || printf "FAILURE: 607 'other' has write permissions on: <$file>(`$LS -Lla $file | awk '{print $1}'`) That permission should be removed.\n"
                $CSV && printf "\"STATUS\",607,\"Permission checks\",2,\"'other' has write permissions on on <$file><`$LS -Lla $file | awk '{print $1}'`>\"\n"
            fi
        fi
    done

#   606 System file permissions. Not enough.
    if [ $BADPERMS1 -eq 1 ] ; then
        $NUM && printf "NUMBER:606\n"
        FAILURE=true
    else
        R "606 system file permissions ok (not enough)"
    fi

#   607 System file permissions. Too much.
    if [ $BADPERMS2 -eq 1 ] ; then
        $NUM && printf "NUMBER:607\n"
        FAILURE=true
    else
        R "607 system file permissions ok (too much)"
    fi

    $CRITICAL_FAILURE && return

#   603 /etc/nsswitch.conf contains vas3. ( check for map entries ).
    if [ -z "$SKIP_NSS_TESTS" ] || [ "$SKIP_NSS_TESTS" -ne 1 ]; then
        if [ -f /etc/sia/matrix.conf ] ; then
            cut -d'#' -f1 < /etc/sia/matrix.conf | grep "vas[34]" >/dev/null
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:603\n"
                $CSV || printf "FAILURE: 603 /etc/sia/matrix.conf does not appear to be configured to use SAS.\n"
                $CSV && printf "\"STATUS\",603,\"matrix.conf checks\",2,\"/etc/sia/matrix.conf does not appear to be configured to use SAS\"\n"
                FAILURE=true
            else
                R "603 /etc/sia/matrix.conf configured to use SAS"
            fi
        elif [ -f /etc/nsswitch.conf ] && [ `uname` != 'Darwin' ] && [ `uname` != 'AIX' ] ; then
            cut -d'#' -f1 < /etc/nsswitch.conf | grep "vas[34]" >/dev/null
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:603\n"
                if [ -z "$MappedFile" ] ; then
                    $CSV || printf "FAILURE: 603 /etc/nsswitch.conf does not appear to be configured to use SAS.\n"
                    $CSV && printf "\"STATUS\",603,\"nsswitch.conf checks\",2,\"/etc/nsswitch.conf does not appear to be configured to use SAS\"\n"
                    FAILURE=true
                else
                    $CSV || printf "INFO: 603 /etc/nsswitch.conf does not appear to be configured to use SAS\n"
                fi
            else
                R "603 /etc/nsswitch.conf configured to use SAS"
            fi
        fi
    fi

#   604 Relevent PAM configuraiton file contains at least one pam_vas3 line.
    PAM_GOOD=true
    for file in /etc/pam.d/system-auth /etc/pam.d/common-auth ; do
        if [ -f $file ] ; then
            grep "pam_vas[34]" $file >/dev/null
            if [ $? -ne 0 ] ; then
                # Double check the -ac file
                if [ -f /etc/pam.d/system-auth-ac ] ; then
                    grep "pam_vas[34]" /etc/pam.d/system-auth-ac >/dev/null
                    if [ $? -eq 0 ] ; then
                        break
                    fi
                fi
                $NUM && printf "NUMBER:604\n"
                $CSV || printf "FAILURE: 604 $file does not appear to be configured to use SAS.\n"
                $CSV && printf "\"STATUS\",604,\"pam checks\",2,\"$file does not appear to be configured to use SAS\"\n"
                FAILURE=true
                PAM_GOOD=false
            fi
            break
        fi
    done
    if [ -f /etc/pam.conf -a ! -d /etc/pam.d ] ; then
        grep "pam_vas[34]" /etc/pam.conf >/dev/null
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:604\n"
            $CSV || printf "FAILURE: 604 /etc/pam.conf does not appear to be configured to use SAS.\n"
            $CSV && printf "\"STATUS\",604,\"pam checks\",2,\"/etc/pam.conf does not appear to be configured to use SAS\"\n"
            FAILURE=true
            PAM_GOOD=false
        fi
    fi
# checks to see if try_disauth_first is set and warns that it is
    for file in /etc/pam.d/system-auth /etc/pam.d/common-auth /etc/pam.d/db2 ; do
        if [ -f $file ] ; then
            cut -d'#' -f1 < $file | grep "try_disauth_first" >/dev/null
            if [ $? -eq 0 ] ; then
                         $NUM && printf "NUMBER:604\n"
                         $CSV || printf "INFO: 604 $file has try_disauth_first set. We recommend removing this setting.\n"
                         break
           fi
        fi
    done
    if [ -f /etc/pam.conf -a ! -d /etc/pam.d ] ; then
        cut -d'#' -f1 < /etc/pam.conf | grep "try_disauth_first" >/dev/null
        if [ $? -eq 0 ] ; then
                $NUM && printf "NUMBER:604\n"
                $CSV || printf "INFO: 604 $file has try_disauth_first set. We recommend removing this setting.\n"
        fi
    fi
    $PAM_GOOD && R "604 pam configured to use SAS"

#   605 AIX: /usr/lib/security/methods.cfg contains VAS
    AIX_GOOD=false
    METHODSCFG=good
    for file in /etc/security/user /usr/lib/security/methods.cfg ; do
        if [ -f $file ] ; then
            grep "VAS" $file >/dev/null
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:605\n"
                $CSV || printf "FAILURE: 605 $file does not appear to be configured to use SAS.\n"
                $CSV && printf "\"STATUS\",605,\"lam checks\",2,\"$file does not appear to be configured to use SAS\"\n"
                FAILURE=true
                AIX_GOOD=false
                METHODSCFG=bad
            else
                AIX_GOOD=true
            fi
        fi
    done
    $AIX_GOOD && R "605 AIX files configured to use SAS"

    if $PAM_GOOD ; then
        $QUICK || if [ -z "$SKIP_PAM_SERVICES" ] ; then
        #   608 pam_vas for each pam service.
            if [ -f /etc/pam.d/common-auth ] ; then
                pam_suse
            elif [ -f /etc/pam.d/system-auth ] ; then
                pam_redhat
            elif [ -d /etc/pam.d ] ; then
                # Only old Suse machines it seems don't have the other methods.
                # -- Correction, OSX machines are configured with way as well
                pam_suse
            else
                pam_conf
            fi
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:608\n"
                WARNING=true
            else
                R "608 each pam service configured to use SAS"
            fi
        fi
    fi

#    609 nss links exist.
    nss_link_tests
    if [ $? -ne 0 -a -z "$MappedFile" ] ; then
        $NUM && printf "NUMBER:609\n"
        FAILURE=true
    else
        R "609 nss links ok"
    fi


#    610 pam links exist.
    pam_link_tests
    if [ $? -ne 0 ] ; then
        $NUM && printf "NUMBER:610\n"
        FAILURE=true
    else
        R "610 pam links ok"
    fi

#    612 AIX: /etc/security/user doesn't have default registry entry
    if [ -f /etc/security/user ] ; then
        P="`lssec -f /etc/security/user -s default -a registry | cut -d= -f2`"
        if [ -n "$P" ] ; then
            $NUM && printf "NUMBER:612\n"
            $CSV || echo "FAILURE: 612 /etc/security/user has default: registry setting <$P>"
            $CSV && printf "\"STATUS\",612,\"lam checks\",2,\"/etc/security/user has default: registry setting\"\n"
            FAILURE=true
        else
            R "612 AIX: /etc/security/user doesn't have default registry entry"
        fi
    fi
#    618 AIX: default rlogin = false isn't set.
    if [ -f /etc/security/user ] ; then
        P="`lssec -f /etc/security/user -s default -a rlogin | cut -d= -f2 | tr $UPPER $LOWER `"
        if [ -n "$P" -a "$P" = "false" ] ; then
            $NUM && printf "NUMBER:618\n"
            $CSV || echo "WARNING: 618 /etc/security/user has default: rlogin setting <$P>"
            $CSV && printf "\"STATUS\",618,\"lam checks\",1,\"/etc/security/user has default: rlogin setting\"\n"
            WARNING=true
        else
            R "618 AIX: /etc/security/user doesn't have rlogin = false registry entry"
        fi
    fi

#    613 AIX: methods.cfg is ok
    if [ "x$METHODSCFG" = "xgood" -a -f /usr/lib/security/methods.cfg ] ; then
        lsuser -R VAS "no such user" 2>&1 1>/dev/null | grep VAS >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:613\n"
            $CSV || echo "CRITICAL: 613 VAS method cannot be loaded, /usr/lib/security/methods.cfg invalid"
            $CSV && printf "\"STATUS\",613,\"lam checks\",3,\"VAS repository cannot be loaded, /usr/lib/security/methods.cfg invalid\"\n"
            CRITICAL_FAILURE=true
            FAILURE=true
        else
            R "613 AIX: methods.cfg is ok, SAS can load"
        fi
    fi


    BIGFILE=false
# NOTE: /var/run/btmpx doens't appear to be used by any supported OS, added strictly to have a file to test with.
    F="/var/adm/btmp /var/adm/btmps /var/adm/utmp /var/adm/utmpx /var/adm/wtmp /var/adm/wtmps /var/adm/wtmpx /var/log/btmp /var/log/wtmp /var/run/utmp /var/run/utmpx /var/run/btmpx"
    for file in $F ; do
        if [ -f $file ] ; then
            SZ="`$LS -Llad $file | awk '{print $5}'`"
            if [ "$SZ" -ge 250000000 ] ; then
                $NUM && printf "NUMBER:614\n"
                $CSV || echo "WARNING: 614 File <$file> is larger than 250MB <$SZ>"
                $CSV && printf "\"STATUS\",614,\"file size checks\",1,\"File <$file> is larger than 250MB: <${SZ}> bytes\"\n"
                WARNING=true
                BIGFILE=true
            fi
        fi
    done
    $BIGFILE || R "614 'last' files not too big"

#   615 warn on /etc/irs.conf vas if netgroup-mode isn't set NSS.
    if [ -f /etc/irs.conf ] ; then
        grep -i  "^[ 	]*netgroup[ 	]*vas" /etc/irs.conf >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            NETGROUP="`get_setting netgroupMode`"
            if [ "$NETGROUP" = "NSS" ] ; then
                R "615 AIX: /etc/irs.conf netgroup vas"
            else
                $NUM && printf "NUMBER:615\n"
                $CSV || echo "WARNING: 615 /etc/irs.conf contains netgroup vas"
                $CSV && printf "\"STATUS\",615,\"lam checks\",1,\"/etc/irs.conf contains netgroup vas\"\n"
                WARNING=true
            fi
        else
            R "615 AIX: /etc/irs.conf netgroup vas"
        fi
    else
        R "615 AIX: /etc/irs.conf netgroup vas"
    fi
#   616 check for read-only /var/opt/quest/vas/vasd
    F=/var/opt/quest/vas/vasd/.test_readable.$$
    rm -f $F >/dev/null 2>&1
    echo "not full" >$F 2>/dev/null
    grep "not full" $F >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:616\n"
            $CSV || echo "FAILURE: 616 /var/opt/quest/vas/vasd appears read-only"
            $CSV && printf "\"STATUS\",616,\"writable directory check\",2,\"Directory /var/opt/quest/vas/vasd appears read-only\"\n"
            FAILURE=true
    else
        R "616 Read-only /var/opt/quest/vas/vasd"
        rm -f $F >/dev/null 2>&1
    fi
#    617 dns not slow
    SKIP=false
    # If there is no resolv.conf file or AD has already failed, skip this test.
    if [ "$ADFAILURE" = "true" -o ! -f /etc/resolv.conf ] ; then
        SKIP=true
    else
        case $PLATFORM in
            OSX*)

                ;;
            AIX*)
                grep "^hosts" /etc/netsvc.conf >/dev/null 2>&1
                if [ $? -eq 0 ] ; then
                    grep "^hosts.*bind" /etc/netsvc.conf >/dev/null 2>&1
                    if [ $? -ne 0 ] ; then
                        SKIP=true
                        $CSV || printf "INFO: 617 dns does not appear to be in use.\n"
                    fi
                fi
                ;;
            *)
                if [ -f /etc/nsswitch.conf ] ; then
                    grep "^hosts:.*dns" /etc/nsswitch.conf >/dev/null 2>&1
                    if [ $? -ne 0 ] ; then
                        SKIP=true
                        $CSV || printf "INFO: 617 dns does not appear to be in use.\n"
                    fi
                fi
                ;;
        esac
    fi

    if [ "$SKIP" = "false" ] ; then
        S="`$VAS info servers -s \* | head -2 | tail -1 | grep -v '^Server'`"
        if [ -z "$S" ] ; then
            $NUM && printf "NUMBER:617\n"
            $CSV || printf "FAILURE: 617 dns speed, vastool info servers query failed.\n"
            $CSV && printf "\"STATUS\",617,\"dns speed check\",2,\"vastool info servers failed to list server\"\n"
            FAILURE=true
        else
            ST=`GetTime`
    # Silly, but some of our build machines failed on this when they are in the middle
    # of a build when this runs, so make 3 calls and if they all take 1 second+ it will
    # trip this test.
            nslookup $S >/dev/null 2>&1
            nslookup $S >/dev/null 2>&1
            nslookup $S >/dev/null 2>&1
            D=`GetTimeDiff $ST`
            if [ $D -gt 2 ] ; then
                $NUM && printf "NUMBER:617\n"
                $CSV || printf "WARNING: 617 dns speed, nslookup query on <$S> took <$D> seconds\n"
                $CSV && printf "\"STATUS\",617,\"dns speed check\",1,\"nslookup query on <$S> took <$D> seconds\"\n"
                WARNING=true
             else
                 R "617 dns not slow"
             fi
        fi
    fi
#    619 & 620.
    if [ `uname` = "Darwin" ] ; then
        if [ $R -gt 10 ] ; then
            F="/Library/Preferences/OpenDirectory/Configurations/Search.plist /Library/Preferences/OpenDirectory/Configurations/Contacts.plist"
        else
            F="/Library/Preferences/DirectoryService/SearchNodeConfig.plist /Library/Preferences/DirectoryService/ContactsNodeConfig.plist"
        fi
        for file in $F ; do
            if [ -f $file ] ; then
                grep -e "Default search policy" -e "Search Node Custom Path Array" $file >/dev/null 2>&1
                if [ $? -eq 0 ] ; then
                    node="default"
                else
                    node="contact"
                fi
				tmpfile="/var/tmp/${node}.$$"
				cp $file $tmpfile
                plutil -convert xml1 $tmpfile
                grep "VAS" $tmpfile >/dev/null 2>&1
                if [ $? -ne 0 ] ; then
                    $NUM && printf "NUMBER:619\n"
                    $CSV || printf "FAILURE: 619 The $node search policy is NOT configure for SAS!\n"
                    $CSV && printf "\"STATUS\",619,\"directory services check\",2,\"The $node search policy is NOT configured for SAS!\"\n"
                    FAILURE=true
                fi
                for directory in "Active Directory" "LDAPv3" ; do
                    grep "$directory" $tmpfile >/dev/null 2>&1
                    if [ $? -eq 0 ] ; then
                        if [ "$directory" = "LDAPv3" ] ; then
                            directory="Open Directory"
                        fi
                        $NUM && printf "NUMBER:620\n"
                        $CSV || printf "WARNING: 620 The $node search policy is configured to include $directory.\n"
                        $CSV && printf "\"STATUS\",620,\"directory services check\",1,\"The $node search policy is configured to include $directory.\"\n"
                        WARNING=true
                    fi
                done
				rm $tmpfile
            fi
        done
    fi

    file=/var/opt/quest/vas/vasd/cached_attributes.xml
    if [ -f $file ] ; then
        SZ="`$LS -Llad $file | awk '{print $5}'`"
        if [ "$SZ" -eq 0 ] ; then
            $NUM && printf "NUMBER:621\n"
            $CSV || echo "FAILURE: 621 File <$file> is 0-bytes, re-cache schema"
            $CSV && printf "\"STATUS\",621,\"file size checks\",2,\"File <$file> is 0-bytes, re-cache schema\"\n"
            FAILURE=true
        fi
    fi


    t622 "com.apple.access_loginwindow" "login window"
    t622 "com.apple.access_ssh" "ssh"

    file=/var/opt/quest/vgp/extensions
    if [ -f $file ] ; then
        SZ="`$LS -Llad $file | awk '{print $5}'`"
        if [ "$SZ" -eq 0 ] ; then
            $NUM && printf "NUMBER:623\n"
            $CSV || echo "FAILURE: 623 File <$file> is 0-bytes, not all policies will apply"
            $CSV && printf "\"STATUS\",623,\"file size checks\",2,\"File <$file> is 0-bytes\"\n"
            FAILURE=true
        else
            R "623 <$file> size check"
        fi
    fi

    case `uname -s` in
      AIX)
        MAX_LOGNAME=`lsattr -O -E -l sys0 -a max_logname | tail -1`
        MAX_CACHE_NAME=`printf ".timeout 5000\nselect max(length(pwnam)) from pwent where accessAllowed='Y';\n.q\n" |$SQL3 $IDENTDB`
        # The value from max_logname is (length + 1), when set to 9 the actual max length is 8.
        if [ ! -z "$MAX_CACHE_NAME" ] && [ $MAX_LOGNAME -le $MAX_CACHE_NAME ] ; then
            $NUM && printf "NUMBER:624\n"
            $CSV || echo "WARNING: 624 sys0 value max_logname <$MAX_LOGNAME> doesn't allow all cached users to log in"
            $CSV && printf "\"STATUS\",624,\"AIX max_logname length doesn't allow all users to log in\",1,\"max_logname <$MAX_LOGNAME> is less or equal to longest user's name length <$MAX_CACHE_NAME>\"\n"
            WARNING=true
        fi
      ;;
    esac

    id daemon >/dev/null 2>&1
    if [ "$?" -ne 0 ] ; then
        $NUM && printf "NUMBER:625\n"
        $CSV || echo "FAILURE: 625 User account <daemon> doesn't exist"
        $CSV && printf "\"STATUS\",625,\"daemon exists\",2,\"User daemon doesn't exists\"\n"
        FAILURE=true
    else
        R "625 daemon exists"
    fi


    file=/etc/opt/quest/vas/vasipc_timeout
    if [ -f $file ] ; then
        SZ="`$LS -Llad $file | awk '{print $5}'`"
        if [ "$SZ" -eq 0 ] ; then
            $NUM && printf "NUMBER:626\n"
            $CSV || echo "FAILURE: 626 File <$file> is 0-bytes, vascache-ipc-timeout is at default(10)"
            $CSV && printf "\"STATUS\",626,\"file size checks\",2,\"File <$file> is 0-bytes\"\n"
            FAILURE=true
        else
            R "626 <$file> size check"
        fi
    fi

    if [ "x$KRB5_KTNAME_SAVE" != "xKRB5_KTNAME=" -o "x$KRB5_CONFIG_SAVE" != "xKRB5_CONFIG=" ] ; then
        OUT=""
        if [ "x$KRB5_KTNAME_SAVE" != "xKRB5_KTNAME=" ] ; then
            OUT="$KRB5_KTNAME_SAVE"
        fi
        if [ "x$KRB5_CONFIG_SAVE" != "xKRB5_CONFIG=" ] ; then
            if [ -z "$OUT" ] ; then
                OUT="$KRB5_CONFIG_SAVE"
            else
                OUT="$OUT $KRB5_CONFIG_SAVE"
            fi
        fi
        $NUM && printf "NUMBER:627\n"
        $CSV || printf "INFO: 627 KRB5 environmental variable(s) set: <$OUT>\n"
    else
        R "627: no KRB5_* environmental variables set"
    fi


    if [ -x /usr/bin/authselect ] ; then
        OUT="`/usr/bin/authselect check`"
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:628\n"
            $CSV || printf "INFO: 628 authselect check of setup: <`/usr/bin/authselect current --raw`> failed: <$OUT>\n"
        else
            R "628: authselect check"
        fi
    fi

    if [ -d /etc/pam.d ] ; then
        grep -v sufficient /etc/pam.d/* 2>/dev/null | grep "^[^#]*pam_localuser" >/dev/null 2>&1
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:629\n"
            $CSV || printf "INFO: 629 pam_localuser found in pam configuration, this might prevent SAS users from logging in\n"
        else
            R "629: pam_localuser check"
        fi
    fi

    if [ -f /etc/nologin ] ; then
        $NUM && printf "NUMBER:630\n"
        $CSV || printf "INFO: 630 /etc/nologin found, this might prevent non-root users from logging in\n"
    else
        R "630: /etc/nologin check"
    fi

    # If it doesn't exist I'm sure other tests will complain horribly.
    if [ -d /var/opt/quest/vas/vasd ] ; then
        own="`ls -lad /var/opt/quest/vas/vasd | awk '{print \$3}'`"
        echo "$own" | grep "daemon" >/dev/null
        if [ $? -eq 0 ] ; then
            R "631 var vasd ownership"
        else
            $NUM && printf "NUMBER:631\n"
            $CSV || printf "INFO: 631 /var/opt/quest/vas/vasd is owned by <$own>, not <daemon> as expected.\n"
        fi
    fi
}

t700 ()
{
    $DEBUG && set -x
#   701 Valid license 1 ( expired )
    $VAS license -s 2>&1 | grep "is a site" >/dev/null
    SITE=$?
    $QUICK || if [ $SITE -ne 0 -o "$DO_LICENSING" = "1" ] ; then
        OUT="`$VAS -d5 license -q 2>&1`"
        echo "$OUT" | grep "is expired" >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:701\n"
            $CSV || printf "INFO: 701 SAS has an expired license.\n"
            $CSV || printf "INFO: <`$VAS -d5 license -q 2>&1 | grep \"is expired\"`>\n"
        else
            R "701 no expired licenses"
        fi
    fi

#   703 Valid license 3
    $QUICK || if [ $SITE -ne 0 -o "$DO_LICENSING" = "1" ] ; then
        echo "$OUT" | grep "could not open license dir (/etc/opt/quest/vas/.licenses)" >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:703\n"
            $CSV || printf "FAILURE: 703 SAS does not have a valid license directory.\n"
            $CSV && printf "\"STATUS\",703,\"license check\",2,\"license directory not found\"\n"
            FAILURE=true
        else
            R "703 license directory found"
        fi
    fi

#   717 more than VAS_default license found.
    $QUICK || if [ $SITE -ne 0 -o "$DO_LICENSING" = "1" ] ; then
        LCOUNT="`$LS -A /etc/opt/quest/vas/.licenses 2>/dev/null| grep -v VAS_default | wc -l | awk '{print $1}'`"
        if [ -f /etc/opt/quest/vas/.licenses/VAS_default -a "x$LCOUNT" = "x0" ] ; then
            $NUM && printf "NUMBER:717\n"
            $CSV || printf "FAILURE: 717 SAS only has a HOST license (VAS_default) installed. It requires a valid license file, this only allows computer account creation.\n"
            $CSV && printf "\"STATUS\",717,\"license check\",2,\"only HOST (VAS_default) license found, need a non HOST license\"\n"
            FAILURE=true
        else
            R "717 Valid license installed (beyond VAS_default)"
        fi
    fi
#   702 valid license found
    $QUICK || if [ $SITE -ne 0 -o "$DO_LICENSING" = "1" ] ; then
        echo "$OUT" | awk '{if ($0 ~ /Smartcard/) {NOPRINT=1}; if(NOPRINT==0) {print $0};}' | awk '{if ($0 ~ /Siebel/) {NOPRINT=1}; if(NOPRINT==0) {print $0};}' | grep "No.*licenses are installed" >/dev/null
        if [ $? -eq 0 ] ; then
            $NUM && printf "NUMBER:702\n"
            $CSV || printf "FAILURE: 702 SAS does not have any valid licenses available.\n"
            $CSV && printf "\"STATUS\",702,\"license check\",2,\"No valid SAS licenses found\"\n"
            FAILURE=true
        else
            R "702 valid license found"
        fi
    fi

#    718 mu_upd pid file exists and conflicts with process.
    MUPID="/var/opt/quest/vas/vasd/.vas_muupd.pid"
    if [ -f $MUPID ] ; then
        P="`cat /var/opt/quest/vas/vasd/.vas_muupd.pid`"
        case $PLATFORM in
            OSX*)
                M="`$PS -eAo pid,command|grep \"^[ 	]*$P[ 	][ 	]*\"|grep -v vas_muupd`"
            ;;
            FREEBSD*)
                M="`$PS ax -o pid,comm|grep \"^[  ]*$P[   ][  ]*\"|grep -v vas_muupd`"
            ;;
            *)
                M="`$PS -eo pid,comm|grep \"^[ 	]*$P[ 	][ 	]*\"|grep -v vas_muupd`"
            ;;
        esac
        if [ ! -z "$M" ] ; then
            $NUM && printf "NUMBER:718\n"
            $CSV || printf "FAILURE: 718 <$MUPID> exists but pid <$P> isn't vas_muupd\n"
            $CSV && printf "\"STATUS\",718,\"vas_muupd pid check\",2,\"<$MUPID> exists but pid <$P> isn't vas_muupd\"\n"
            FAILURE=true
        else
            R "718 mu_upd pid file exists and pid conflicts"
        fi
    else
        R "718 mu_upd pid file exists and pid conflicts"
    fi
#   719 not multiple vgptool running
    case $PLATFORM in
        OSX*)
            VGPC="`$PS -eAo command | grep \"[v]gptool\" | wc -l | awk '{print $1}'`"
        ;;
        LINUX*)
            VGPC="`$PS -eo comm | grep \"[v]gptool\" | wc -l | awk '{print $1}'`"
        ;;
        FREEBSD*)
            VGPC="`$PS ax -o comm | grep \"[v]gptool\" | wc -l | awk '{print $1}'`"
        ;;
        SOLARIS_1*)
            if [ -x /usr/bin/zonename ] ; then
                ZONENAME=`/usr/bin/zonename`
            fi
            if [ -n "$ZONENAME" ] ; then
                VGPC="`pgrep -z $ZONENAME vgptool | wc -l | awk '{print $1}'`"
            else
                VGPC="`$PS -eo args | grep \"[v]gptool\" | wc -l | awk '{print $1}'`"
            fi

        ;;
        *)
            VGPC="`$PS -eo args | grep \"[v]gptool\" | wc -l | awk '{print $1}'`"
        ;;
    esac

    if [ $VGPC -gt 2 ] ; then
        $NUM && printf "NUMBER:719\n"
        $CSV || printf "FAILURE: 719 more than 2 vgptools running.\n"
        $CSV && printf "\"STATUS\",719,\"vgptool check\",2,\"more than 2 vgptool processes running\"\n"
        FAILURE=true
    else
        R "719 more than 2 vgptools running"
    fi


    SLIMIT=25
    NSOCKS=`netstat -an 2>/dev/null | grep '\.vasd' | wc -l |awk '{print $1}'`
    if [ $NSOCKS -gt $SLIMIT ] ; then
        sleep 4
        NSOCKS=`netstat -an 2>/dev/null | grep '\.vasd' | wc -l |awk '{print $1}'`
    fi
    if [ $NSOCKS -gt $SLIMIT ] ; then
        $NUM && printf "NUMBER:720\n"
        $CSV || printf "WARNING: 720 more than $SLIMIT vasd sockets, has <$NSOCKS> open.\n"
        $CSV && printf "\"STATUS\",720,\"vasd sockets check\",1,\"more than $SLIMIT vasd sockets, has <$NSOCKS> open.\"\n"
        WARNING=true
    else
        R "720 more than $SLIMIT vasd sockets open"
    fi

    DID_ONE=0
    for F in /var/opt/quest/vas/vasd/.disable_ac_group_updating \
             /var/opt/quest/vas/.qas_id_dbg  \
             /var/opt/quest/vas/.qas_id_call \
             /var/opt/quest/vas/.qas_auth_dbg \
             /var/opt/quest/vas/.qas_auth_call \
             /var/opt/quest/vas/vasd/max_ipc_debugsize \
             /var/opt/quest/vas/.vasd_host_password_disable_force_pdc \
             /var/opt/quest/vas/vasd/.force_disconnected_mode \
             /var/opt/quest/vas/vasd/.parent_pause_processing \
             /var/opt/quest/vas/.upgrade_scenario \
             /var/opt/quest/vas/.disable_starling \
             /var/opt/quest/vgp/.vgptool.lock_MACHINE ; do
        if [ -f "$F" ] ; then
            if [ "$DID_ONE" -eq 0 ] ; then
                DID_ONE=1
                $NUM && printf "NUMBER:722\n"
            fi
            $CSV || printf "INFO: 722 . file found: <$F>\n"
        fi
    done
    if [ "$DID_ONE" -eq 0 ] ; then
        R "722 . file check"
    fi
}

t700b ()
{
    $DEBUG && set -x
    $ADFAILURE && return 0
#   705/706 vasd running
    case $PLATFORM in
        OSX*)
            VASDC="`$PS -eAo command | grep \"^[^ ]*/[.]*vasd \" | wc -l | awk '{print $1}'`"
        ;;
        SOLARIS*)
            VASDC="`$PS -eo comm | grep \"^/opt/quest/sbin/[.]*vasd\" | wc -l | awk '{print $1}'`"
        ;;
        FREEBSD*)
            VASDC="`$PS ax -o comm | grep \"^[.]*vasd\" | wc -l | awk '{print $1}'`"
        ;;
        *)
            VASDC="`$PS -eo comm | grep \"^[.]*vasd\" | wc -l | awk '{print $1}'`"
        ;;
    esac

    if [ $VASDC -lt 1 ] ; then
        $NUM && printf "NUMBER:705\n"
        $CSV || printf "FAILURE: 705 vasd does not appear to be running.\n"
        $CSV && printf "\"STATUS\",705,\"vasd check\",2,\"vasd does not appear to be running\"\n"
        FAILURE=true
        return
    elif [ $VASDC -eq 1 ] ; then
        $NUM && printf "NUMBER:706\n"
        $CSV || printf "FAILURE: 706 vasd does not appear to be running completely ( only one process ).\n"
        $CSV && printf "\"STATUS\",706,\"vasd check\",2,\"vasd does not appear to be running completely, only one process\"\n"
        FAILURE=true
        return
    else
        R "705 vasd running"
        R "706 vasd running properly (two+ processes)"
    fi

#    715 If vgp is installed, vasgpd is running.
    if [ -f $VGPD ] ; then
        case $PLATFORM in
            OSX*)
                VGPDC="`$PS -eAo command | grep \"^[^ ]*/vasgpd \" | wc -l | awk '{print $1}'`"
            ;;
            SOLARIS*)
                VGPDC="`$PS -eo comm | grep \"^/opt/quest/sbin/vasgpd\" | wc -l | awk '{print $1}'`"
            ;;
            FREEBSD*)
                VGPDC="`$PS ax -o comm | grep \"^[.]*vasgpd\" | wc -l | awk '{print $1}'`"
            ;;
            *)
                VGPDC="`$PS -eo comm | grep \"^[.]*vasgpd\" | wc -l | awk '{print $1}'`"
            ;;
        esac

        if [ $VGPDC -lt 1 ] ; then
            $NUM && printf "NUMBER:715\n"
            $CSV || printf "FAILURE: 715 vasgpd does not appear to be running.\n"
            $CSV && printf "\"STATUS\",715,\"vasgpd check\",2,\"vasgpd does not appear to be running\"\n"
            FAILURE=true
            return
        else
            R "715 vasgpd running"
        fi
    fi

#    708 Mapped user consistency.
    if [ ! -z "$MappedFile" ] ; then
        validate_db
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:708\n"
            FAILURE=true
        else
            R "708 mapped user consistent"
        fi
    else
        R "708 mapped user consistent"
    fi


#   713 duplicate users
    $QUICK || if [ "$VASVERMAJOR.$VASVERMINOR.$VASVERREVISION" != "3.0.3" ]; then
        check_dups user
        if [ $? -eq 0 ] ; then
            R "713 duplicate users"
        else
            $NUM && printf "NUMBER:713\n"
            $CSV || printf "FAILURE: 713 There are duplicate users in the cache\n"
            $CSV && printf "\"STATUS\",713,\"duplicate user\",2,\"There are duplicate users in the cache\"\n"
            FAILURE=true
        fi

#   714 no duplicate groups
        check_dups group
        if [ $? -eq 0 ] ; then
            R "714 duplicate groups"
        else
            $NUM && printf "NUMBER:714\n"
            $CSV || printf "FAILURE: 714 There are duplicate groups in the cache\n"
            $CSV && printf "\"STATUS\",714,\"duplicate group\",2,\"There are duplicate groups in the cache\"\n"
            FAILURE=true
        fi
    fi


#   708 vasd responding
# depending on os -f on the ipc file doesn't work.
# and -e doesn't seem universal ( thats what I get for writing these notes
# long after I tested, I don't know what OS fails, jstu that this seemed to be
# the best way to universally test this )
$LS $VASIPC >/dev/null 2>&1
    if [ $? -ne 0 ] ; then
        $NUM && printf "NUMBER:709\n"
        $CSV || printf "FAILURE: 709 Missing <$VASIPC>, vasd cannot handle IPC requests.\n"
        $CSV && printf "\"STATUS\",709,\"vasd check\",2,\"Missing <$VASIPC>, vasd cannot handle requests\"\n"
        FAILURE=true
        return
    else
#   707 vasd responding
        VASD_UP=1
        if [ -f $ASDCOM ] ; then
            $ASDCOM SendPing >/dev/null 2>&1 || VASD_UP=0
        else
            $VAS list users 2>&1 | grep -i "Could not communicate with vasd" >/dev/null
            VASD_UP=$?
        fi
        if [ $VASD_UP -eq 0 ] ; then
            $NUM && printf "NUMBER:707\n"
            $CSV || printf "WARNING: 707 vasd did not respond to an IPC ping, could be busy.\n"
            $CSV && printf "\"STATUS\",707,\"vasd check\",1,\"vasd did not respond to an IPC ping, could be busy\"\n"
            WARNING=true
        else
            R "707 vasd responding to IPC ping"
            R "709 $VASIPC exists"
        fi
    fi

#   710 process memory size
    mem_tests
    if [ $? -ne 0 ] ; then
        $NUM && printf "NUMBER:710\n"
    else
        R "710 process memory size"
    fi

#    711 all binaries are same version
    BAD_VERSION=0
    $QUICK || for file in bin/vastool sbin/vasd sbin/vasypd sbin/vasgpd bin/vgptool bin/uptool sbin/vasproxyd; do
        if [ -f /opt/quest/$file ] ; then
            VER="`/opt/quest/$file -v | grep \"[0-9]*.[0-9]*.[0-9]*.[0-9]*\" | head -1 | sed 's/^\([^:]*\):.* \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)/\2/'`"
            if [ ! "$TVASVERSION" = "$VER" ] ; then
                $CSV || printf "WARNING: 711 /opt/quest/$file version <$VER> does not match SAS version\n"
                $CSV && printf "\"STATUS\",711,\"version check\",1,\"/opt/quest/$file version <$VER> does not match SAS version <$TVASVERSION>\"\n"
                WARNING=true
                BAD_VERSION=1
            fi
        fi
    done

    if [ $BAD_VERSION -ne 0 ] ; then
        $NUM && printf "NUMBER:711\n"
    else
        R "711 all binaries same version"
    fi

# 712, socket file permissions. Should be srwxrwxrwx.
    SPERMS=`$LS -la $VASIPC 2>/dev/null |cut -c1-10 | tr $UPPER $LOWER`
    if [ "$SPERMS" = "srwxrwxrwx" ] ; then
        R "712 socket file permissions"
    else
        $NUM && printf "NUMBER:712\n"
        $CSV || printf "FAILURE: 712 file permissions on <$VASIPC> are <$SPERMS>, must be <srwxrwxrwx>\n"
        $CSV && printf "\"STATUS\",712,\"vasd check\",2,\"file permissions on <$VASIPC> are <$SPERMS>, must be <srwxrwxrwx>\"\n"
        FAILURE=true
    fi

# 716 defunct processes
    DCOUNT=0
    VASDP=
    S=state
    C=comm
    V=".vasd"
    PC="-eo"
    case $PLATFORM in
        OSX*)
            V=/opt/quest/sbin/.vasd
            C=ucomm
        ;;
        SOLARIS*)
            S=s
            V=/opt/quest/sbin/.vasd
        ;;
        FREEBSD*)
            PC="ax -o"
        ;;
    esac

    VASDP="`$PS $PC uid,pid,$C| grep \"^ *0  *[0-9]*  *$V\$\" | head -1 | awk '{print $2}'`"
    if [ -n "$VASDP" ] ; then
        DCOUNT="`$PS $PC ppid,$S | grep $VASDP | grep Z | wc -l | awk '{print $1}'`"
    fi

    if [ $DCOUNT -le 2 ] ; then
        R "716 defunct processes"
    else
        $NUM && printf "NUMBER:716\n"
        $CSV || printf "WARNING: 716 parent vasd process <$VASDP> has <$DCOUNT> defunct processes\n"
        $CSV && printf "\"STATUS\",716,\"vasd check\",1,\"parent vasd process <$VASDP> has <$DCOUNT> defunct processes\"\n"
        WARNING=true
    fi

#   721 users.allow/deny user consistency.
#   But only on SAS 4.0, the older sqlite3 doesn't understand the query used.
    if [ -f $ASDCOM ] ; then
        if [ -f $UALLOW -o -f $UDENY -o "`ls /etc/opt/quest/vas/access.d/ | wc -l`" -gt 0 ] ; then
            validate_ac
            if [ $? -ne 0 ] ; then
                $NUM && printf "NUMBER:721\n"
                FAILURE=true
            else
                R "721 access control file(s) consistent"
            fi
        else
            R "721 access control file(s) consistent"
        fi
    fi

    VASYPD_COUNT=`ps $PC comm | grep vasypd | wc -l`
    YPSERV_COUNT=`ps $PC comm | grep ypserv | wc -l`
    if [ $VASYPD_COUNT -gt 0 -a $YPSERV_COUNT -gt 0 ] ; then
        $NUM && printf "NUMBER:723\n"
        $CSV || printf "INFO: 723 vasypd and ypserv both running\n"
    else
        R "723 vasypd and ypserv check"
    fi

    DC="`$VAS info servers 2>/dev/null | sed '1d' | head -1`"
    if [ -n "$DC" ] ; then
        $VAS info cldap $DC >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:724\n"
            $CSV || printf "INFO: 724 Unable to cldap ping server <$DC> for site\n"
        else
            $VAS info cldap $DC 2>/dev/null | grep "Client Site:.*(NULL)" >/dev/null
            if [ $? -eq 0 ] ; then 
                $NUM && printf "NUMBER:723\n"
                $CSV || printf "INFO: 724 System is not defined as in a site\n"
            else
                R "724 Detect if in a site."
            fi
        fi
    else
        $NUM && printf "NUMBER:724\n"
        $CSV || printf "INFO: 724 Unable to find an in-site server to cldap ping for site\n"
    fi


#    COMPUTERFQDN="`get_setting computerFQDN`"
    if [ -n "$COMPUTERFQDN" ] ; then
        echo $COMPUTERFQDN | grep ".*[.].*" >/dev/null
        if [ $? -eq 0 ] ; then
            R "725 computerFQDN is an fqdn"
        else
            $NUM && printf "NUMBER:725\n"
            $CSV || printf "FAILURE: 725 computerFQDN isn't an fqdn <$COMPUTERFQDN>\n"
            $CSV && printf "\"STATUS\",725,\"fqdn check\",2,\"computerFQDN isn't an fqdn <$COMPUTERFQDN>\"\n"
            FAILURE=true
        fi
    else
        $NUM && printf "NUMBER:725\n"
        $CSV || printf "INFO: 725 No computerFQDN set in misc cache\n"
    fi


    for f in /usr/tgcware/etc/ssh/sshd_config /opt/ssh/etc/sshd_config /etc/ssh/sshd_config /etc/sshd_config /etc/opt/quest/ssh/sshd_config ; do
        FOUND_ONE=false
        if [ -f "$f" ] ; then

            for e in DenyUsers AllowUsers DenyGroups AllowGroups; do
                grep "^[ \t]*$e" $f >/dev/null 2>&1
                if [ $? -eq 0 ] ; then
                    FOUND_ONE=true
                    $CSV || printf "INFO: 726 <$e> entry found in <$f>\n"
                fi
            done
        fi
    done
    if [ !$FOUND_ONE ] ; then
        R "726 AllowUsers, etc in sshd_conf"
    fi

#   727 Check vasypd search_base path.
    VASYPD_SEARCH_BASE="`get_vasconf_setting vasypd search-base`"
    if [ -n "$VASYPD_SEARCH_BASE" ] ; then
        $VAS search -U DC://@$DEFAULTREALM "(distinguishedName=${VASYPD_SEARCH_BASE})" dn >/dev/null 2>&1
        if [ $? -ne 0 ] ; then
            $NUM && printf "NUMBER:727\n"
            $CSV || printf "WARNING: 727 $VASCONF [vasypd] search-base setting <$VASYPD_SEARCH_BASE> could not be found in AD.\n"
            $CSV && printf "\"STATUS\",727,\"Checking [vasypd] search-base setting in vas.conf\",1,\"$VASCONF [vasypd] search-base setting <$VASYPD_SEARCH_BASE> could not be found in AD.\"\n"
            WARNING=true
        else
            R "727 $VASCONF vasypd search-base"
        fi
    else
        R "727 $VASCONF vasypd search-base"
    fi
}

CleanUp ()
{
    rm -f $CLEANUP_FILES
}

EndSuccess ()
{
    $DEBUG && set -x
    $NUM && printf "NUMBER:001\n"
    $CSV || printf "Result: <No tests failed> (`GetTimeDiff $STARTTIME` seconds)(v$VSVERSION)\n"
    CleanUp
    EXIT_VALUE=0
}

ExitCritical ()
{
    $DEBUG && set -x
    $CSV || printf "Result: <Critical test(s) failed> (`GetTimeDiff $STARTTIME` seconds)(v$VSVERSION)\n"
    CleanUp
    EXIT_VALUE=3
}

ExitNoVAS ()
{
    $DEBUG && set -x
    $CSV || printf "Result: <SAS does not appear to be installed> (`GetTimeDiff $STARTTIME` seconds)(v$VSVERSION)\n"
    CleanUp
    EXIT_VALUE=5
}

ExitFailure ()
{
    $DEBUG && set -x
    $CSV || printf "Result: <Test(s) failed> (`GetTimeDiff $STARTTIME` seconds)(v$VSVERSION)\n"
    CleanUp
    EXIT_VALUE=2
}

ExitWarning()
{
    $DEBUG && set -x
    $CSV || printf "Result: <Test(s) reported warnings> (`GetTimeDiff $STARTTIME` seconds)(v$VSVERSION)\n"
    CleanUp
    EXIT_VALUE=1
}

RunEverything ()
{
    t000 ; if [ $? -ne 0 ] ; then ExitNoVAS; return ; fi
    t100 ; if [ $? -ne 0 ] ; then t600; t700; ExitCritical ; return ; fi
    t200 ; if [ $? -ne 0 ] ; then t600; t700; ExitCritical ; return ; fi
    t300
    t400
    t500
    t600
    t700
    t700b
    if $CRITICAL_FAILURE ; then ExitCritical ; return ; fi
    if $FAILURE ; then ExitFailure ; return ; fi
    if $WARNING ; then ExitWarning ; return ; fi
    EndSuccess
}

VerifyRoot

RunEverything
$SET_CCNAME && $VAS kdestroy 2>/dev/null 1>&2
exit $EXIT_VALUE
