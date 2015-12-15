#!/bin/bash

# bashbot, the Telegram bot written in bash.
# Written by @topkecleon and Juan Potato (@awkward_potato)
# http://github.com/topkecleon/bashbot

# Depends on JSON.sh (http://github.com/dominictarr/JSON.sh),
# which is MIT/Apache-licensed.

# This file is public domain in the USA and all free countries.
# If you're in Europe, and public domain does not exist, then haha.

echo "Telegram bot dir:"$(pwd)
. global
#MESSAGE="$@"
OFFSET=0

{
  res=$(curl "$URL/getMe")
  bot_username=$(echo $res | ./JSON.sh -s | egrep '\["result","username"\]' | cut -f 2 | cut -d '"' -f 2)
} &>/dev/null
echo "Bot username:$bot_username"

#buttons="{\"keyboard\":[[\"sensors\",\"raid_status\"]],\"one_time_keyboard\":true}"

#Starting in stand by mode
prevActiveTime=0

./sendNotify -l2 -t "Bot started at $hostname"

while true; do {
  newMessage=0
  while [ $newMessage -eq 0 ]; do
    {
      res=$(curl $URL\/getUpdates\?offset=$OFFSET\&limit=1)
      if [ ! "$res" == '{"ok":true,"result":[]}' ]; then
        newMessage=1
        TARGET=$(echo $res | ./JSON.sh | egrep '\["result",0,"message","chat","id"\]' | cut -f 2)
        from=$(echo $res | ./JSON.sh | egrep '\["result",0,"message","from","username"\]' | cut -f 2)
        OFFSET=$(echo $res | ./JSON.sh | egrep '\["result",0,"update_id"\]' | cut -f 2)
        MESSAGE=$(echo $res | ./JSON.sh -s | egrep '\["result",0,"message","text"\]' | cut -f 2 | cut -d '"' -f 2)
        message_id=$(echo $res | ./JSON.sh | egrep '\["result",0,"message","message_id"\]' | cut -f 2 )
        echo "o:$OFFSET r:$res"
      fi
    } &>/dev/null
	done

  curTime=$((10#`date +%s`))
  OFFSET=$((OFFSET+1))
  #echo "$MESSAGE"

  if [ $OFFSET != 1 ]; then
    echo "$OFFSET">lastOffset
    msgWords=($MESSAGE)
    cmd=${msgWords[0]}
    args=("${msgWords[@]:1}") #removed the 1st element
    #echo "cmd: $cmd"
    toHost="$hostname"
    drive=""
    notifyLevel=-1
    msg=""
    #echo "args:${args[@]}"
    unset OPTIND
    while getopts ":d: :s:" opt "${args[@]}"; do
      case $opt in
        s)
          if [[ "$OPTARG" =~ [^0-9]+ ]]; then
            msg="Only numbers"
            cmd=""
          else
            if [ $((10#$OPTARG)) -le 3 ] && [ $((10#$OPTARG)) -ge 0 ]; then
              notifyLevel=$((10#$OPTARG))
              echo "Good notify level $notifyLevel"
            else
              msg="Level must be from 0 to 3"
              cmd=""
            fi
          fi
          ;;
        d)
          drive=`echo "$OPTARG" | cut -c 1-3`;;
        :)
          toHost=""
          msg="Option -$OPTARG requires an argument.";;
      esac
    done

    echo "from:$from Message:$MESSAGE"

    cmdAr=(${cmd//\@/ })
    cmd=${cmdAr[0]}
    toBot=${cmdAr[1]}
    #echo "c:$cmd t:$toBot"
    if [ ! "$toBot" == "" ] && [ ! "$toBot" == "$bot_username" ]; then
      echo "To other bot $toBot"
      cmd=""
    fi
    #include a case from file commands
    . commands

    if [ ! -z "$msg" ]; then
      prevActiveTime=$curTime
      send_message "$TARGET" "$msg"
    fi
  fi

  elapsed=$((curTime-prevActiveTime))

  if [ $elapsed -le $standByAfter ]; then
    if [ $cycleSleep -gt 0 ]; then
      sleep $cycleSleep
    fi
  else
    sleep $cycleSleepStandBy
  fi

} done
