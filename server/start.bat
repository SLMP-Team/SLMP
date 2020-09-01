@ECHO OFF
title SL:MP Server
cd /D %~dp0\luajit\
cls
luajit ..\server.lua
pause