#!/bin/bash

PID=$1
LOG_FILE=/workspace/logs/monitor.log

if [ -z "$PID" ]; then
    echo "Usage: ./monitor.sh <PID>"
    exit 1
fi

echo "=== Monitoring PID: $PID ===" >> $LOG_FILE

while true
do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    STATS=$(ps -p $PID -o %cpu,%mem --no-headers)

    if [ -z "$STATS" ]; then
        echo "[$TIMESTAMP] Process ended." >> $LOG_FILE
        break
    fi

    CPU=$(echo $STATS | awk '{print $1}')
    MEM=$(echo $STATS | awk '{print $2}')

    echo "[$TIMESTAMP] PID:$PID CPU:${CPU}% MEM:${MEM}%" >> $LOG_FILE

    sleep 2
done
