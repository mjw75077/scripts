#!/bin/ksh
#
# Name       : nexidia.ksh
#
# Purpose    : outerface file for nexidia
#
# Usage      :
#
# Dependent Files :
#
# History    : Created 02/14/2014
#
# Date          Name                    Comments
#                  Matt Wagner          created
###########################################################################


do_sql()
{

FILENAME=CB_VZWVOC_CTR_`date +"%Y%m%d"`.TXT

. $DBAKSH/sdb.ksh VOCPROD
sqlplus -s / as sysdba  <<-EOT
set echo on;
set timing off;
set head off;
set feedback off;
set pagesize 0;
spool $VOCLOG/$FILENAME
@$VOCSQL/nexidia.sql;
spool off;
exit;
EOT
}


xmit_file()
{
   sftp -oPort=40022 clarabridge_sftp@twacfidpsvc.tdc.vzwcorp.com  << EOF
   cd clarabridge_zweig
   put $VOCLOG/$FILENAME
   exit
EOF
}



main()
{

  print "#################################################################################"
  print `date` Begin $PROGRAM_NAME

   do_sql
   xmit_file

  print "#################################################################################"
  print `date` End $PROGRAM_NAME
  print "#################################################################################"
} >$VOCLOG/$PROGRAM_NAME.log 2>$VOCLOG/$PROGRAM_NAME.err
#*******************************************************************************
# START HERE

#  Run envoracle to set DBA system variables   !!
. ~/.envorabase
export PROGRAM_NAME=`basename $0 .ksh`
export FILE_NAME=$0
export HOSTNAME=`hostname`

# Copy the old log file to the history file
cat $VOCLOG/$PROGRAM_NAME.log>>$VOCLOG/$PROGRAM_NAME.log.history 2>/dev/null

# If $1 is defined then replace arg list with $@, else truly empty
main ${1+"$@"}
egrep -v "Connect|MFT" nexidia.err > $VOCLOG/$PROGRAM_NAME.out
if [[ -s $VOCLOG/$PROGRAM_NAME.out ]]
then
# cat  $VOCLOG/$PROGRAM_NAME.err | $VOCKSH/mail.ksh -s $FILE_NAME
cat $VOCLOG/$PROGRAM_NAME.out | mail -s $FILE_NAME wagnerm@one.verizon.com
else
echo "Nexidia File has been delivered" |mail -s "Nexidia Job - Complete" wagnerm@one.verizon.com
fi
exit $RETURN
