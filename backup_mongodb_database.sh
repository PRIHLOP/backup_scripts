#!/bin/bash
source $(dirname $0)/mongodb.conf
mkdir -p ${LOGSDIR} 2> /dev/null
#start backup
for DBNAME in ${DBLIST[@]}
do
  function main
  {
  echo "[--------------------------------[`date +%F--%H-%M`]--------------------------------]" 
  echo "[----------][`date +%F--%H-%M`] Run the backup script..."
  mkdir -p ${BACKUPDIR_D}/${DBNAME} 2> /dev/null 
  echo "[++--------][`date +%F--%H-%M`] Generate a database backup..."
  #MongoDB dump
  mongodump --host ${HOST} --db ${DBNAME} --out /tmp/`date +%F`_${DBNAME}
  cd /tmp/
  tar -czf ./`date +%F`_${DBNAME}.tar.gz ./`date +%F`_${DBNAME}/
  rm -rf ./`date +%F`_${DBNAME}/
  mv -f ./`date +%F`_${DBNAME}.tar.gz ${BACKUPDIR_D}/${DBNAME}/ 2> /dev/null
#--username=${USER} --password="${PASSWD}" --authenticationDatabase admin --db=${DBNAME} --archive=${BACKUPDIR_D}/${DBNAME}/`date +%F`_${DBNAME}.archive --gzip
  if [[ $? -gt 0 ]];then 
    echo "[++--------][`date +%F--%H-%M`] Aborted. Generate database backup failed."
    exit 1
  fi
  find ${BACKUPDIR_D}/${DBNAME}/ -type f -atime +${DCOUNT} -name '*.tar.gz' -delete
  if [ "`date +%d`" -eq "${DOM}" ]
   then
   mkdir -p ${BACKUPDIR_M}/${DBNAME}
   cp ${BACKUPDIR_D}/${DBNAME}/`date +%F`_${DBNAME}.sql.gz ${BACKUPDIR_M}/${DBNAME}/
   find ${BACKUPDIR_M}/${DBNAME}/ -type f -atime +${MCOUNT} -name '*.tar.gz' -delete
  fi
  echo "[++++------][`date +%F--%H-%M`] Backup database [${DBNAME}] - successfull."
  echo "[+++++++++-][`date +%F--%H-%M`] Stat datadir space (USED): `du -h ${BACKUPDIR_D} | tail -n1`" 
  echo "[+++++++++-][`date +%F--%H-%M`] Free BACKUP space: `df -h ${BACKUPSPACE}|tail -n1|awk '{print $4}'`"
  echo "[++++++++++][`date +%F--%H-%M`] All operations completed successfully!"
  }
  main 2>&1 | rotatelogs -n 2 ${LOGSDIR}/mongo_backup.log 1M
done
exit 0
