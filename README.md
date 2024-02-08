# pgdumpall
This script creates 

## Files
pgdumpall_<HOSTNAME>_<DATETIME>.clog  >>  List all deleted files, if backup retention of 30 days is reached and file gets deleted
pgdumpall_<HOSTNAME>_<DATETIME>.log  >> Show log og pg_dumpall execution
pgdumpall_<HOSTNAME>_<DATETIME>.sql  >> Logical backup file from pg_dumpall

## Scheduling
The script can be regulary scheduled at crontab for example:

cim2ci00031do:~ $ crontab -l
#Vodafone PostgreSQL backup task
0 22 * * * /var/lib/pgsql/pg-backup.sh
