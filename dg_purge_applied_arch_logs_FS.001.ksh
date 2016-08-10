#!/bin/ksh
#
# Name       : purge_dg_applied_archlogs_FS.ksh
#
# Purpose    : Purge applied archivelogs for Filesystem based DBs
#
# Usage      : purge_dg_applied_archlogs_FS.ksh -d <dbname>
#
# Dependent Files :
#
# History    : Created 03/01/2014
#
# Date          Name                    Comments
#                  Matt Wagner          created
###########################################################################


do_sql()
{
sqlplus -s / as sysdba  <<-EOT
set echo off;
set timing off;
set head off;
set feedback off;
set pagesize 0;

spool $DBALOG/arch_purge.lst
select thread#, max(sequence#) from v\$archived_log where applied='YES' and registrar='RFS' and completion_time < (sysdate -7) group by thread#;
spool off;
exit;
EOT
}


purge_arch_logs()
{
cat $DBALOG/arch_purge.lst | awk '{print "delete noprompt  archivelog until sequence " $2 " thread=" $1 ";"}' > $DBASQL/del_archs.rman
$ORACLE_HOME/bin/rman target / <<-EOT
@$DBASQL/del_archs.rman
exit;
EOT

}



main()
{

  print "#################################################################################"
  print `date` Begin $PROGRAM_NAME

   # Examine options
  while getopts :d: OPTS; do            # Capture -t option, strip others
    case "$OPTS" in
    d)    DATABASE=$OPTARG;;           # THRESHOLD to check for
    *)    usage
          return 2;;                    # Invalid args
    esac
    done
  shift `expr $OPTIND - 1`              # remove argument(s)


  export $DATABASE

  . $DBAKSH/sdb.ksh $DATABASE >/dev/null

  if [ -z "$ORACLE_HOME" ]; then
        print -u2 ORACLE_HOME cannot be set for $ORACLE_SID..Exiting..

  else
   do_sql
   purge_arch_logs
  fi

  print "#################################################################################"
  print `date` End $PROGRAM_NAME
  print "#################################################################################"
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
else
cat $DBALOG/$PROGRAM_NAME.log | mail -s "$DATABASE - Dataguard Purge Applied Archive Logs" wagnerm@one.verizon.com
fi
exit $RETURN
