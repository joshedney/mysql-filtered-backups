#!/usr/bin/env bash

set -euo pipefail

# Check config
if [ ! -f "$1" ]; then
    echo 'Config file could not be found'
    exit 1
fi

# Load config
. "$1"

if [[ -z "$MHOST" || -z "$MPASS" || -z "$MHOST" || -z "$FULLS3BUCKET" || -z "$FILTEREDS3BUCKET " ]]; then
    echo "Please check your config file"
    exit 1
fi

./wait-for-it.sh --host=$MHOST --port=3306 -t 20

(
    flock -n -e 200 || exit 1

    # Grab a list of tables which should be stripped of their data
    FILTERTABLES=$(
        (
            while read line; do
                echo -n "${line}|"
            done <./filtered-tables
        ) | sed -e 's/|\+$//g'
    )

    backup_db() {
        # Set up dates
        NOW=$(date +"%Y-%m-%d")
        NOWYEAR=$(date +"%Y")
        NOWMONTH=$(date +"%m")

        # Grab a full database backup and compress it
        echo "$(date) ${db}: Creating dump of ${db}..."
        FULLBACKUPFILE=$(mktemp -p /mnt/tmp)
        mysqldump --set-gtid-purged=off --skip-lock-tables --single-transaction --user="$MUSER" --host="$MHOST" --password="$MPASS" "$db" | gzip >"$FULLBACKUPFILE"

        # Filter the backup file
        echo "$(date) ${db}: Filtering backup..."
        FILTEREDBACKUPFILE=$(mktemp -p /mnt/tmp)
        gunzip <"$FULLBACKUPFILE" | grep -avE "INSERT INTO \`(${FILTERTABLES})\` VALUES " | gzip >"$FILTEREDBACKUPFILE"

        # Copy the backups to S3
        echo "$(date) ${db}: Uploading to S3..."
        aws s3 cp "$FULLBACKUPFILE" s3://"$FULLS3BUCKET"/"$NOWYEAR"/"$NOWMONTH"/"$NOW"/"$db".$(date +"%Y-%m-%d-%T").full.gz
        aws s3 cp "$FILTEREDBACKUPFILE" s3://"$FILTEREDS3BUCKET"/"$NOWYEAR"/"$NOWMONTH"/"$NOW"/"$db".$(date +"%Y-%m-%d-%T").filtered.gz

        # Cleanup
        rm "$FULLBACKUPFILE"
        rm "$FILTEREDBACKUPFILE"
        echo "$(date) ${db}: Backup complete"
    }

    # Launch a backup thread for every database
    DBS="$(mysql -u "$MUSER" -h "$MHOST" -p"$MPASS" -Bse 'show databases')"
    for db in $DBS; do
        case $db in
        "information_schema") ;;
        "mysql") ;;
        "innodb") ;;
        "performance_schema") ;;
        "sys") ;;
        "tmp") ;;
        *)
            backup_db "$db" &
            sleep 120
            ;;
        esac
    done

) 200>/var/lock/mysql_backup_$(basename $1)
