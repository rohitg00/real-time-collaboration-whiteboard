'use strict';

const Redis = require('ioredis');
const config = require('config');

let redisClient = null;
let redisSubscriber = null;

module.exports = {
  connectRedis: function() {
    if (redisClient && redisSubscriber) return { pub: redisClient, sub: redisSubscriber };

    if (config.get('redis_mock')) {
      console.log("[redis] using mock implementation");
      return null;
    }

    const redisConfig = {
      host: config.get('redis_host'),
      port: 6379,
      password: config.get('redis_password'),
      retryStrategy: function(times) {
        const delay = Math.min(times * 50, 2000);
        console.log(`[redis] retrying connection in ${delay}ms`);
        return delay;
      }
    };

    try {
      // Create separate clients for pub/sub
      redisClient = new Redis(redisConfig);
      redisSubscriber = new Redis(redisConfig);

      redisClient.on('connect', () => {
        console.log('[redis] publisher connected to redis server');
      });

      redisSubscriber.on('connect', () => {
        console.log('[redis] subscriber connected to redis server');
      });

      const errorHandler = (err) => {
        console.error('[redis] Error:', err);
      };

      redisClient.on('error', errorHandler);
      redisSubscriber.on('error', errorHandler);

      return { pub: redisClient, sub: redisSubscriber };
    } catch (err) {
      console.error('[redis] Connection error:', err);
      return null;
    }
  },

  getClient: function() {
    return redisClient;
  },

  getSubscriber: function() {
    return redisSubscriber;
  },

  sendMessage: function(action, model, object, channelId) {
    if (!redisClient) return;

    const message = {
      action: action,
      model: model,
      object: object,
      channel: channelId
    };

    try {
      redisClient.publish('whiteboard-updates', JSON.stringify(message))
        .catch(err => console.error('[redis] Publish error:', err));
    } catch (err) {
      console.error('[redis] Send message error:', err);
    }
  },

  set: function(key, value, callback) {
    if (config.get('redis_mock')) return callback(null, "OK");
    if (!redisClient) return callback(new Error("Redis not connected"));
    
    redisClient.set(key, value, callback);
  },

  get: function(key, callback) {
    if (config.get('redis_mock')) return callback(null, null);
    if (!redisClient) return callback(new Error("Redis not connected"));
    
    redisClient.get(key, callback);
  },

  del: function(key, callback) {
    if (config.get('redis_mock')) return callback(null, 1);
    if (!redisClient) return callback(new Error("Redis not connected"));
    
    redisClient.del(key, callback);
  },

  publish: function(channel, message, callback) {
    if (config.get('redis_mock')) return callback ? callback(null) : null;
    if (!redisClient) return callback ? callback(new Error("Redis not connected")) : null;
    
    redisClient.publish(channel, message, callback);
  },

  subscribe: function(channel, callback) {
    if (config.get('redis_mock')) return callback ? callback(null) : null;
    if (!redisSubscriber) return callback ? callback(new Error("Redis not connected")) : null;
    
    redisSubscriber.subscribe(channel, callback);
  },

  unsubscribe: function(channel, callback) {
    if (config.get('redis_mock')) return callback ? callback(null) : null;
    if (!redisSubscriber) return callback ? callback(new Error("Redis not connected")) : null;
    
    redisSubscriber.unsubscribe(channel, callback);
  }
};

