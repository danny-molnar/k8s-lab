const express = require('express');
const app = express();
const port = process.env.PORT || 80;

const APP_ENV = process.env.APP_ENV || 'unknown';
const APP_MESSAGE = process.env.APP_MESSAGE || 'no message configured';
const API_KEY = process.env.API_KEY || null;

app.get('/', (req, res) => {
  res.json({
    app: 'demo-app',
    env: APP_ENV,
    message: APP_MESSAGE,
    apiKeyPresent: !!API_KEY,
    timestamp: new Date().toISOString()
  });
});

app.get('/healthz', (req, res) => {
  // Basic liveness – if process is up, we're good
  res.status(200).send('ok');
});

app.get('/readyz', (req, res) => {
  // Simple readiness – we could add real checks later
  res.status(200).send('ready');
});

app.listen(port, () => {
  console.log(`demo-app listening on port ${port}`);
});
