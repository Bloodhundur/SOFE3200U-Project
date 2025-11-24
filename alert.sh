#!/bin/bash
# alert.sh - slack and email  implementation

ALERT_MESSAGE=$1 #message passed in from detection script
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
HOSTNAME=$(hostname)



#SLACK IMPLEMENTATION
#-----------------------------------
WEBHOOK_URL=$SLACK_WEBHOOK_URL


PAYLOAD="{
  \"blocks\": [
    {
      \"type\": \"section\",
      \"text\": {\"type\": \"mrkdwn\", \"text\": \":rotating_light: *System Alert*\"}
    },
    {
      \"type\": \"section\",
      \"text\": {\"type\": \"mrkdwn\", \"text\": \"*Host:* $HOSTNAME\"}
    },
    {
      \"type\": \"section\",
      \"text\": {\"type\": \"mrkdwn\", \"text\": \"*Time:* $TIMESTAMP\"}
    },
    {
      \"type\": \"section\",
      \"text\": {\"type\": \"mrkdwn\", \"text\": \"$ALERT_MESSAGE\"}
    }
  ]
}"

curl -X POST -H 'Content-type: application/json' \
	--data "$PAYLOAD" $WEBHOOK_URL
#-----------------------------------


#EMAIL ALERT
#-----------------------------------
RECIPIENT="syst3stm4il@gmail.com" #can be any recipient


FULL_MESSAGE="[$TIMESTAMP on $HOSTNAME] $ALERT_MESSAGE"

#send email using mail
echo "$FULL_MESSAGE" | mail -s "System Alert" $RECIPIENT
#-----------------------------------




