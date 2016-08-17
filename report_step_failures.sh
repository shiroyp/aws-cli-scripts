#!/bin/bash
rpmquery jq &> /dev/null || yum install -y jq
[ -f ~/.failed_steps ] || touch ~/.failed_steps

JOBFLOW_ID=$(jq .jobFlowId /mnt/var/lib/info/job-flow.json | sed 's/"//g')
SNS_TOPIC_ARN=$1

aws emr list-steps --cluster-id $JOBFLOW_ID --query Steps[].[Status.State,Id,Name] --output text | awk '$1 == "FAILED" {print $0}' | while read STATE STEP_ID NAME
do

        if ! grep $STEP_ID ~/.failed_steps &> /dev/null
        then
                 aws sns publish --topic-arn $SNS_TOPIC_ARN --subject "Step failed in cluster $JOBFLOW_ID" --message "Cluster: $JOBFLOW_ID,Step: $STEP_ID,Step Name: $NAME"
                 echo $STEP_ID >> ~/.failed_steps
        fi
done
