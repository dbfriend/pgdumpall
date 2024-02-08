#!/bin/bash

### Set environment
BACKUPLOC=/var/SP/postgres/backup
USER=backup
POSTFIX=${HOSTNAME}_$(date +"%Y%m%d%H%M")
PGDUMPALL=/usr/bin/pg_dumpall
CLEANLOG=${BACKUPLOC}/pgdumpall_${POSTFIX}.clog
export PGPASSFILE=/var/lib/pgsql/.pgpass

### Do the actual work
${PGDUMPALL} -v -c -U ${USER} -f ${BACKUPLOC}/pgdumpall_${POSTFIX}.sql 2> ${BACKUPLOC}/pgdumpall_${POSTFIX}.log

### Delete backups and its logs which are older than 30 days
find ${BACKUPLOC} -type f \( -name '*.sql' -o -name '*.log' \) -mtime +30 -delete | tee -a ${CLEANLOG}

### Change ownership to postgres user
chown postgres:postgres ${BACKUPLOC}/pgdumpall_${POSTFIX}.*
chmod 600 ${BACKUPLOC}/pgdumpall_${POSTFIX}.*

exit 0
