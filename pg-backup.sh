#!/bin/bash
################################################################################################
#### Scripname:         pg-backup.sh
#### Description:       This is script is performing a PostgreSQL backup and is deleting older dumps
#### Version:           1.0
################################################################################################

### Set environment
BACKUPLOC=/var/SP/postgres/backup
USER=backup
POSTFIX=${HOSTNAME}_$(date +"%Y%m%d%H%M")
PGDUMPALL=/usr/bin/pg_dumpall
CLEANLOG=${BACKUPLOC}/pgdumpall_${POSTFIX}.clog
export PGPASSFILE=/var/lib/pgsql/.pgpass


#### Time Function for logs
_currtime() {
  echo "$(date +"%Y-%m-%dT%H:%M:%S.%3N%z")"
}

STARTECHO="$(_currtime) - Script start"
echo ${STARTECHO}

### Check backup dir
if [ ! -d "${BACKUPLOC}" ]; then
  echo "$(_currtime) - Backup dir ${BACKUPLOC} doesn't exists, abort"
  echo "$(_currtime) - Script ends"
  exit 1
fi

### Create log-file
touch ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
chown postgres:postgres ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
chmod 600 ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
echo ${STARTECHO} >> "${BACKUPLOC}/pgdumpall_${POSTFIX}.log"

#### Check if pg_dumpall-binaries exists
if [ ! -x ${PGDUMPALL} ]; then
  echo "$(_currtime) - Cannot find pg_dumpall at location ${PGDUMPALL}, abort" | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  echo "$(_currtime) - Script ends"                                            | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  mv ${BACKUPLOC}/pgdumpall_${POSTFIX}.log ${BACKUPLOC}/pgdumpall_${POSTFIX}.log.FAILED
  exit 1
fi

### Check if password file is available
if [ ! -f ${PGPASSFILE} ]; then
  echo "$(_currtime) - Cannot find password-file (pgpass) at location ${PGPASSFILE}, abort" | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  echo "$(_currtime) - Script ends"                                            | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  mv ${BACKUPLOC}/pgdumpall_${POSTFIX}.log ${BACKUPLOC}/pgdumpall_${POSTFIX}.log.FAILED
  exit 1
fi

### Do the actual work
echo "$(_currtime) - Progressing ..." | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
${PGDUMPALL} -v -c -U ${USER} -f ${BACKUPLOC}/pgdumpall_${POSTFIX}.sql >> ${BACKUPLOC}/pgdumpall_${POSTFIX}.log 2>&1
BCK_RC=${?}

#### Error handling
if [ ${BCK_RC} -ne 0 ]; then
  tail -2 ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  echo "$(_currtime) - Dump failed, abort"      | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  echo "$(_currtime) - Script ends"             | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
  mv ${BACKUPLOC}/pgdumpall_${POSTFIX}.log ${BACKUPLOC}/pgdumpall_${POSTFIX}.log.FAILED
  exit 1
fi

### Delete backups and its logs which are older than 30 days
find ${BACKUPLOC} -type f \( -name '*.sql' -o -name '*.log' \) -mtime +30 -delete | tee -a ${CLEANLOG}

### Change ownership to postgres user
chown postgres:postgres ${BACKUPLOC}/pgdumpall_${POSTFIX}.*
chmod 600 ${BACKUPLOC}/pgdumpall_${POSTFIX}.*

echo "$(_currtime) - Backup completed successfully."    | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
echo "$(_currtime) - Script ends"                       | tee -a ${BACKUPLOC}/pgdumpall_${POSTFIX}.log
exit 0
