/**
 * Simple logger utility for structured logging
 * In production, consider using Winston or Pino for advanced logging
 */

const nodeEnv = process.env.NODE_ENV || "development";

const logger = {
  info: (message, data = {}) => {
    const timestamp = new Date().toISOString();
    console.log(
      JSON.stringify({
        level: "INFO",
        timestamp,
        message,
        ...data,
      }),
    );
  },

  error: (message, data = {}) => {
    const timestamp = new Date().toISOString();
    console.error(
      JSON.stringify({
        level: "ERROR",
        timestamp,
        message,
        ...data,
      }),
    );
  },

  warn: (message, data = {}) => {
    const timestamp = new Date().toISOString();
    console.warn(
      JSON.stringify({
        level: "WARN",
        timestamp,
        message,
        ...data,
      }),
    );
  },

  debug: (message, data = {}) => {
    if (nodeEnv === "development") {
      const timestamp = new Date().toISOString();
      console.log(
        JSON.stringify({
          level: "DEBUG",
          timestamp,
          message,
          ...data,
        }),
      );
    }
  },
};

module.exports = logger;
