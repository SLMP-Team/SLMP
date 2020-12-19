@ECHO OFF
title SL:MP Server
cd /D %~dp0\core\
cls
luajit lua\svrcore\init.lua
pause