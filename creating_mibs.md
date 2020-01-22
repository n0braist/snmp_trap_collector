## Free collection of mibs
http://www.circitor.fr/Mibs/Html

## another collection of mibs (no download)
https://mibs.observium.org/

## Global OID reference database
https://oidref.com/

## Adding MIBS to config on server


Path to MIB modules /usr/share/snmp/mibs
Path for converted MIBS: /etc/snmp

> before converting copy origin mib-files to /usr/share/snmp/mibs to supress dependency errors


### converting MIB manually:
```
snmpttconvertmib --in=/PATH/MIBFILE.mib --out=/PATH/DefinitionFileName
```
 e.g.:
```
snmpttconvertmib --in=/tmp/SL_MIBS_2012-08-20/LSERIES-TAPE-LIBRARY-MIB.mib --out=/etc/snmp/snmptt_storagetek_LSERIES-TAPE-LIBRARY.txt
```

#### The Definitionfile has to be added to snmptt.conf (or sometimes snmptt.ini):

```
 vi /etc/snmp/snmptt.conf
 (vi /etc/snmp/snmptt.ini)
 
 [TrapFiles]
 # A list of snmptt.conf files (this is NOT the snmptrapd.conf file).  The COMPLETE path
 # and filename.  Ex: '/etc/snmp/snmptt.conf'
 snmptt_conf_files = <<END
 /PATH/DefinitionFileName
 e.g.: /etc/snmp/snmptt_storagetek_LSERIES-TAPE-LIBRARY.txt
 .
 .
 END
 ```

### or use script:


 ~~./convert_mibs -S PATHTOORIGIALMIBS -G PATHTOSTORECONVERTEDMIBS~~
 
 ~~e.g.~~
 ~~./convert_mibs -S /tmp/SL_MIBS_2012-08-20/compaq/ -G /etc/snmp/compaq/~~

after that, you have to restart the snmpt daemon:

```
/etc/init.d/snmptt restart
   Stopping /usr/sbin/snmptt                     done
   Starting /usr/sbin/snmptt                      done
 
```
 

### Testing traps by using OID or MIB-File:

SNMPv2 simplified the format of a notification request, consolidating everything within the varbind list, rather than having separate header fields just for Trap requests.  So the first two varbinds of an SNMPv2 notification will be sysUpTime.0 following by snmpTrapOID.0. The value of this second varbind is the OID identifying the trap being sent.

The snmptrap command will insert a sensible value for the sysUpTime varbind, so it's really just necessary to provide the trap OID (plus any additional varbinds from the OBJECTS clause):

```
snmptrap -v 2c -c public host "" UCD-NOTIFICATION-TEST-MIB::demoNotif SNMPv2-MIB::sysLocation.0 s "TEXT YOU WANT TO USE"
```

except of using the MIB-Text you can use the OID also

### example:

```
snmptrap -v 2c -c public XXX.XXX.XXX.XXX "" .1.3.6.1.4.1.2606.7.0.2 SNMPv2-MIB::sysLocation.0 s "TEXT YOU WANT TO USE"
```
 


## MIB Problems:

Be sure that you have all required (import) MIBS inside /usr/share/snmp/mibs

### Problem 1:

```
snmpttconvertmib --in=/tmp/SL_MIBS_2012-08-20/LSERIES-TAPE-LIBRARY-MIB.mib --out=/tmp/SL_MIBS_2012-08-20/snmptt_storagetek_LSERIES-TAPE-LIBRARY.txt
****  Processing MIB file ****
 snmptranslate version: NET-SNMP version: 5.4.2.1
 severity: Normal
 File to load is:        /tmp/SL_MIBS_2012-08-20/LSERIES-TAPE-LIBRARY-MIB.mib
 File to APPEND TO:      /tmp/SL_MIBS_2012-08-20/snmptt_storagetek_LSERIES-TAPE-LIBRARY.txt
 MIBS environment var:   /tmp/SL_MIBS_2012-08-20/LSERIES-TAPE-LIBRARY-MIB.mib
 mib name:

Aborting!!!
 Could not find DEFINITIONS ::= BEGIN statement in MIB file!
```


#### Solution:
 wrong phrase in original MIB-file:
```
LSERIES-TAPE-LIBRARY-MIB DEFINITIONS ::=
 BEGIN

corrected phrase:
 LSERIES-TAPE-LIBRARY-MIB DEFINITIONS ::= BEGIN
```


### Problem 2:

```
snmpttconvertmib --in=/usr/share/snmp/mibs/G3-AVAYA-TRAP.mib --out=/tmp/WFO_12_Framework_MIB_Files/converted/snmptt_G3-AVAYA-TRAPB.mib.txt

*****  Processing MIB file *****

snmptranslate version: NET-SNMP version: 5.4.2.1
severity: Normal

File to load is:        /usr/share/snmp/mibs/G3-AVAYA-TRAP.mib
File to APPEND TO:      /tmp/WFO_12_Framework_MIB_Files/converted/snmptt_G3-AVAYA-TRAPB.mib.txt

MIBS environment var:   /usr/share/snmp/mibs/G3-AVAYA-TRAP.mib
mib name: G3-AVAYA-MIB

Processing MIB:         G3-AVAYA-MIB

Processing MIB:         G3-AVAYA-TRAP
#
skipping a TRAP-TYPE / NOTIFICATION-TYPE line - probably an import line.
#
Line: 36784
TRAP-TYPE: alarmClear
Variables: g3clientExternalName g3alarmsProductID g3alarmsAlarmNumber
Looking up via snmptranslate: G3-AVAYA-TRAP::alarmClear
No log handling enabled - turning on stderr logging
Attempt to define a root oid (iso): At line 10 in /usr/share/snmp/mibs/G3-AVAYA-TRAP.mib
Bad parse of OBJECT IDENTIFIER: At line 10 in /usr/share/snmp/mibs/G3-AVAYA-TRAP.mib
Cannot find module (G3-AVAYA-TRAP): At line 1 in °?a
Unknown object identifier: G3-AVAYA-TRAP::alarmClear
OID:
```

#### Solution:

The problem is the translation of line 10 in the MIB-file. In this case:
```
iso             OBJECT IDENTIFIER ::= { 1 }
```

one solution is to comment it out (with "–")
```
-- iso             OBJECT IDENTIFIER ::= { 1 } 
```
 
