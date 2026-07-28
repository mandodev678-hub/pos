const path = require('path');
const express = require('express');
const http = require('http');

// Manual proxy: forwards requests to backend on port 3001
function proxyToBackend(req, res) {
    const options = {
        hostname: 'localhost',
        port: 3001,
        path: req.url,
        method: req.method,
        headers: { ...req.headers, host: 'localhost:3001' },
    };
    const proxyReq = http.request(options, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res, { end: true });
    });
    proxyReq.on('error', (err) => {
        res.status(502).json({ message: 'Backend not reachable', error: err.message });
    });
    req.pipe(proxyReq, { end: true });
}

// Helper to serve static SPA build on a given port
function serveApp(name, port, dirPath) {
    const app = express();

    // Proxy /api requests to backend on port 3001
    app.use('/api', (req, res) => {
        req.url = '/api' + req.url;
        proxyToBackend(req, res);
    });

    app.use(express.static(dirPath));
    app.get('*', (req, res) => {
        res.sendFile(path.join(dirPath, 'index.html'));
    });
    app.listen(port, '0.0.0.0', () => {
        console.log(`✅ ${name} is serving on http://localhost:${port}`);
    });
}

// 1. Serve Frontends
serveApp('POS App (الكاشير)', 3002, path.join(__dirname, 'pos/dist'));
serveApp('Website App (الموقع)', 3000, path.join(__dirname, 'website/dist'));
serveApp('KDS Kitchen (المطبخ)', 3003, path.join(__dirname, 'kds/dist'));

// 2. Start Backend Server
console.log('🚀 Starting Backend Server on port 3001...');
require('./backend/src/server.js');
