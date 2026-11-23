const express = require('express');
const client = require('prom-client');

const app = express();
app.use(express.json());
client.collectDefaultMetrics();

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duración de peticiones HTTP',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.05, 0.1, 0.3, 0.5, 1, 2]
});

app.use((req, res, next) => {
  const end = httpDuration.startTimer();
  res.on('finish', () => end({ method: req.method, route: req.path, status: res.statusCode }));
  next();
});

const productos = [
  { id: 1, nombre: 'Laptop', precio: 15000 },
  { id: 2, nombre: 'Mouse', precio: 250 }
];

app.get('/health', (_req, res) => res.json({ status: 'ok', version: process.env.APP_VERSION || 'dev' }));
app.get('/api/productos', (_req, res) => res.json(productos));
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

module.exports = app;
