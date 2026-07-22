/**
 * Simple proxy server for NVIDIA API
 * This avoids CORS issues by making API calls server-side
 */

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const NVIDIA_API_KEY = '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';

// MIME types
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
  console.log(`${req.method} ${req.url}`);

  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle OPTIONS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // API proxy endpoint
  if (req.url === '/api/chat' && req.method === 'POST') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const requestData = JSON.parse(body);
        console.log('📤 Proxying request to NVIDIA API...');
        
        // Prepare NVIDIA API request
        const postData = JSON.stringify(requestData);
        
        const options = {
          hostname: 'integrate.api.nvidia.com',
          port: 443,
          path: '/v1/chat/completions',
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${NVIDIA_API_KEY}`,
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(postData)
          }
        };
        
        // Make request to NVIDIA
        const proxyReq = https.request(options, (proxyRes) => {
          let responseBody = '';
          
          proxyRes.on('data', (chunk) => {
            responseBody += chunk;
          });
          
          proxyRes.on('end', () => {
            console.log(`✅ NVIDIA API responded: ${proxyRes.statusCode}`);
            res.writeHead(proxyRes.statusCode, {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            });
            res.end(responseBody);
          });
        });
        
        proxyReq.on('error', (error) => {
          console.error('❌ Proxy error:', error.message);
          res.writeHead(500, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ error: 'Proxy error: ' + error.message }));
        });
        
        proxyReq.write(postData);
        proxyReq.end();
        
      } catch (error) {
        console.error('❌ Parse error:', error.message);
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid request body' }));
      }
    });
    
    return;
  }

  // Serve static files
  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './index.html';
  }

  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = mimeTypes[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 - File Not Found</h1>', 'utf-8');
      } else {
        res.writeHead(500);
        res.end('Server Error: ' + error.code, 'utf-8');
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log('🚀 Server running on:');
  console.log(`   http://localhost:${PORT}`);
  console.log('');
  console.log('✅ AI Chat proxy enabled at: http://localhost:${PORT}/api/chat');
  console.log('');
  console.log('Press Ctrl+C to stop the server');
});
