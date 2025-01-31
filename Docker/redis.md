# Init redis document for later usage purpose

## Redis Stack
```sh
docker run -d --name redis-stack-server -p 6379:6379 redis/redis-stack-server:latest
```

```bash
# Create a directory for redis01
docker run --rm -v sql2022-edmtime:/bitnami/redis/data busybox mkdir -p /bitnami/redis/data/redis01

# Create a redis master container and point to directory
docker run -d -p 6379:6379 \
    --name redis-master \
    --network mynet \
    -v sql2022-edmtime:/bitnami/redis/data/redis01 \
    -e REDIS_REPLICATION_MODE=master \
    -e REDIS_PASSWORD=123456 \
    bitnami/redis:latest

```

```bash
docker run --rm -v sql2022-edmtime:/bitnami/redis/data busybox mkdir -p /bitnami/redis/data/redis02

# Create a redis slave container and point to directory
docker run -d -p 6380:6379 \
    --name redis-slave \
    --network mynet \
    -v sql2022-edmtime:/bitnami/redis/data/redis02 \
    -e REDIS_REPLICATION_MODE=slave \
    -e REDIS_MASTER_HOST=redis-master \
    -e REDIS_MASTER_PORT_NUMBER=6379 \
    -e REDIS_MASTER_PASSWORD=123456 \
    -e REDIS_PASSWORD=123456 \
    bitnami/redis:latest

```
