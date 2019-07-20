#!/usr/bin/env bash
#
# Script to check container status and report to Discord if any of them are not running
# Tronyx

# Define some variables
tempDir='/tmp/'
containerNamesFile="${tempDir}container_names.txt"
# Your webhook URL for the Discord channel you want alerts sent to
discordWebhookURL=''
# Your Discord numeric user ID
# To find your user ID just type \@<username> or \@<role>, like so \@username#1337
# It will look something like <@123492578063015834> and you NEED the exclamation point like below
discordUserID='<@!123492578063015834>'

# Function to create list of Docker containers
create_containers_list() {
  docker ps --format '{{.Names}}' |sort > "${containerNamesFile}"
}

# Function to check Docker containers
check_containers() {
  while IFS= read -r container; do
    containerStatus=$(docker inspect "${container}" |jq .[].State.Status |tr -d '"')
    if [ "${containerStatus}" = 'running' ];then
      :
    elif [ "${containerStatus}" = 'exited' ];then
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "'"${discordUserID}"' The '"${container}"' container is currently stopped!"}' "${discordWebhookURL}"
    elif [ "${containerStatus}" = 'dead' ];then
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "'"${discordUserID}"'The '"${container}"' container is currently dead!"}' "${discordWebhookURL}"
    elif [ "${containerStatus}" = 'restarting' ];then
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "'"${discordUserID}"'The '"${container}"' container is currently restarting!"}' "${discordWebhookURL}"
    elif [ "${containerStatus}" = 'paused' ];then
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "'"${discordUserID}"'The '"${container}"' container is currently paused!"}' "${discordWebhookURL}"
    else
      curl -s -H "Content-Type: application/json" -X POST -d '{"content": "'"${discordUserID}"'The '"${container}"' container currently has an unknown status!"}' "${discordWebhookURL}"
    fi
  done < <(cat "${containerNamesFile}")
}

# Main function to run all other functions
main() {
  create_containers_list
  check_containers
}

main
