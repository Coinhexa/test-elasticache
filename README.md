# Test elasticache

## Resources

- [Install eslint](https://eslint.org/docs/latest/use/getting-started)
- [Install prettier, husky](https://prettier.io/docs/en/install.html)
- [Redis security group](https://stackoverflow.com/questions/56564457/aws-redis-security-group-example)
- [Encryption in transit](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/in-transit-encryption-enable.html)
- [Install redis-cli on Amazon Linux 2](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/GettingStarted.ConnectToCacheNode.html)
- [Install nvm on Amazon Linux 2](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html)
- [Install nvm on Amazon Linux 2 as user data script does not work but works when run manually](https://www.reddit.com/r/aws/comments/14t6j0h/install_nvm_node_on_amz_linux_2_ec2_instance_with/)
- [Install node on Amazon Linux 2](https://techviewleo.com/how-to-install-nodejs-on-amazon-linux/?expand_article=1)
- [Install epel](https://repost.aws/knowledge-center/ec2-enable-epel)
- [Install s3cmd](https://stackoverflow.com/questions/35643286/no-package-s3cmd-available)
- [Install AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [redis_save.sh](https://gist.github.com/ptaoussanis/6250564)
- [A Backup Script To Move Redis RDBs and AOF to S3](https://gist.github.com/alxschwarz/7e9dfc551265448c51d2515df58e0238)
- [Backup MySQL to Amazon S3](https://gist.github.com/oodavid/2206527?permalink_comment_id=3362643)
- [mysql-aws-s3-backup.sh](https://gist.github.com/jessekanner/c60d0444f3c55ba217c9a538be50b178)
- [Save Amazon ElastiCache Redis to file dump.rdb](https://gist.github.com/lmmendes/15c65fb77aec523e836d032b48eee77b)
- [backup-redis](https://gist.github.com/khoa-le/94c5758bf40f8ddc61cbfca90a0fc198)
- [Bash script to dump and restore postgres DB on another host](https://gist.github.com/suhirotaka/c0d76b25450d016ece0ee84d813e5d9e)
- [How to copy production database on AWS RDS(postgresql) to local development database](https://gist.github.com/syafiqfaiz/5273cd41df6f08fdedeb96e12af70e3b)
- [Hacky AWS ElastiCache Hourly Backup Shell Script](https://gist.github.com/luckyjajj/463b98e5ec8127b21c6b)
- [SSH into ElastiCache - Redis](https://gist.github.com/mlsaito/c6ca2827baa2382334d9be4583060b51)
- [pg_dump and upload to S3 using s3cmd](https://gist.github.com/allanlei/1537335)
- [Database backup/restore via S3](https://gadelkareem.com/2019/06/11/database-backup-restore-via-s3/)

## Purpose

- Check if our EC2 instance can connect with elasticache

## How to run

### Localhost

    REDIS_SESSION_DB=0 REDIS_HOST=localhost REDIS_PASSWORD=c6eakLo3p1WwbcBCmsJQ REDIS_PORT=6379 REDIS_TLS=false node index

### AWS

    REDIS_SESSION_DB=0 REDIS_HOST=master.test-elasticache.bmjevo.use1.cache.amazonaws.com REDIS_PASSWORD=testELASTICACHEinstance REDIS_PORT=23431 REDIS_TLS=true node index

### redis-cli

    redis-cli -h master.test-elasticache.bmjevo.use1.cache.amazonaws.com --tls -a testELASTICACHEinstance -p 23431 -n 0
