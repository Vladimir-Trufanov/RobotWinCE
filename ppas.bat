@echo off
SET THEFILE=C:\ForWinCE\WinCE Emulator\SDFlash\RobotWinCE\RobotWinCE.exe
echo Linking %THEFILE%
C:\LazarusWinCE\fpc\3.2.0\bin\i386-win32\arm-wince-ld.exe -m arm_wince_pe  --gc-sections   --subsystem wince --entry=_WinMainCRTStartup    -o "C:\ForWinCE\WinCE Emulator\SDFlash\RobotWinCE\RobotWinCE.exe" "C:\ForWinCE\WinCE Emulator\SDFlash\RobotWinCE\link.res"
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
