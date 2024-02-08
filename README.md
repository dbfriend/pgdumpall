# pgdumpall
This script creates a full PostgreSQL database backup

## Files
- pgdumpall_HOSTNAME_DATETIME.clog >>  List all deleted files, if backup retention of 30 days is reached and file gets deleted
- pgdumpall_HOSTNAME_DATETIME.log >> Show log of pg_dumpall execution
- pgdumpall_HOSTNAME_DATETIME.sql >> Logical backup file from pg_dumpall

## Requirements
In order to authenticate pg_dumpall against to the database a file called .pgpass with a username and password must be available.
More information can be read here: https://www.postgresql.org/docs/current/libpq-pgpass.html

It is best practise to create a dedicated db user which is caring about the backup and not use the default super user "postgres"
```
postgres@server:~ $ cat /var/lib/pgsql/.pgpass
*:*:*:backup:MYPASSWORD
```

## Scheduling
The script can be regulary scheduled at crontab for example:
```
server:~ $ crontab -l
#PostgreSQL backup task
0 22 * * * /var/lib/pgsql/pg-backup.sh
```
