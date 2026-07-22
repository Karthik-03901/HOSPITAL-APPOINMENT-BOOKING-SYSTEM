@echo off
echo ========================================
echo Starting TOTP Backend API Server
echo ========================================
echo.
echo Server will run on http://localhost:3001
echo Press Ctrl+C to stop the server
echo.

node totp-server.js

pause
