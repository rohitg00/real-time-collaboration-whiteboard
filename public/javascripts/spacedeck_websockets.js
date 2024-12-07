SpacedeckWebsockets = {
  data: {
    users_online: {},
    cursors: {},
    clientId: null
  },
  methods: {
    handle_live_updates: function(msg) {
      if (msg.model == "Space" && msg.object) {
        if (msg.object.space_type == "space") {
          if (this.active_space) {
            if (this.active_space._id == msg.object._id) {
              this.active_space = _.merge(this.active_space, msg.object);
            }
          }
        }
      }

      if (msg.model == "Message") {
        if (msg.action == "create" && msg.object) {
          var new_message = msg.object;
          if(this.active_space && this.active_space._id == new_message.space._id) {
            this.active_space_messages.push(new_message);
            this.refresh_space_comments();
          } else console.log("message created in another space.");
        }
      }

      if (msg.model == "Artifact") {
        if (msg.action == "create" && msg.object) {
          var new_artifact = msg.object;
          if (this.active_space && this.active_space._id == new_artifact.space_id) {
            var o = new_artifact;

            if (o._id && !this.find_artifact_by_id(o._id)) {
              this.update_board_artifact_viewmodel(new_artifact);
              this.active_space_artifacts.push(new_artifact)
            } else {
              console.log("warning: got create on existing artifact.");
              msg.action = "update"; // hackety hack!
            }
          } else console.log("artifact created in another space.");
        }
        else if ((msg.action == "update" || msg.action == "update-self") && msg.object) {
          if (msg.action == "update-self") {
            console.log(msg.object);
          }

          if (this.active_space) {
            var o = msg.object;
            if (o && o._id) {
              var existing_artifact = this.find_artifact_by_id(o._id);
              if (!existing_artifact) {
                existing_artifact = o;
              } else {
                for (key in o) {
                  existing_artifact[key] = o[key];
                  this.update_board_artifact_viewmodel(existing_artifact);
                }
              }
            }
          }
        }
        else if (msg.action == "delete" && msg.object) {
          if (this.active_space) {
            var o = msg.object;
            if (o._id){
              var existing_artifact = this.find_artifact_by_id(o._id);
              if (existing_artifact) {
                var idx = this.active_space_artifacts.indexOf(existing_artifact);
                this.active_space_artifacts.splice(idx, 1);
              } else console.log("existing artifact to delete not found");
            } else console.error("object without _id");
          }
        }
      }
    },

    subscribe: function(space) {
      if (this.websocket && this.websocket.readyState==1) {
        this.websocket.send(JSON.stringify({action: "subscribe", space_id: space._id}));
      } else {
        console.error("socket not ready yet. (subscribe)");
      }
    },

    is_member_online: function(space, member) {
      if (!member.user) {
        return false;
      }

      if (!this.users_online[space._id]) {
        return false;
      }

      var isOnline = _.find(this.users_online[space._id], function(u) {
        return (u._id == member.user._id);
      });

      return isOnline;
    },

    auth_websocket: function(space){
      if (!this.websocket) {
        this.init_websocket();
      }

      if (this.websocket && this.websocket.readyState==1) {
        var token = "";
        if (this.user) token = this.user.token;
        var auth_params = {
          action: "auth",
          editor_auth: space_auth,
          editor_name: this.guest_nickname,
          auth_token: token,
          space_id: space._id
        };
        console.log("[websocket] auth space");
        this.websocket.send(JSON.stringify(auth_params));
      }
    },

    websocket_send: function(msg) {
      if (!this.websocket) return;
      if (this.websocket.readyState!=1) return;

      try {
        this.websocket.send(JSON.stringify(msg));
      } catch (e) {
        // catch NS problems
      }
    },

    init_websocket: function() {
      if (this.websocket) this.websocket = null;

      if (this.current_timeout) {
        clearTimeout(this.current_timeout);
        this.current_timeout = null;
      }

      try {
        this.websocket = new WebSocket(ENV.websocketsEndpoint + "/socket");
      } catch (e) {
        console.log("[websocket] cannot establish websocket connection: ",e);
        this.current_timeout = setTimeout(function() {
          console.log("[websocket] reconnecting", e);
          this.init_websocket();
        }.bind(this),5000);
      }

      if (!this.websocket) {
        console.log("[websocket] no websocket support?");
        return;
      }

      this.websocket.onopen = function(evt) {
        if (this.current_timeout) {
          clearTimeout(this.current_timeout);
          this.current_timeout = null;
        }

        if (this.active_space_loaded) {
          this.auth_websocket(this.active_space);
        }
        this.online = true;

      }.bind(this);

      this.websocket.onclose = function(evt) {
        if (!window._spacedeck_location_change) {
          this.online = false;
        }

        if (!this.current_timeout) {
          this.current_timeout = setTimeout(function() {
            console.log("[websocket] onclose: reconnecting", evt);
            this.init_websocket();
          }.bind(this),5000);
        }
      }.bind(this);

      this.websocket.onmessage = function(evt) {
        try {
          var msg = JSON.parse(evt.data);
          
          if (msg.type === 'connected') {
            this.clientId = msg.id;
          }

          if (msg.action === "cursor") {
            this.handle_cursor_update(msg);
            return;
          }

          // Handle other message types
          switch(msg.type) {
            case 'cursor_move':
              this.updateCursor(msg.clientId, msg.cursor);
              break;
            case 'user_joined':
              this.addUser(msg.clientId, msg.user);
              break;
            case 'user_left':
              this.removeUser(msg.clientId);
              break;
            default:
              this.handle_live_updates(msg);
          }
        } catch (e) {
          console.error('WebSocket message error:', e);
        }
      }.bind(this);

      this.websocket.onerror = function(evt) {
        console.log("websocket.onerror:", evt);
        if (!window._spacedeck_location_change) {
          this.online = false;
          this.was_offline = true;
        }

        if (!this.current_timeout) {
          this.current_timeout = setTimeout(function() {
            console.log("websocket.onerror: reconnecting", evt);
            this.init_websocket();
          }.bind(this),5000);
        }

      }.bind(this);

      // Send cursor position periodically
      document.addEventListener('mousemove', _.throttle(function(e) {
        if (this.websocket && this.websocket.readyState === WebSocket.OPEN && this.active_space) {
          this.websocket.send(JSON.stringify({
            action: 'cursor',
            space_id: this.active_space._id,
            client_id: this.clientId,
            x: e.pageX,
            y: e.pageY,
            nickname: this.user?.nickname || this.guest_nickname || 'Anonymous'
          }));
        }
      }.bind(this), 16));

      // Add cursor styles dynamically
      const style = document.createElement('style');
      style.textContent = `
        .remote-cursor {
          position: fixed;
          pointer-events: none;
          z-index: 99999;
          transform: translate3d(0,0,0);
          transition: transform 0.08s cubic-bezier(0.23, 1, 0.32, 1);
          will-change: transform;
        }
        .cursor-pointer {
          width: 12px;
          height: 12px;
          background: #FF6B6B;
          border-radius: 50%;
          border: 2px solid white;
          box-shadow: 0 0 4px rgba(0,0,0,0.5);
        }
        .cursor-label {
          position: absolute;
          left: 15px;
          top: -18px;
          padding: 3px 8px;
          color: white;
          font-size: 12px;
          white-space: nowrap;
          border-radius: 4px;
          background: inherit;
        }
      `;
      document.head.appendChild(style);
    },

    updateCursor: function(clientId, cursor) {
      if (clientId === this.clientId) return;

      let cursorEl = this.cursors[clientId];
      if (!cursorEl) {
        cursorEl = document.createElement('div');
        cursorEl.className = 'remote-cursor';
        cursorEl.innerHTML = `
          <div class="cursor-pointer" style="background-color: ${cursor.color}"></div>
          <div class="cursor-label" style="background-color: ${cursor.color}">
            ${cursor.nickname}
          </div>
        `;
        document.body.appendChild(cursorEl);
        this.cursors[clientId] = cursorEl;
      }

      cursorEl.style.transform = `translate3d(${cursor.x}px, ${cursor.y}px, 0)`;
    },

    addUser: function(clientId, user) {
      this.users_online[clientId] = user;
      // Update UI to show active users
    },

    removeUser: function(clientId) {
      delete this.users_online[clientId];
      if (this.cursors[clientId]) {
        this.cursors[clientId].remove();
        delete this.cursors[clientId];
      }
    },

    handle_cursor_update: function(msg) {
      if (msg.client_id === this.clientId) return;
      
      this.updateCursor(msg.client_id, {
        x: msg.x,
        y: msg.y,
        nickname: msg.nickname,
        color: msg.color
      });
    }
  }
}
