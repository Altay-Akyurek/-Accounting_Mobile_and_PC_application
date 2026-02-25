@echo off
echo Muhasebe Pro - Windows Temizlik Baslatiliyor...
echo Lutfen VS Code'u kapatin ve bu dosyaya Sag Tiklayip 'Yonetici Olarak Calistir' deyin.
echo.

taskkill /F /IM flutter.exe /T 2>nul
taskkill /F /IM dart.exe /T 2>nul
taskkill /F /IM muhasebe_app.exe /T 2>nul
taskkill /F /IM msbuild.exe /T 2>nul
taskkill /F /IM cmake.exe /T 2>nul
taskkill /F /IM vctip.exe /T 2>nul
taskkill /F /IM link.exe /T 2>nul
taskkill /F /IM cl.exe /T 2>nul

echo.
echo Build klasoru temizleniyor...
timeout /t 2 /nobreak >nul
if exist build rmdir /s /q build

echo.
echo Islem Tamamlandi! Simdi VS Code'u acip tekrar Run diyebilirsiniz.
pause
