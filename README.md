# PostgreSQL Scripts

## pg-backup.sh
This script creates a full PostgreSQL database backup

### Files
- pgdumpall_HOSTNAME_DATETIME.clog >>  List all deleted files, if backup retention of 30 days is reached and file gets deleted
- pgdumpall_HOSTNAME_DATETIME.log >> Show log of pg_dumpall execution
- pgdumpall_HOSTNAME_DATETIME.sql >> Logical backup file from pg_dumpall

### Requirements
- The script **pg-backup.sh** should be placed for security reasons with 700 permissions to the home-directory of the user, for example: /home/postgres
- The file **pg-backup.conf** should be placed for security reasons with 400 permissions to the home-directory of the user, for example: /home/postgres
- The **.pgpass** should be placed for security reasons with 600 permissions to the home-directory
   - In order to authenticate pg_dumpall against to the database the file .pgpass with a username and password must be available.
```
postgres@itk480yr:~ $ ll -la
-rwx------. 1 postgres postgres  701 Feb 16 11:19 pg-backup.sh
-rw-------. 1 postgres postgres   38 Feb 13 13:02 .pgpass
```
- It is best practise to create a dedicated db user which is caring about the backup and not use the default super user "postgres". Here I created user "backup".
  - ROLE pg_read_all_data which is available at PG version >= 14 can be used to restrict access
  - Restore operation would be done with a superuse then
```
SQL> CREATE USER backup WITH ENCRYPTED PASSWORD '<password>'; 
SQL> GRANT pg_read_all_data to backup;
```
```
postgres@server:~ $ cat /home/postgres/.pgpass
*:*:*:backup:MYPASSWORD
```
- More information can be read here: https://www.postgresql.org/docs/current/libpq-pgpass.html.

### Scheduling
The script can be regulary scheduled at crontab for example:
```
server:~ $ crontab -l
#PostgreSQL backup task
0 22 * * * /home/postgres/pg-backup.sh
```
### Backup flow visualisation
![image](https://github.com/dbfriend/pgscripts/assets/118447736/a14d6d65-8254-4245-9d07-62d64b9d8eb7)

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
