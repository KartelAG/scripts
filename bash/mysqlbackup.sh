#!/bin/sh
### Binaries ###
TAR="$(which tar)"
GZIP="$(which gzip)"
FTP="$(which ftp)"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"

### Mysql ### 
MUSER=
MPASS=
MHOST=

### FTP parameters ###
### FTP server name ###
FTPS=
### FTP remote dir ###
FTPD=

## Today + hour in 24h format ###
NOW=$(date +%Y%m%d) 

BACKUP=/root/backup/mysql
mkdir $BACKUP/$NOW

### name Mysql ###
DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
for db in $DBS
do
  echo "backuping $db" 
  mkdir $BACKUP/$NOW/$db
  FILE=$BACKUP/$NOW/$db/$db.sql.gz
  echo "creating file $FILE"
  $MYSQLDUMP --add-drop-table --allow-keywords -q -c -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $FILE
done

$TAR -zcf $BACKUP/mysql-$NOW.tar.gz $BACKUP/$NOW
if [[ $? -eq 0 ]]; then
  echo "removing backup folder"
  rm -rf $BACKUP/$NOW
fi 

### sending backup to ftp server ###
cd $BACKUP
DUMPFILE=mysql-$NOW.tar.gz
$FTP -i -A $FTPS <<END_SCRIPT
cd $FTPD
mput $DUMPFILE
quit
END_SCRIPT

#echo $?
echo $DUMPFILE >> $BACKUP/mysql.list

if [[ `cat $BACKUP/mysql.list | wc -l` -ge 7 ]] 
then
  echo "Starting to Delete..."
  echo $BACKUP/mysql.list
  FILETODEL=`head -1 $BACKUP/mysql.list` 
  rm -f $BACKUP/$FILETODEL
  $FTP -i -A $FTPS <<END_SCRIPT
  cd $FTPD
  delete $FILETODEL
  quit
END_SCRIPT
  sed -e '1d' $BACKUP/mysql.list > $BACKUP/mysql.list2
  mv $BACKUP/mysql.list2 $BACKUP/mysql.list
fi

