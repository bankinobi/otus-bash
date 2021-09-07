#!/bin/bash

# Script files
LOCKFILE=/tmp/web-cron.pid
LOGFILE=/tmp/web-cron.log

# Determine dates
DATE="`date +"%d/%b/%Y:%H"`"
DATE_LOG="`date +"%d/%b/%Y %H:%M:%S"`"
DATE_HOUR_AGO="`date --date="1 hour ago" +"%d/%b/%Y:%H"`"
DATE_ERROR="`date --date="1 hour ago" +"%Y/%m/%d %H"`"

# Target log files
ACCESS_LOG=/vagrant/access.log
ERROR_LOG=/vagrant/error.log

# Sendmail
MAIL_ADDR=$1

# Send report
report()
{
(
cat - <<END
Subject: Otus report
From: test@localhost
To: $MAIL_ADDR

Web server report:

Logs scanned from $DATE_HOUR_AGO to $DATE.

Requests from IP addresses:

${ADDR[@]}

Requested URLs:

${URLS[@]}

Response codes:

${RESPONSE[@]}

Errors occurred:

${ERRORS[@]}
END
) | /usr/sbin/sendmail $MAIL_ADDR
}

# Parse logs and send report
if [ -e $LOCKFILE ]
then
        echo "$DATE_LOG --> Script is running!" >> $LOGFILE 2>&1
        exit 1
else
        echo "$$" > $LOCKFILE
        trap 'rm -f $LOCKFILE; exit $?' INT TERM EXIT
        ADDR+=$(grep "$DATE_HOUR_AGO" $ACCESS_LOG | awk '{print $1}' | sort | uniq -c | sort -nr | head)
        URLS+=$(grep "$DATE_HOUR_AGO" $ACCESS_LOG | grep -Pio '(?<=GET|POST).*(?=HTTP/1.1")' | sort | uniq -c | sort -nr | head)
        RESPONSE+=$(grep "$DATE_HOUR_AGO" $ACCESS_LOG | grep -Pio '(?<=HTTP/1.1").*(?=(\s\d*\s"-"))' | sort | uniq -c | sort -nr)
        ERRORS+=$(grep "$DATE_ERROR" $ERROR_LOG | head)
        report
        rm -rf $LOCKFILE
        trap - INT TERM EXIT
        echo "$DATE_LOG --> Report sent!" >> $LOGFILE 2>&1
fi
