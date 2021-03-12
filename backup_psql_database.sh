#!/usr/bin/env bash
source $(dirname $0)/psql.conf
DATEYMD=`date --iso`
for DBNAME in ${DBLIST[@]}
do
  function main
  {
  echo "[--------------------------------[`date +%F--%H-%M`]--------------------------------]" 
  echo "[----------][`date +%F--%H-%M`] Run the backup script..."
  mkdir -p ${BACKUPDIR_D}/${DBNAME} 2> /dev/null
  # postgresql dump
  pg_dump -h 127.0.0.1 -p 5432 -Fc -Z9 ${DBNAME} -f "/tmp/`date +%F`_${DBNAME}.dump"
  mv -f /tmp/`date +%F`_${DBNAME}.dump ${BACKUPDIR_D}/${DBNAME}/${DATEYMD}_${DBNAME}.dump 2> /dev/null
  if [[ $? -gt 0 ]]
   then 
   echo "[++--------][`date +%F--%H-%M`] Aborted. Generate database backup failed."
   exit 1
  fi
  find ${BACKUPDIR_D}/${DBNAME}/ -type f -atime +${DCOUNT} -name '*.dump' -delete
  if [ "`date +%d`" -eq "${DOM}" ]
   then
   mkdir -p ${BACKUPDIR_M}/${DBNAME}
   cp ${BACKUPDIR_D}/${DBNAME}/${DATEYMD}_${DBNAME}.dump ${BACKUPDIR_M}/${DBNAME}/
   find ${BACKUPDIR_M}/${DBNAME}/ -type f -atime +${MCOUNT} -name '*.dump' -delete
  fi
  echo "[++++------][`date +%F--%H-%M`] Backup database [$DBNAME] - successfull."
  echo "[+++++++++-][`date +%F--%H-%M`] Stat datadir space (USED): `du -h ${BACKUPDIR_D} | tail -n1`" 
  echo "[+++++++++-][`date +%F--%H-%M`] Free BACKUP space: `df -h ${BACKUPSPACE}|tail -n1|awk '{print $4}'`"
  echo "[++++++++++][`date +%F--%H-%M`] All operations completed successfully!"
  }
  main 2>&1 | rotatelogs -n 2 ${LOGSDIR}/psql_backup.log 1M
done
exit 0
