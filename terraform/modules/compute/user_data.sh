#!/bin/bash
set -e

# ── System setup ──────────────────────────
yum update -y
yum install -y nodejs npm git

# ── App directory ─────────────────────────
mkdir -p /opt/app
cd /opt/app

# ── Write environment variables ───────────
cat > /opt/app/.env <<EOF
PORT=3000
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
S3_BUCKET=${s3_bucket}
AWS_REGION=${aws_region}
EOF

# ── Pull app code from S3 ─────────────────
# In a real pipeline this would be CodeDeploy or pull from S3 artifact
# For now we write the app inline so the instance is self-contained

cat > /opt/app/package.json <<'PKGJSON'
{
  "name": "three-tier-app",
  "version": "1.0.0",
  "main": "server.js",
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "aws-sdk": "^2.1450.0",
    "dotenv": "^16.3.1",
    "cors": "^2.8.5"
  }
}
PKGJSON

cat > /opt/app/server.js <<'SERVERJS'
require("dotenv").config();
const express = require("express");
const mysql   = require("mysql2/promise");
const AWS     = require("aws-sdk");
const cors    = require("cors");

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// AWS S3 client
const s3 = new AWS.S3({ region: process.env.AWS_REGION });

// DB connection pool
const pool = mysql.createPool({
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

// ── Init DB schema ──────────────────────
async function initDB() {
  const conn = await pool.getConnection();
  await conn.execute(`
    CREATE TABLE IF NOT EXISTS items (
      id        INT AUTO_INCREMENT PRIMARY KEY,
      name      VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);
  conn.release();
}

// ── Routes ──────────────────────────────

// Health check — ALB uses this
app.get("/health", (req, res) => res.json({ status: "ok" }));

// Home
app.get("/", (req, res) => {
  res.json({
    message: "3-Tier AWS App — running on EC2",
    region:  process.env.AWS_REGION,
    bucket:  process.env.S3_BUCKET,
  });
});

// Get all items
app.get("/items", async (req, res) => {
  try {
    const [rows] = await pool.execute("SELECT * FROM items ORDER BY created_at DESC");
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create item
app.post("/items", async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: "name is required" });
  try {
    const [result] = await pool.execute("INSERT INTO items (name) VALUES (?)", [name]);
    res.status(201).json({ id: result.insertId, name });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete item
app.delete("/items/:id", async (req, res) => {
  try {
    await pool.execute("DELETE FROM items WHERE id = ?", [req.params.id]);
    res.json({ deleted: req.params.id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// List S3 objects
app.get("/files", async (req, res) => {
  try {
    const data = await s3.listObjectsV2({ Bucket: process.env.S3_BUCKET }).promise();
    const files = (data.Contents || []).map(f => ({ key: f.Key, size: f.Size }));
    res.json(files);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Start ────────────────────────────────
initDB()
  .then(() => app.listen(PORT, () => console.log(`Server running on port ${PORT}`)))
  .catch(err => { console.error("DB init failed:", err); process.exit(1); });
SERVERJS

# ── Install dependencies & start ──────────
cd /opt/app
npm install

# Run with a simple process manager
npm install -g pm2
pm2 start server.js --name app
pm2 startup systemd -u root --hp /root
pm2 save
