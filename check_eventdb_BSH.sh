#!/bin/bash
#
##############################################################
#
# written by: Stefan Lange (stefan.lange@bshg.com), BSH Hausgeraete GmbH
#
# help for mysql db users http://dev.mysql.com/doc/refman/5.1/de/adding-users.html (german)
#
# 08.01.2013    v 1.0  first shot script
# 14.11.2013    v 1.1  changed syntax in message (. to spaces) 
# 10.03.2014    v 1.2  added SQL statement error problems
# 12.05.2014    v 1.3  problems with \ in messagde text solved
# 05.08.2016    v 2.0  new tmp procedure for non EventDB DB, remoehost, datefield 
#
##############################################################

#################################################################################################################################
#
# examples
#
# EventDB:
# EventDB on HOSTNAME 
# ./check_eventdb_BSH.sh -u USER -p PASSWORD -d eventdb -t event -C host_name,message,created,priority -P 22m -w 1 -c 5 -S "(priority = '0')" -M 'PRIORITY_3_(ALERT)_Alarm:'
# 
#
# other mysql:
# here Syslog on HOSTNAME
# ./check_eventdb_BSH.sh -u USER -p PASSWORD -d Syslog -t SystemEvents -C DeviceReportedTime,Facility,Priority,FromHost,Message -P 5m -w 10 -c 50 -S "(FromHost LIKE '%XXX')" -D DeviceReportedTime -M "LogAnalyzer"
#
#
# for snmp database described on  https://github.com/n0braist/snmp_trap_collector :
#
#  ./check_eventdb_BSH.sh -u DBUSER -p DBPASSWORD -d snmptt -t snmptt -C hostname,formatline,severity,traptime -D traptime -P 22m -w 1 -c 5 -S "(hostname LIKE 'cdcst%' OR hostname LIKE '%hds%') AND (formatline LIKE '%DRIVE BLOCKADE%') ORDER BY traptime DESC" -M "HDS_Alarms: " 
#
###################################################################################################################################

# configurations
export PATH="/bin:/usr/local/bin:/sbin:/usr/bin:/usr/sbin"
PROGNAME=$(basename $0)
BASE=`uname -s`
DATE=`date "+%d.%m.%Y %H:%M:%S"`
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
DBHOST=localhost
DATEFIELD=created
TEMPDIR=`mktemp -d /tmp/checkeventdbdir.XXXXXXXXXXX`
chmod 777 $TEMPDIR
SQLERROR=`mktemp /$TEMPDIR/checkeeventdbsqlerror.XXXXXX`

# FUNCTIONS
function usage() {
    echo "Usage: $PROGNAME  -u [DBUSER] -p [DBPW] -d [DBNAME] -t [DBTABLE] -P [TIMEPERIOD] -w [warning threshold] -c [critical threshold] -S [SQL statement] -M [MESSAGETEXT]"
    echo "Usage: $PROGNAME  -h, --help"
    echo ""
    echo "Options:"
    echo "    -h print help"
    echo "    -H DBHOST:      Database host"
    echo "    -u DBUSER:      User which is allowd to access DB data"
    echo "    -p DBPASSWORD:  Password of this user"
    echo "    -d DBNAME:      Name of database"
    echo "    -t DBTABLE:     DB-Table from which you want to take your information"
    echo "    -C COLUMN:      Which columns should be searched in the table"
    echo "    -P PERIOD:      s (seconds), m (minutes), h (hours), d (days), w (weeks) or y (years)"
    echo "    -D DATEFIELD:   which column should be used for the date reference"
    echo "    -w WARNING:     Threshold for warning matches"
    echo "    -c CRITICAL:    Threshold for critical matches"
    echo "    -S STATEMENT:   complete SQL-statement set into \" \" (like \"WHERE STATEMENT\")"
    echo "    -M MESSAGETEXT: write your individual message for ticketing"
    echo
    echo "Example: ./check_eventdb_BSH.sh -H HOSTNAME -u USER -p PW -d DATABASE -t TABLENAME -P 2d -w 3 -c 5  -S \"(host_name LIKE 'cdcsw%') AND (message LIKE '%UNKNOWN TRAP%')\" -M \"Check for cdcsw and unknown traps\""
    echo "Example: ./check_eventdb_BSH.sh -u USER -p PW -d DATABASE -t TABLENAME -P 48w -w 3 -c 5 -S \"(host_name = 'xxxxm01' OR host_name = 'XXXXm02') AND (message LIKE 'An alarm has been issued%')\" -M \"Check for XXXXm01 and XXXXm03 and 'An alarm has been issued'\""
    echo
    echo "Example: ./check_eventdb_BSH.sh -u DBUSER -p DBPASSWORD -d snmptt -t snmptt -C hostname,formatline,severity,traptime -D traptime -P 22m -w 1 -c 5 -S \"(hostname LIKE 'cdcst%' OR hostname LIKE '%hds%') AND (formatline LIKE '%DRIVE BLOCKADE%') ORDER BY traptime DESC\" -M \"HDS_Alarms: \""
    echo ""
}

