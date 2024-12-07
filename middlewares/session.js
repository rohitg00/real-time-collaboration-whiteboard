"use strict";

const db = require("../models/db");
var config = require("config");

module.exports = (req, res, next) => {
  // authentication via API token
  const api_token = req.headers["x-spacedeck-api-token"];

  if (api_token && api_token.length > 7) {
    db.User.findOne({ where: { api_token: api_token } }).then((user) => {
      if (user) {
        req.user = user;
        next();
      } else {
        res.status(403).json({
          error: "invalid_api-token",
        });
      }
    });

    return;
  }

  // authentication via session/cookie
  let token = req.cookies["sdsession"];

  if (!token || token == "null") {
    // authentication via session/header
    token = req.headers["x-spacedeck-auth"];
  }

  if (token && token !== "null") {
    db.Session.findOne({ where: { token: token } })
      .then((session) => {
        if (!session) {
          next();
        } else {
          db.User.findOne({ where: { _id: session.user_id } }).then((user) => {
            if (!user) {
              res.clearCookie("sdsession");
              res.status(403).json({ error: "token_not_found" });
            } else {
              req.token = token;
              req.user = user;
              next();
            }
          });
        }
      })
      .catch((err) => {
        console.error("Session resolve error", err);
        next();
      });
  } else {
    next();
  }
};
