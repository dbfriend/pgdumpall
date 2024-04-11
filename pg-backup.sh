#!/bin/bash
################################################################################################
#### Scripname:         pg-backup.sh
#### Description:       This is script is performing a PostgreSQL backup and is deleting older dumps
#### Version:           1.7
################################################################################################

#### Time Function for logs
_currtime() {
  echo "$(date +"%Y-%m-%dT%H:%M:%S.%3N%z")"
}

### Environment specific variables
if [ ! -f $(dirname $0)/pg-backup.conf ]; then
  echo "$(_currtime) - Cannot find config.file at $(dirname $0)/pg-backup.conf"
  exit 1
fi

echo "$(_currtime) - Load config file $(dirname $0)/pg-backup.conf"
source "$(dirname $0)/pg-backup.conf"

### Script specific variables
POSTFIX=${HOSTNAME}_$(date +"%Y%m%d%H%M")
CLEANLOG=${BACKUPLOC}/pgdumpall_${POSTFIX}.clog
LOGFILE=${BACKUPLOC}/pgdumpall_${POSTFIX}.log
SCRIPTVERSION="1.7"

### Check if script is already running
if [ $(pgrep -f $(basename $0) | wc --lines) -gt 2 ]; then
  echo "Backup script already running"
  exit 1
fi

### Check backup dir
if [ ! -d "${BACKUPLOC}" ]; then
  echo "$(_currtime) - Backup dir ${BACKUPLOC} doesn't exists, abort"
  echo "$(_currtime) - Script ends"
  exit 1
fi

### Create log-files
touch ${LOGFILE}
chown postgres:postgres ${LOGFILE}
chmod 600 ${LOGFILE}
echo "$(_currtime) - Script start" | tee -a ${LOGFILE} ${CLEANLOG}

#### Check if pg_dumpall-binaries exists
if [ ! -x ${PGDUMPALL} ]; then
  echo "$(_currtime) - Cannot find pg_dumpall at location ${PGDUMPALL}, abort" | tee -a ${LOGFILE}
  echo "$(_currtime) - Script ends"                                            | tee -a ${LOGFILE}
  mv ${LOGFILE} ${LOGFILE}.FAILED
  exit 1
fi

### Check if password file is available
if [ ! -f ${PGPASSFILE} ]; then
  echo "$(_currtime) - Cannot find password-file (pgpass) at location ${PGPASSFILE}, abort" | tee -a ${LOGFILE}
  echo "$(_currtime) - Script ends"                                            | tee -a ${LOGFILE}
  mv ${LOGFILE} ${LOGFILE}.FAILED
  exit 1
fi

### Find PGDATA location
PGDATA=$(systemctl cat postgresql.service | grep "Environment=PGDATA=" | awk -F'=' '{print $3}' | tail -1)
if [ -z ${PGDATA} ]; then
  echo "$(_currtime) - Cannot find PGDATA at systemctl" | tee -a ${LOGFILE}
  echo "$(_currtime) - Script ends" | tee -a ${LOGFILE}
  mv ${LOGFILE} ${LOGFILE}.FAILED
  exit 1
fi

### Show file information
echo "$(_currtime) - Script version: ${SCRIPTVERSION}" | tee -a ${LOGFILE}
echo "$(_currtime) - Log: ${LOGFILE}" | tee -a ${LOGFILE}
echo "$(_currtime) - Database backup file: ${BACKUPLOC}/pgdumpall_${POSTFIX}.sql" | tee -a ${LOGFILE}
echo "$(_currtime) - Config files backup: ${BACKUPLOC}/pgdumpall_${POSTFIX}.conf.tar" | tee -a ${LOGFILE}
echo "$(_currtime) - Clean log: ${CLEANLOG}" | tee -a ${LOGFILE}
echo "$(_currtime) - PGDATA: ${PGDATA}" | tee -a ${LOGFILE}
echo "$(_currtime) - Backup retention: ${RETENTION} days" | tee -a ${LOGFILE}
echo "$(_currtime) - Compress backup after: ${COMPRESSAFTER} days" | tee -a ${LOGFILE}

### Do the actual work
echo "$(_currtime) - Progressing ..." | tee -a ${LOGFILE}
${PGDUMPALL} --verbose --clean --username=${USER} --file=${BACKUPLOC}/pgdumpall_${POSTFIX}.sql >> ${LOGFILE} 2>&1
BCK_RC=${?}

#### Error handling
if [ ${BCK_RC} -ne 0 ]; then
  tail -2 ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  echo "$(_currtime) - Dump failed, abort"      | tee -a ${LOGFILE}
  echo "$(_currtime) - Script ends"             | tee -a ${LOGFILE}
  mv ${LOGFILE} ${LOGFILE}.FAILED
  exit 1
fi

echo "$(_currtime) - Database backup completed successfully."    | tee -a ${LOGFILE}

### Backup all *.conf files at PGDATA
echo "$(_currtime) - Starting to backup config files..."    | tee -a ${LOGFILE}
tar --verbose --create --file=${BACKUPLOC}/pgdumpall_${POSTFIX}.conf.tar ${PGDATA}/*.conf >> ${LOGFILE}
echo "$(_currtime) - Config files backup completed successfully."    | tee -a ${LOGFILE}

### Delete backups and its logs which are older than retention period
echo "$(_currtime) - Backups after ${RETENTION} days will be deleted: " | tee -a ${CLEANLOG}

for FILE in $(find ${BACKUPLOC} -type f \( -name '*.sql' -o -name '*.sql.gz' -o -name '*.sql.zst' -o -name '*.log' -o -name '*.clog' -o -name '*.tar' \) -mtime +${RETENTION} ! -path '*/.snapshot/*'); do
  echo "$(_currtime) - $(ls -lh ${FILE} | awk '{print $9" - Size: "$5 }')" | tee -a ${CLEANLOG}
  rm --force ${FILE}
done

### Compress older backups to save storage
echo "$(_currtime) - Backups after ${COMPRESSAFTER} days will be compressed: " | tee -a ${CLEANLOG}

if [ -x "/usr/bin/zstd" ]; then
  echo "$(_currtime) - Using Zstandard (*.zst) for compression" | tee -a ${CLEANLOG}
  CTOOL="/usr/bin/zstd --rm --quiet --force"
  CTOOLEXT="zst"

elif [ -x "/usr/bin/gzip" ]; then
  echo "$(_currtime) - Using Gzip (*.gz) for compression" | tee -a ${CLEANLOG}
  CTOOL="/usr/bin/gzip --force"
  CTOOLEXT="gz"

else
  echo "$(_currtime) - No compression tool found, skip compression :(" | tee -a ${CLEANLOG}
  CTOOL="NF"
fi

if [ "${CTOOL}" != "NF" ]; then
  for FILE in $(find ${BACKUPLOC} -type f -name '*.sql' -mtime +${COMPRESSAFTER} ! -path '*/.snapshot/*'); do
    echo "$(_currtime) - $(ls ${FILE}) >> $(ls ${FILE}).${CTOOLEXT}" | tee -a ${CLEANLOG}
    ${CTOOL} ${FILE}
  done
fi

### Change ownership to postgres user
chown postgres:postgres ${BACKUPLOC}/pgdumpall_${POSTFIX}.*
chmod 600 ${BACKUPLOC}/pgdumpall_${POSTFIX}.*

echo "$(_currtime) - Script ends"                       | tee -a ${LOGFILE} ${CLEANLOG}
exit 0
