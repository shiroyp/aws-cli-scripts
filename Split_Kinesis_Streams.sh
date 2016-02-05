#!/bin/bash

STREAM_NAME=$1
SHARD_STATE=$(aws kinesis describe-stream --stream-name $STREAM_NAME --query StreamDescription.StreamStatus | sed 's/\"//g')
aws kinesis describe-stream --stream-name $STREAM_NAME --query StreamDescription.Shards[*].[ShardId,HashKeyRange.StartingHashKey,HashKeyRange.EndingHashKey] --output text | awk '{print $1, ($2+$3)/2}' | while read SHARD_ID NEW_STARTING_HASH_KEY
do
        echo -ne "Waiting for the stream $STREAM_NAME to be Active"
        until [[ $SHARD_STATE = ACTIVE ]]; do
                #statements
                sleep 3
                echo -ne "."
                SHARD_STATE=$(aws kinesis describe-stream --stream-name $STREAM_NAME --query StreamDescription.StreamStatus | sed 's/\"//g')
        done
        echo -e "\tOK"
        echo -ne "Splitting shard $SHARD_ID\t"
        aws kinesis split-shard --stream-name $STREAM_NAME --shard-to-split $SHARD_ID --new-starting-hash-key $NEW_STARTING_HASH_KEY && echo "Done" || echo "Failed"
        SHARD_STATE=$(aws kinesis describe-stream --stream-name $STREAM_NAME --query StreamDescription.StreamStatus | sed 's/\"//g')
done

SHARD_STATE=$(aws kinesis describe-stream --stream-name $STREAM_NAME --query StreamDescription.StreamStatus | sed 's/\"//g')
echo -ne "Waiting for the stream $STREAM_NAME to be Active"
until [[ $SHARD_STATE = ACTIVE ]]; do
        #statements
        sleep 3
        echo -ne "."
        SHARD_STATE=$(aws kinesis describe-stream --stream-name $STREAM_NAME --query StreamDescription.StreamStatus | sed 's/\"//g')
done
echo -e "\tOK"
