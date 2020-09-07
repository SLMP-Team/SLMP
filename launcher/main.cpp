#define _CRT_SECURE_NO_WARNINGS

#include <iostream>
#include <Windows.h>
#include <string>

inline bool doesFileExists(const std::string& name) {
	struct stat buffer;
	return (stat(name.c_str(), &buffer) == 0);
}

int main(int argc, char** argv)
{
	::ShowWindow(::GetConsoleWindow(), SW_HIDE);
	char buf[256];
	GetCurrentDirectoryA(256, buf);
	strcat(buf, "\\gta_sa.exe");
	if (!doesFileExists(buf))
		MessageBoxA(NULL, (LPCSTR)"SL:MP can`t find GTA_SA.EXE file!", (LPCSTR)"SL:MP - Critical Error", MB_ICONERROR | MB_OK);
	else
		system("gta_sa.exe -multiplayer");
	return 0;
}
