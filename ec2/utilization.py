import sys
import boto3
import datetime

if len(sys.argv) < 2:
    print("python utilization.py <cloudwatchlogs.logGroupName>")
    sys.exit(1)

flowlogName = sys.argv[1]

timeformat = "%Y-%m-%dT%H:%M:%S"
title = ['ReservationId', 'InstanceId', 'NetworkInterfaceId', 'InstanceType', 'StateName', 'LaunchTime', 'NetworkLogStoredBytes', 'NetworkLastIngestionTime', 'NetworkLastEventTimestamp', 'NetworkFirstEventTimestamp', 'NetworkLogCreationTime', 'Tags']
acceptedtags = ['Name', 'Client', 'Stage', 'Requester']
csv = []

logs = boto3.client('logs')
ec2 = boto3.client('ec2')

response = ec2.describe_instances()


def microtimetstr( time ):
    return datetime.datetime.fromtimestamp(time//1000.0).strftime(timeformat)

def defFlowLogMap( flowlogName, networkInterfaceId ):
    flowlog = logs.describe_log_streams(logGroupName=flowlogName, logStreamNamePrefix="%s-all" % (networkInterfaceId))
    flowlog = flowlog['logStreams']
    r = {
        'lastIngestionTime': '',
        'lastEventTimestamp': '',
        'firstEventTimestamp': '',
        'creationTime': '',
        'storedBytes': 0
    }

    if len(flowlog) > 0:
        flowlog = flowlog[len(flowlog) - 1]
        r['lastIngestionTime'] = microtimetstr(flowlog['lastIngestionTime'])
        r['lastEventTimestamp'] = microtimetstr(flowlog['lastEventTimestamp'])
        r['firstEventTimestamp'] = microtimetstr(flowlog['firstEventTimestamp'])
        r['creationTime'] = microtimetstr(flowlog['creationTime'])
        r['storedBytes'] = flowlog['storedBytes']

    return r

for i, reservation in enumerate(response['Reservations']):
    for j, instance in enumerate(reservation['Instances']):
        tags = []

        for k, tag in enumerate(instance['Tags']):
            if tag['Key'] in acceptedtags:
                tags.append("%s:%s" % (tag['Key'], tag['Value']))

        for l, networkinterface in enumerate(instance['NetworkInterfaces']):
            networkInterfaceId = networkinterface['NetworkInterfaceId']
            flowlog = defFlowLogMap(flowlogName, networkInterfaceId)

            row = [
                reservation['ReservationId'],
                instance['InstanceId'],
                networkInterfaceId,
                instance['InstanceType'],
                instance['State']['Name'],
                instance['LaunchTime'].strftime(timeformat),
                str(flowlog['storedBytes']),
                flowlog['lastIngestionTime'],
                flowlog['lastEventTimestamp'],
                flowlog['firstEventTimestamp'],
                flowlog['creationTime'],
                '"%s"' % (','.join(tags))
            ]

            csv.append(','.join(row))

print(','.join(title))
print("\n".join(csv))
