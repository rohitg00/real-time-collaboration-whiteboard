'use strict';

const WebSocket = require('ws');
const _ = require('underscore');
const db = require('../models/db.js');
const config = require('config');
const redis = require('./redis');
const consensus = require('./consensus');

function WebsocketHelper() {
  this.wss = null;
  this.clients = {};
  this.redisPublisher = null;
  this.redisSubscriber = null;
  this.userCursors = new Map(); // Track user cursors
}

WebsocketHelper.prototype.startWebsockets = function(server) {
  // Initialize Redis clients
  const redisClients = redis.connectRedis();
  if (redisClients) {
    this.redisPublisher = redisClients.pub;
    this.redisSubscriber = redisClients.sub;
  }

  if (!this.redisPublisher && !config.get('redis_mock')) {
    console.error('[websocket] Failed to initialize Redis clients');
    return;
  }

  this.wss = new WebSocket.Server({
    server: server,
    path: "/socket"
  });

  this.wss.on('connection', (ws) => {
    const clientId = Math.random().toString(36).substring(7);
    this.clients[clientId] = ws;
    consensus.addNode(clientId);

    // Store client info
    ws.clientId = clientId;
    ws.activeSpace = null;
    ws.userInfo = null;

    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        
        // Handle different message types
        switch(data.type) {
          case 'cursor_move':
            this.handleCursorMove(clientId, data);
            break;
          case 'join_space':
            ws.activeSpace = data.space_id;
            ws.userInfo = {
              nickname: data.nickname,
              color: data.color || this.getRandomColor()
            };
            this.broadcastToSpace(ws.activeSpace, {
              type: 'user_joined',
              user: ws.userInfo,
              clientId: clientId
            });
            break;
          default:
            this.handleMessage(clientId, data);
        }
      } catch (e) {
        console.error('WebSocket message error:', e);
      }
    });

    ws.on('close', () => {
      if (ws.activeSpace) {
        this.broadcastToSpace(ws.activeSpace, {
          type: 'user_left',
          clientId: clientId
        });
      }
      delete this.clients[clientId];
      this.userCursors.delete(clientId);
      consensus.removeNode(clientId);
    });

    // Send initial heartbeat
    ws.send(JSON.stringify({ 
      type: 'connected', 
      id: clientId 
    }));
  });

  // Subscribe to Redis updates
  if (this.redisSubscriber) {
    this.redisSubscriber.subscribe('whiteboard-updates', (err) => {
      if (err) console.error('Redis subscription error:', err);
    });

    this.redisSubscriber.on('message', (channel, message) => {
      if (channel === 'whiteboard-updates') {
        try {
          const data = JSON.parse(message);
          switch (data.action) {
            case 'cursor':
              this.broadcastToSpace(data.space_id, {
                type: 'cursor_move',
                clientId: data.client_id,
                cursor: {
                  x: data.x,
                  y: data.y,
                  nickname: data.nickname,
                  color: data.color
                }
              });
              break;
            case 'cursor_move':
              this.broadcastCursorMove(data);
              break;
            case 'create':
            case 'update':
            case 'delete':
              this.broadcast(data);
              break;
            case 'auth':
              this.handleAuth(data);
              break;
            default:
              console.log('[websocket] Unknown message action:', data.action);
          }
        } catch (e) {
          console.error('Redis message parse error:', e);
        }
      }
    });
  }
};

WebsocketHelper.prototype.handleCursorMove = function(clientId, data) {
  const client = this.clients[clientId];
  if (!client || !client.activeSpace) return;

  this.userCursors.set(clientId, {
    x: data.x,
    y: data.y,
    nickname: client.userInfo?.nickname || 'Anonymous',
    color: client.userInfo?.color
  });

  this.broadcastToSpace(client.activeSpace, {
    type: 'cursor_move',
    clientId: clientId,
    cursor: this.userCursors.get(clientId)
  });
};

WebsocketHelper.prototype.broadcastToSpace = function(spaceId, data) {
  Object.values(this.clients).forEach(client => {
    if (client.readyState === WebSocket.OPEN && client.activeSpace === spaceId) {
      try {
        client.send(JSON.stringify(data));
      } catch (e) {
        console.error('Broadcast error:', e);
      }
    }
  });
};

WebsocketHelper.prototype.getRandomColor = function() {
  const colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEEAD'];
  return colors[Math.floor(Math.random() * colors.length)];
};

WebsocketHelper.prototype.handleMessage = function(clientId, data) {
  if (consensus.isLeader(clientId)) {
    // Leader can broadcast directly
    this.broadcast(data);
    if (this.redisPublisher) {
      this.redisPublisher.publish('whiteboard-updates', JSON.stringify(data))
        .catch(err => console.error('Redis publish error:', err));
    }
  } else {
    // Followers forward to leader
    const leaderId = consensus.leader;
    if (leaderId && this.clients[leaderId]) {
      this.clients[leaderId].send(JSON.stringify(data));
    }
  }
};

WebsocketHelper.prototype.broadcast = function(data) {
  Object.values(this.clients).forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      try {
        client.send(JSON.stringify(data));
      } catch (e) {
        console.error('Broadcast error:', e);
      }
    }
  });
};

WebsocketHelper.prototype.handleAuth = function(data) {
  const client = Object.values(this.clients).find(c => c.clientId === data.client_id);
  if (client) {
    client.activeSpace = data.space_id;
    client.userInfo = {
      nickname: data.editor_name || 'Anonymous',
      color: this.getRandomColor()
    };

    // Broadcast user joined with their color
    this.broadcastToSpace(data.space_id, {
      type: 'user_joined',
      clientId: client.clientId,
      user: {
        nickname: client.userInfo.nickname,
        color: client.userInfo.color
      }
    });
  }
};

module.exports = new WebsocketHelper();
