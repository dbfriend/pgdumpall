# PostgreSQL Scripts

## pg-backup.sh
This script creates a full PostgreSQL database backup

### Files
- pgdumpall_HOSTNAME_DATETIME.clog >>  List all deleted files, if backup retention of 30 days is reached and file gets deleted
- pgdumpall_HOSTNAME_DATETIME.log >> Show log of pg_dumpall execution
- pgdumpall_HOSTNAME_DATETIME.sql >> Logical backup file from pg_dumpall

### Requirements
- In order to authenticate pg_dumpall against to the database a file called .pgpass with a username and password must be available.
- The **PGPASS-file** as well as the script **pg-backup.sh** should be placed for security reasons to the home-directory of the user, for example: /home/postgres
- More information can be read here: https://www.postgresql.org/docs/current/libpq-pgpass.html.
- It is best practise to create a dedicated db user which is caring about the backup and not use the default super user "postgres"
```
postgres@server:~ $ cat /home/postgres/.pgpass
*:*:*:backup:MYPASSWORD
```

### Scheduling
The script can be regulary scheduled at crontab for example:
```
server:~ $ crontab -l
#PostgreSQL backup task
0 22 * * * /home/postgres/pg-backup.sh
```

## postgresql-banner.sh
- This small script shows some basic information about the PostgreSQL database.
- It should be placed at location "/etc/profile.d/postgresql-banner.sh" with 644 permissions to become active for every OS user
