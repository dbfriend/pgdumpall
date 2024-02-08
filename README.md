# pgdumpall
This script creates a full PostgreSQL database backup

## Files
- pgdumpall_HOSTNAME_DATETIME.clog  >>  List all deleted files, if backup retention of 30 days is reached and file gets deleted
- pgdumpall_HOSTNAME_DATETIME.log  >> Show log og pg_dumpall execution
- pgdumpall_HOSTNAME_DATETIME.sql  >> Logical backup file from pg_dumpall

## Scheduling
The script can be regulary scheduled at crontab for example:
```
cim2ci00031do:~ $ crontab -l
#Vodafone PostgreSQL backup task
0 22 * * * /var/lib/pgsql/pg-backup.sh
```
