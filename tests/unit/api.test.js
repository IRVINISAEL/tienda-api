const { test, before, after } = require('node:test');
const assert = require('node:assert');
const app = require('../../app/app');

let server, base;
before(() => new Promise(r => { server = app.listen(0, () => { base = `http://localhost:${server.address().port}`; r(); }); }));
after(() => server.close());

test('GET /health responde ok', async () => {
  const r = await fetch(`${base}/health`);
  assert.strictEqual(r.status, 200);
  assert.strictEqual((await r.json()).status, 'ok');
});

test('GET /api/productos devuelve lista', async () => {
  const r = await fetch(`${base}/api/productos`);
  const data = await r.json();
  assert.ok(Array.isArray(data) && data.length > 0);
});

test('GET /metrics expone métricas Prometheus', async () => {
  const r = await fetch(`${base}/metrics`);
  assert.match(await r.text(), /http_request_duration_seconds/);
});
