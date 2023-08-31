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
log="restore-elasticache-to-docker.log"
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
    subject="Elasticache restore encountered an error at $(date)"
    text="Elasticache restore encountered an error at line:$(caller) while running:${BASH_COMMAND} due to the error:${log_message}"
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
        subject="Elasticache restore completed successfully at $(date)"
        text="Elasticache restore completed successfully ${log_message} ${result}"
        aws ses send-email --from "${from}" --subject "${subject}" --text "${text}" --to "${to}"
        # echo "subject: ${subject}"
        # echo "text: ${text}"
    fi

    # Stop the container that was created
    docker stop "${container_name}" && docker rm "${container_name}"

    # Delete the rdb file
    rm "${dump_file_directory}/${dump_file_name}"

    # Delete the error log file
    rm "restore-elasticache-to-docker.log"
}

# https://stackoverflow.com/questions/76787024/why-is-the-exit-code-always-0-inside-handle-exit-and-how-to-distinguish-error-fr
trap 'handle_exit $?' EXIT
trap 'handle_error $?' ERR

# https://stackoverflow.com/a/46577479/5371505
export AWS_DEFAULT_REGION="us-east-1"
bucket='test-ch-backups-elasticache'
container_name="my_redis_container"
dump_file_directory="$HOME"
host="localhost"
port="6379"
redis_version="7.2.0"
result=""

# https://stackoverflow.com/a/31064378/5371505
dump_file_name=$(aws s3 ls $bucket --recursive | sort | tail -n 1 | awk '{print $4}')

aws s3 cp "s3://${bucket}/${dump_file_name}"  "${dump_file_directory}/${dump_file_name}"

# https://stackoverflow.com/a/44364288/5371505
docker ps -aq --filter "name=${container_name}" | grep -q . && docker stop "${container_name}" && docker rm -fv "${container_name}"

# Run the Docker container
# https://stackoverflow.com/questions/60362470/start-redis-inside-docker-container-with-redis-dump-without-compose
docker run --detach --name "${container_name}" --publish "${port}:${port}" --volume "${dump_file_directory}/${dump_file_name}:/data/dump.rdb" "redis:${redis_version}"

# Wait for the Docker container to be ready
until docker exec -it "${container_name}" redis-cli -h "${host}" -p "${port}" ping; do
    echo "Waiting for redis container to be up $(date)"
    sleep 10
done

# HOW TO VERIFY IF REDIS WAS RESTORED SUCCESSFULLY HERE???
result=$(docker exec "${container_name}" redis-cli -h "${host}" -p "${port}" keys '*')
