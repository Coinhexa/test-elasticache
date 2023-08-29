const Redis = require("ioredis");

const REDIS_SESSION_DB = +process.env.REDIS_SESSION_DB || 0;
const REDIS_HOST = process.env.REDIS_HOST || "localhost";
const REDIS_PASSWORD = process.env.REDIS_PASSWORD || "";
const REDIS_PORT = +process.env.REDIS_PORT || 6379;
const REDIS_TLS = process.env.REDIS_TLS === "true" ? {} : false;
const logger = console;

const redisClient = new Redis({
  db: REDIS_SESSION_DB,
  host: REDIS_HOST,
  password: REDIS_PASSWORD,
  port: REDIS_PORT,
  tls: REDIS_TLS,
});

redisClient.on("error", (error) => {
  if (error.code === "ECONNRESET") {
    logger.error("Error: redis client connection reset");
  } else if (error.code === "ECONNREFUSED") {
    logger.error("Error: redis client connection refused");
  } else {
    logger.error(error, "Error: redis client");
  }
});

redisClient.on("reconnecting", (ts) => {
  if (redisClient.status === "reconnecting") {
    logger.info("Notice: redis client reconnecting...");
  } else {
    logger.warn("Error: redis client reconnect failed");
  }
});

redisClient.on("connect", (error) => {
  if (!error) {
    logger.info("Success: redis client connected");
  }
});

(async function () {
  try {
    let response = await redisClient.ping();
    logger.log("ping", response);
    response = await redisClient.set("hello", "world");
    logger.log("set hello", response);
    response = await redisClient.get("hello");
    logger.log("get hello", response);
    response = await redisClient.del("hello");
    logger.log("del hello", response);
    response = await redisClient.get("hello");
    logger.log("get hello", response);
  } catch (error) {
    logger.error(error);
  } finally {
    redisClient.quit();
  }
})();