function print_help() {
    echo "$PROGNAME checks a mysql database for a STATEMENT"
    echo ""
    usage
    echo ""
    echo "  Don't forget to use -D argument if you use another DB than EventDB from Netways"
    echo ""
    echo "  This plugin is NOT developed by the Nagios Plugin group."
    echo "  Please do not e-mail them for support on this plugin, since"
    echo "  they won't know what you're talking about."
    echo ""
    echo "  written by Stefan Lange (stefan.lange@bshg.com)"
    echo "             BSH Hausgeraete GmbH"
    echo
}

# END OF FUNCTIONS

if [ $# -eq 0 ]; then
    usage
    #echo "erste if mit: $#"
    exit $STATE_CRITICAL
fi

while [ "$1" != "" ]
do
    case "$1" in
        --help) print_help; exit $STATE_OK;;
        -h) print_help; exit $STATE_OK;;
        -u) DBUSER=$2; shift 2;;
        -H) DBHOST=$2; shift 2;;
        -p) DBPASS=$2; shift 2;;
        -d) DBNAME=$2; shift 2;;
        -t) DBTABLE=$2; shift 2;;
        -C) COLUMN=$2; shift 2;;
        -c) CRITTHRES=$2; shift 2;;        
        -w) WARNTHRES=$2; shift 2;;
        -D) DATEFIELD=$2; shift 2;;
        -S) STATEMENT=$2; shift 2;;
        -P) PERIOD=$2; shift 2;;
        -M) MESSAGETEXT=$2; shift 2;;
        *) usage; exit $STATE_UNKNOWN;;
    esac
done

if [ -z $MESSAGETEXT ]; then
    PERFTEXT="check eventdb BSH"
    ALERTINFO=""
else
    PERFTEXT=`echo $MESSAGETEXT | tr "_" " "`
    ALERTINFO=$PERFTEXT
fi

UNITPARAMETER=`echo $PERIOD | tail -c2`

        case $UNITPARAMETER in
            m)
                UNIT="minutes"
                ;;
            s)
                UNIT="seconds"
                ;;
            h)
                UNIT="hours"
                ;;
            d)
                UNIT="days"
                ;;
            w)
                UNIT="weeks"
                ;;
            y)
                UNIT="years"
                ;;
            *)
                echo "choosen unit for timeperiod unknown. please choose s (seconds), m (minutes), h (hours), d (days), w (weeks) or y (years)"
                ;;
        esac
    
        
TIME=`echo $PERIOD | tr '[a-z]' ' '`
PURGEDATE=`date --date "$TIME $UNIT ago" "+%Y-%m-%d %H:%M:%S"`

# running db command
if [ $DBNAME = "eventdb" ]; then
    mysql --user=$DBUSER --host=$DBHOST --password=$DBPASS $DBNAME --execute="SELECT $COLUMN FROM $DBTABLE WHERE created > '$PURGEDATE' AND $STATEMENT;" >> $TEMPDIR/checkeventdb.log 2>$SQLERROR
else

    mysql --user=$DBUSER --host=$DBHOST --password=$DBPASS $DBNAME --execute="SELECT $COLUMN FROM $DBTABLE WHERE $DATEFIELD > '$PURGEDATE' AND $STATEMENT;" >> $TEMPDIR/checkeventdb.log 2>$SQLERROR

fi

SQLERRORCOUNTER=`cat $SQLERROR | wc -c`
#echo "Debug: cat $EVENTLOG"
#cat $EVENTLOG

if [ $SQLERRORCOUNTER -gt 0 ]; then
    SQLERRORTEXT=`cat $SQLERROR`
    echo -n "EventDB SQL statement error for check: -> $ALERTINFO <-; SQL error: $SQLERRORTEXT"
    rm -r $TEMPDIR
    exit $STATE_UNKNOWN
fi

# counting the matches
MATCHCOUNTER=`cat $TEMPDIR/checkeventdb.log | wc -l`

# building performancetext
typeset -i MAX
typeset -i CRITTHRES
MIN=0
MAX=$MATCHCOUNTER+2
PERFORMANCE="$PERFTEXT=$MATCHCOUNTER;$WARNTHRES;$CRITTHRES;$MIN;$MAX"

# exit if warning threshold is not reached
if [ $MATCHCOUNTER -lt $WARNTHRES ]; then
    echo -n "EventDB check $ALERTINFO OK|$PERFORMANCE"
    rm -r $TEMPDIR
    exit $STATE_OK
fi

# building information text
MESSAGE=`cat $TEMPDIR/checkeventdb.log | tr '{<>*#%\\"' " " | tr -s " " | tr "\n" ";" | tr -d '\\' 2>/dev/null`
MESSAGE=`echo $MESSAGE | sed -e 's/  */ /g'`

# generating the alarms
if [ $MATCHCOUNTER -ge $CRITTHRES ]; then
    echo -n "EventDB check $ALERTINFO CRITICAL: $MATCHCOUNTER matches found. Matchtext: $MESSAGE|$PERFORMANCE" 
    rm -r $TEMPDIR
    exit $STATE_CRITICAL    
else
    echo -n "EventDB check $ALERTINFO CRITICAL: $MATCHCOUNTER matches found. Matchtext: $MESSAGE|$PERFORMANCE"
    rm -r $TEMPDIR
    exit $STATE_WARNING
fi

echo "hm, this script runs even further than I thought..."
exit $STATE_UNKNOWN

