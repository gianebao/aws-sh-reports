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
  date("Y-m-d H:i:s", $i->lastIngestionTime),
  date("Y-m-d H:i:s", $i->lastEventTimestamp),
  date("Y-m-d H:i:s", $i->firstEventTimestamp),
  date("Y-m-d H:i:s", $i->creationTime)]);'


  echo "logStreamName,storedBytes,lastIngestionTime,lastEventTimestamp,firstEventTimestamp,creationTime"
  echo "$m" | php -r "$JSONDECODE""$p"
}

main "$1"
