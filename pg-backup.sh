#!/bin/bash
################################################################################################
#### Scripname:         pg-backup.sh
#### Description:       This is script is performing a PostgreSQL backup and is deleting older dumps
#### Version:           1.4
################################################################################################

### Set environment
BACKUPLOC=/var/SP/postgres/backup
USER=backup
export PGPASSFILE=/var/lib/pgsql/.pgpass
PGDUMPALL=/usr/bin/pg_dumpall
POSTFIX=${HOSTNAME}_$(date +"%Y%m%d%H%M")
CLEANLOG=${BACKUPLOC}/pgdumpall_${POSTFIX}.clog
LOGFILE=${BACKUPLOC}/pgdumpall_${POSTFIX}.log
RETENTION=32

#### Time Function for logs
_currtime() {
  echo "$(date +"%Y-%m-%dT%H:%M:%S.%3N%z")"
}

### Check if script is already running
if [ $(pgrep -f $(basename $0) | wc -l) -gt 2 ]; then
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

### Show file information
echo "$(_currtime) - Log: ${LOGFILE}" | tee -a ${LOGFILE}
echo "$(_currtime) - Backup file: ${BACKUPLOC}/pgdumpall_${POSTFIX}.sql" | tee -a ${LOGFILE}
echo "$(_currtime) - Clean log: ${CLEANLOG}" | tee -a ${LOGFILE}
echo "$(_currtime) - Backup retention: ${RETENTION} days" | tee -a ${LOGFILE}

### Do the actual work
echo "$(_currtime) - Progressing ..." | tee -a ${LOGFILE}
${PGDUMPALL} -v -c -U ${USER} -f ${BACKUPLOC}/pgdumpall_${POSTFIX}.sql >> ${LOGFILE} 2>&1
BCK_RC=${?}

#### Error handling
if [ ${BCK_RC} -ne 0 ]; then
  tail -2 ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  echo "$(_currtime) - Dump failed, abort"      | tee -a ${LOGFILE}
  echo "$(_currtime) - Script ends"             | tee -a ${LOGFILE}
  mv ${LOGFILE} ${LOGFILE}.FAILED
  exit 1
fi

echo "$(_currtime) - Backup completed successfully."    | tee -a ${LOGFILE}

### Delete backups and its logs which are older than retention period
echo "$(_currtime) - Because of the retention policy these backups will be deleted: " | tee -a ${CLEANLOG}

for FILE in $(find ${BACKUPLOC} -type f \( -name '*.sql' -o -name '*.log' \) -mtime +${RETENTION} ! -path '*/.snapshot/*'); do
  echo "$(_currtime) - $(ls ${FILE})" | tee -a ${CLEANLOG}
  rm -f ${FILE}
done

### Change ownership to postgres user
chown postgres:postgres ${BACKUPLOC}/pgdumpall_${POSTFIX}.*
chmod 600 ${BACKUPLOC}/pgdumpall_${POSTFIX}.*

echo "$(_currtime) - Script ends"                       | tee -a ${LOGFILE} ${CLEANLOG}
exit 0
