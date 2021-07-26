# MySQL Filtered Backups

Take a backup of all the MySQL databases on a server and create a full and filtered backup file and upload them to the relevant S3 buckets within AWS.

## Installation

Create a folder for the `backup.sh` script.

`mkdir /var/lib/mysql-backup/`

Place the `backup.sh` and the `filtered-tables` folder in the newly created folder.

Edit the `filtered-tables` file and add the names of tables that you wish to exclude from the filtered backups.

Place the `backup.conf` file in a folder within `/etc`. For example `mkdir /etc/mysql-backups`

Edit the `backup.conf` to include the following information.

```
MUSER="" <-- MySQL Username
MPASS="" <-- MySQL Password
MHOST="" <-- MySQL Host
FULLS3BUCKET="" <-- Full Backup S3 bucket name
FILTEREDS3BUCKET="" <-- Filtered Backup S3 bucket name
```

Create a cron in the `/etc/cron.d/` folder with the following command.

```
0 23 * * *  root    /var/lib/mysql-backup/backup.sh /etc/mysql-backup/backup.conf >> /var/log/mysql-backup.log 2>&1
```

This will run the backup script every night at 11PM.

## Usage

To test the backup script, run the following command.

```
/var/lib/mysql-backup/backup.sh /etc/mysql-backup/backup.conf
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)