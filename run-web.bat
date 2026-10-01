@echo off
cd /d "%~dp0web"
call flutter build web
cd /d "%~dp0"
node serve-web-build.js
