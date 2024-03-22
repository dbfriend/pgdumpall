# PostgreSQL Scripts

## pg-backup.sh
This script creates a full PostgreSQL database backup

### Files
- pgdumpall_HOSTNAME_DATETIME.clog >>  List all deleted files, if backup retention of 30 days is reached and file gets deleted
- pgdumpall_HOSTNAME_DATETIME.log >> Show log of pg_dumpall execution
- pgdumpall_HOSTNAME_DATETIME.sql >> Logical backup file from pg_dumpall

### Requirements
- The script **pg-backup.sh** should be placed for security reasons with 700 permissions to the home-directory of the user, for example: /home/postgres
- The file **pg-backup.conf** should be placed for security reasons with 600 permissions to the home-directory of the user, for example: /home/postgres
- The **.pgpass** should be placed for security reasons with 600 permissions to the home-directory
   - In order to authenticate pg_dumpall against to the database the file .pgpass with a username and password must be available.
- It is best practise to create a dedicated db user which is caring about the backup and not use the default super user "postgres". Here I created user "backup".
  - ROLE pg_read_all_data which is available at PG version >= 14 can be used to restrict access
  - Restore operation would be done with a superuse then
```
SQL> CREATE USER backup WITH ENCRYPTED PASSWORD '<password>'; 
SQL> GRANT pg_read_all_data to backup;
```
```
$ cat /home/postgres/.pgpass
*:*:*:backup:MYPASSWORD
```
- More information can be read here: https://www.postgresql.org/docs/current/libpq-pgpass.html.

### Typical FS layout
```
$ mkdir -p $HOME/scripts/pg-backup
$ cp pg-backup.conf pg-backup.sh .pgpass $HOME/scripts/pg-backup
$ ls -la $HOME/scripts/pg-backup
-rw-------. 1 postgres postgres  534 Mar 22 09:15 pg-backup.conf
-rwx------. 1 postgres postgres 4688 Mar 22 09:15 pg-backup.sh
-rw-------. 1 postgres postgres   28 Mar 22 09:15 .pgpass
```

### Scheduling
The script can be regulary scheduled at crontab for example:
```
$ crontab -l
#PostgreSQL backup task
0 22 * * * /home/postgres/scripts/pg-backup/pg-backup.sh
```
### Backup flow visualisation
![GitHub Image](pg-backup-process-flow.png)

## postgresql-banner.sh
- This small script shows some basic information about the PostgreSQL database.
- It should be placed at location "/etc/profile.d/postgresql-banner.sh" owned by root with 644 permissions to become active for every OS user
Output:
```
########################################################
     This is a PostgreSQL database server!
########################################################

postgresql.service: active
PGDATA: /var/SP/postgres/pgdata
Port: 5432
```
