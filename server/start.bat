@ECHO OFF
title SL:MP Server
chcp 1251
cd /D %~dp0\luajit\
cls
luajit ..\SLMultiplayer.lua
pause