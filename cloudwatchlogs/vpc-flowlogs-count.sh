#!/usr/bin/env bash
PHPD='$d = file_get_contents("php://stdin")'
JSONDECODE='$d = json_decode('"$PHPD"');'

# start-time end-time period statistics
function main() {
  m=`aws logs describe-log-streams --log-group-name $1`
  p='$d = $d->logStreams;
 date_default_timezone_set("Asia/Singapore");
 foreach ($d as $i) echo implode(",", [
  $i->logStreamName,
  $i->storedBytes,
  date("Y-m-d H:i:s", $i->lastIngestionTime/1000),
  date("Y-m-d H:i:s", $i->lastEventTimestamp/1000),
  date("Y-m-d H:i:s", $i->firstEventTimestamp/1000),
  date("Y-m-d H:i:s", $i->creationTime/1000)]);'


  echo "logStreamName,storedBytes,lastIngestionTime,lastEventTimestamp,firstEventTimestamp,creationTime"
  echo "$m" | php -r "$JSONDECODE""$p"
}

main "$1"
