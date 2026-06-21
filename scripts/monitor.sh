#!/bin/bash

PARENT_PID=$1
LOG_FILE=/workspace/logs/monitor.log

if [ -z "$PARENT_PID" ]; then
    echo "Usage: ./monitor.sh <parent_pid>"
    exit 1
fi

echo "=== Monitoring Parent PID: $PARENT_PID ===" >> $LOG_FILE

while true
do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if ! ps -p $PARENT_PID > /dev/null 2>&1; then
        echo "[$TIMESTAMP] Process ended." >> $LOG_FILE
        break
    fi

    # parent information
    PARENT_STATS=$(ps -p $PARENT_PID -o %cpu,rss --no-headers)

    PARENT_CPU=$(echo $PARENT_STATS | awk '{print $1}')
    PARENT_RSS=$(echo $PARENT_STATS | awk '{print $2}')

    # searching child PID 찾기
    CHILD_PID=$(ps --ppid $PARENT_PID -o pid= | xargs)

    CHILD_CPU=0
    CHILD_RSS=0

    if [ ! -z "$CHILD_PID" ]; then
        CHILD_STATS=$(ps -p $CHILD_PID -o %cpu,rss --no-headers)

        if [ ! -z "$CHILD_STATS" ]; then
            CHILD_CPU=$(echo $CHILD_STATS | awk '{print $1}')
            CHILD_RSS=$(echo $CHILD_STATS | awk '{print $2}')
        fi
    fi

    TOTAL_CPU=$(awk "BEGIN {print $PARENT_CPU + $CHILD_CPU}")
    TOTAL_RSS_KB=$((PARENT_RSS + CHILD_RSS))
    TOTAL_RSS_MB=$((TOTAL_RSS_KB / 1024))

    echo "[$TIMESTAMP] Parent:$PARENT_PID Child:${CHILD_PID:-None} CPU:${TOTAL_CPU}% MEM:${TOTAL_RSS_MB}MB" >> $LOG_FILE

    sleep 2
done
