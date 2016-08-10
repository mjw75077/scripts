#!/bin/ksh
#
# Name       : dg_check_instance.ksh
#
# Purpose    : Make sure Listnener, isntance and MRP are up
#
# Usage      : dg_check_instance.ksh
#
# Dependent Files :
#
# History    : Created 03/01/2014
#
# Date          Name                    Comments
#                  Matt Wagner          created
###########################################################################


check_svcs()
{

if ps ax| grep -v grep|grep -c tnslsnr >/dev/null
then
        echo "Listener is running"
else
        echo "Listener is not running." >> $DBALOG/$PROGRAM_NAME.err
fi

if ps ax| grep -v grep|grep -c ora_mrp0 >/dev/null
then
        echo "Managed Recovery is running"
else
        echo "Managed Recovery is not running." >> $DBALOG/$PROGRAM_NAME.err
fi

if ps ax| grep -v grep|grep -c ora_pmon_$ORACLE_SID >/dev/null
then
        echo "Oracle Instance is running."
else
        echo "Oracle Instance is not running" >> $DBALOG/$PROGRAM_NAME.err
fi
}

main()
{
  while getopts d: OPTS; do
    case "$OPTS" in
    d)    DBNAME=$OPTARG;;
    *)    usage
          return 2;;                                              # Invalid args
    esac
    done
  shift `expr $OPTIND - 1`

. $DBAKSH/sdb.ksh $DBNAME > /dev/null

check_svcs


} >$DBALOG/$PROGRAM_NAME.log 2>$DBALOG/$PROGRAM_NAME.err

#*******************************************************************************
# START HERE

#  Run envoracle to set DBA system variables   !!
. ~/.envorabase
export PROGRAM_NAME=`basename $0 .ksh`
export FILE_NAME=$0
export HOSTNAME=`hostname`

# Copy the old log file to the history file
cat $DBALOG/$PROGRAM_NAME.log>>$DBALOG/$PROGRAM_NAME.log.history 2>/dev/null

# If $1 is defined then replace arg list with $@, else truly empty
main ${1+"$@"}
if [[ -s $DBALOG/$PROGRAM_NAME.err ]]
then
cat  $DBALOG/$PROGRAM_NAME.err | $DBAKSH/mail.ksh -s $FILE_NAME
fi
exit $RETURN
