#!/bin/ksh
#
# Name       : snap_backup.ksh
#
# Purpose    : Backup Database
#
# Usage      :
#
# Dependent Files :
#
# History    : Created 06/25/2013
#
# Date          Name                    Comments
#                  Matt Wagner          created
###########################################################################

usage()
{

        print "USAGE : snap_backup.ksh <dbname>"

}

do_backup()
{
. $DBAKSH/sdb.ksh $DBNAME
smo backup create -profile $ORACLE_SID -auto -full -noprotect -retain -hourly -verbose

if [ $? -eq 0 ]
then
$ORACLE_HOME/bin/rman target / <<-EOT
delete force noprompt archivelog all completed before 'sysdate - 1/24';
exit;
EOT
fi
}


main()
{

while getopts s:t: OPTS; do              # Capture -s  option, strip others
    case "$OPTS" in
    s)    DBNAME=$OPTARG;;                              # DBNAME to connect
    t)    BACKUP_ACTION=$OPTARG;;                              # DBNAME to connect
    *)    usage
          return 2;;                                              # Invalid args
    esac
    done
  shift `expr $OPTIND - 1`                                  # remove argument(s)
  

  print "#################################################################################"
  print `date` Begin $PROGRAM_NAME

   do_backup


  print "#################################################################################"
  print `date` End $PROGRAM_NAME
  print "#################################################################################"
} >$DBALOG/${PROGRAM_NAME}_${2}.log 2>$DBALOG/${PROGRAM_NAME}_${2}.err
#*******************************************************************************
# START HERE

#  Run envoracle to set DBA system variables   !!
. ~/.envorabase
export PROGRAM_NAME=`basename $0 .ksh`
export FILE_NAME=$0
export HOSTNAME=`hostname`

# Copy the old log file to the history file
cat $DBALOG/${PROGRAM_NAME}_${2}.log>>$DBALOG/${PROGRAM_NAME}_${2}.log.history 2>/dev/null

main ${1+"$@"}
if [[ -s $DBALOG/${PROGRAM_NAME}_${2}.err ]]
then
# cat  $DBALOG/$PROGRAM_NAME.err | $DBAKSH/mail.ksh -s $FILE_NAME
cat $DBALOG/${PROGRAM_NAME}_${2}.err | mail -s $FILE_NAME wagnerm@one.verizon.com
else
cat $DBALOG/${PROGRAM_NAME}_${2}.log | mail -s "$DBNAME - Backup Complete" wagnerm@one.verizon.com
fi
exit $RETURN
