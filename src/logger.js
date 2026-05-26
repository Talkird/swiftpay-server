/**
 * Simple logger utility for structured logging
 * In production, consider using Winston or Pino for advanced logging
 */

const nodeEnv = process.env.NODE_ENV || "development";

const SENSITIVE_PATTERNS = [
  "password",
  "secret",
  "token",
  "key",
  "credential",
  "aws",
  "auth",
  "cookie",
];

function redact(obj) {
  if (obj == null || typeof obj !== "object") return obj;
  if (Array.isArray(obj)) return obj.map(redact);

  const out = {};
  for (const k of Object.keys(obj)) {
    try {
      const v = obj[k];
      const lk = k.toLowerCase();
      if (SENSITIVE_PATTERNS.some((p) => lk.includes(p))) {
        out[k] = "[REDACTED]";
      } else if (typeof v === "object" && v !== null) {
        out[k] = redact(v);
      } else {
        out[k] = v;
      }
    } catch (e) {
      out[k] = "[UNAVAILABLE]";
    }
  }
  return out;
}

function emit(level, message, data = {}) {
  const timestamp = new Date().toISOString();
  const safe = redact(data);
  const payload = {
    level,
    timestamp,
    message,
    ...safe,
  };

  const out = JSON.stringify(payload);
  if (level === "ERROR") console.error(out);
  else console.log(out);
}

const logger = {
  info: (message, data = {}) => emit("INFO", message, data),
  error: (message, data = {}) => emit("ERROR", message, data),
  warn: (message, data = {}) => emit("WARN", message, data),
  debug: (message, data = {}) => {
    if (nodeEnv === "development") emit("DEBUG", message, data);
  },
};

module.exports = logger;
