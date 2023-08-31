#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
# https://stackoverflow.com/a/71738522/5371505
# https://www.shellcheck.net/ VERIFIED
set -e
set -E
set -o pipefail
set -u
set -x

IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

# https://stackoverflow.com/a/64616137/5371505
log="dump-elasticache-to-s3.log"
exec 2>"$log"

# https://stackoverflow.com/questions/64786/error-handling-in-bash/185900#185900
handle_error() {    
    log_message="$(< "$log")"
    local from;
    local to;
    local subject;
    local text;
    from="cron@coinhexa.com"
    to="coinhexa@gmail.com"
    subject="Elasticache dump encountered an error at $(date)"
    text="Elasticache dump encountered an error at line:$(caller) while running:${BASH_COMMAND} due to the error:${log_message}"
    aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
    # echo "subject: ${subject}"
    # echo "text: ${text}"
    exit 1
}

handle_exit() {
    if [ $? -eq 0 ]; then
        log_message="$(< "$log")"
        local from;
        local to;
        local subject;
        local text;
        from="cron@coinhexa.com"
        to="coinhexa@gmail.com"
        subject="Elasticache dump completed successfully at $(date)"
        text="Elasticache dump completed successfully and files were uploaded to S3 ${log_message}"
        aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
        # echo "subject: ${subject}"
        # echo "text: ${text}"
    fi

    # Delete the error log file
    rm "dump-elasticache-to-s3.log"
}

# https://stackoverflow.com/questions/76787024/why-is-the-exit-code-always-0-inside-handle-exit-and-how-to-distinguish-error-fr
trap 'handle_exit $?' EXIT
trap 'handle_error $?' ERR

# https://stackoverflow.com/a/46577479/5371505
export AWS_DEFAULT_REGION="us-east-1"
cache_cluster_id="test-ch-cluster-001"
current_time="$(date +"%Y-%m-%d-%H-%M-%S")";
file_name="${cache_cluster_id}-${current_time}";
max_number_of_backups_to_keep=10;
target_bucket="test-ch-backups-elasticache"

# {"Snapshot":{"SnapshotName":"test-ch-cluster-001-2023-08-14-17-29-17","CacheClusterId":"test-ch-cluster-001","SnapshotStatus":"creating","SnapshotSource":"manual","CacheNodeType":"cache.t3.micro","Engine":"redis","EngineVersion":"7.0.7","NumCacheNodes":1,"PreferredAvailabilityZone":"us-east-1b","CacheClusterCreateTime":"2023-07-25T03:37:02.646000+00:00","PreferredMaintenanceWindow":"sun:10:00-sun:11:00","Port":23431,"CacheParameterGroupName":"default.redis7","CacheSubnetGroupName":"test-ch-subnet-group","VpcId":"vpc-06bf4837a223cf33b","AutoMinorVersionUpgrade":true,"SnapshotRetentionLimit":7,"SnapshotWindow":"09:00-10:00","NodeSnapshots":[{"CacheNodeId":"0001","CacheSize":"","CacheNodeCreateTime":"2023-07-25T03:37:02.646000+00:00"}],"ARN":"arn:aws:elasticache:us-east-1:288534097102:snapshot:test-ch-cluster-001-2023-08-14-17-29-17"}}
snapshot_status=$(aws elasticache create-snapshot --cache-cluster-id "${cache_cluster_id}" --snapshot-name "${file_name}");

echo "${snapshot_status}"

# While number of snapshots with a status of creating is more than 0, wait
while [ "$(aws elasticache describe-snapshots --cache-cluster-id "${cache_cluster_id}" --query "Snapshots[?SnapshotStatus=='creating']" | grep -c SnapshotStatus)" -gt 0 ]
do
    echo "Snapshot creation not complete, waiting...$(date)";
    sleep 120
done

# {"Snapshot":{"SnapshotName":"test-ch-cluster-001-2023-08-14-18-49-03","CacheClusterId":"test-ch-cluster-001","SnapshotStatus":"exporting","SnapshotSource":"manual","CacheNodeType":"cache.t3.micro","Engine":"redis","EngineVersion":"7.0.7","NumCacheNodes":1,"PreferredAvailabilityZone":"us-east-1b","CacheClusterCreateTime":"2023-07-25T03:37:02.646000+00:00","PreferredMaintenanceWindow":"sun:10:00-sun:11:00","Port":23431,"CacheParameterGroupName":"default.redis7","CacheSubnetGroupName":"test-ch-subnet-group","VpcId":"vpc-06bf4837a223cf33b","AutoMinorVersionUpgrade":true,"SnapshotRetentionLimit":7,"SnapshotWindow":"09:00-10:00","NodeSnapshots":[{"CacheNodeId":"0001","CacheSize":"6 MB","CacheNodeCreateTime":"2023-07-25T03:37:02.646000+00:00","SnapshotCreateTime":"2023-08-14T13:19:30+00:00"}],"ARN":"arn:aws:elasticache:us-east-1:288534097102:snapshot:test-ch-cluster-001-2023-08-14-18-49-03"}}
export_status=$(aws elasticache copy-snapshot --source-snapshot-name "${file_name}" --target-snapshot-name "${file_name}" --target-bucket "${target_bucket}");

echo "${export_status}"

# https://gist.github.com/luckyjajj/463b98e5ec8127b21c6b
# Check if number of stored backups is 8
# Check if number of stored backups is 8
if [ "$(aws elasticache describe-snapshots --cache-cluster-id "${cache_cluster_id}" --query "Snapshots[?SnapshotSource=='manual']" |grep -c SnapshotName)"  -gt "${max_number_of_backups_to_keep}" ]; then
    # Get the name of the oldest snapshot
    old_snapshot=$(aws elasticache describe-snapshots --cache-cluster-id "${cache_cluster_id}" --query "Snapshots[?SnapshotSource=='manual']" | grep SnapshotName | head -1 | cut -d \" -f 4)
    aws elasticache delete-snapshot --snapshot-name "${old_snapshot}"
    echo "Deleted oldest snapshot ${old_snapshot}"
else
    echo "No older snapshots to delete currently so exiting..."
fi
