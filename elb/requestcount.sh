#!/usr/bin/env bash
PHPD='$d = file_get_contents("php://stdin")'
JSONDECODE='$d = json_decode('"$PHPD"');'

# start-time end-time period statistics
function main() {
 l=`listAll`

 while read -r line; do
  getRequestCount "$1" "$2" "$3" "$4" "$line"
 done <<< "$l"
}

function listAll() {
 m="$(aws cloudwatch list-metrics --namespace AWS/ELB --metric-name RequestCount)"
 p='$d = $d->Metrics;
$all = array();
$k = 0;
foreach ($d as $i) {
 $itm = array();
 foreach ($i->Dimensions as $j) $itm[] = "Name=".$j->Name.",Value=".$j->Value;
 if (false === strpos(($itm = implode(" ", $itm)), "Name=LoadBalancerName")) continue;
 $all[] = $itm;
 $k ++;
}
echo implode("\n", $all);'

 echo "$m" | php -r "$JSONDECODE""$p"
}

function getRequestCount() {
 m=`aws cloudwatch get-metric-statistics \
  --metric-name RequestCount \
  --start-time "$1" --end-time "$2" \
  --period "$3" --namespace 'AWS/ELB' --statistics "$4" \
  --dimensions "$5"`

 dp=`echo "$m" | php -r "$JSONDECODE"'if (!empty($d->Datapoints[1])) { $d = $d->Datapoints[1]; echo $d->Sum, ",", $d->Unit, ",", $d->Timestamp; } else echo ",,";'`
 echo "\"$5\",$dp"
}

# main "2017-08-07T00:00:00" "2017-08-14T17:00:00" 604800 Sum
main "$1" "$2" "$3" "$4"
