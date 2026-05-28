const express = require("express");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const logger = require("./logger");

const app = express();
const port = process.env.PORT || 3000;
const nodeEnv = process.env.NODE_ENV || "development";

//Token alejo test

// Security Middleware
// Hide framework fingerprint
app.disable("x-powered-by");

// Set secure HTTP headers
app.use(helmet());

// Content Security Policy - API only (minimal restrictive policy)
app.use(
  helmet.contentSecurityPolicy({
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      objectSrc: ["'none'"],
      imgSrc: ["'self'", "data:"],
      baseUri: ["'self'"],
      frameAncestors: ["'none'"],
    },
  }),
);

// Note: CORS is managed externally (AWS), so no in-app CORS handling here.

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path} - ${req.ip}`);
  next();
});

// Rate limiting middleware - adjust based on your needs
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply rate limiting to all routes
app.use(limiter);

// Parse JSON with size limits
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", environment: nodeEnv });
});

// Main application endpoint
app.get("/", (req, res) => {
  res.status(200).json({
    message: "SwiftPay Server",
    version: "1.0.0",
    status: "running",
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error(`Error: ${err.message}`, { stack: err.stack });

  const status = err.status || 500;
  const message =
    nodeEnv === "production" ? "Internal Server Error" : err.message;

  res.status(status).json({
    error: {
      message,
      status,
    },
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

// Start server
const server = app.listen(port, "127.0.0.1", () => {
  logger.info(
    `SwiftPay Server running on port ${port} in ${nodeEnv} environment`,
  );
});

// Graceful shutdown
process.on("SIGTERM", () => {
  logger.info("SIGTERM signal received: closing HTTP server");
  server.close(() => {
    logger.info("HTTP server closed");
    process.exit(0);
  });
});

module.exports = app;
