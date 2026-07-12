@echo off
SET THEFILE=C:\Users\User\Desktop\Simply_VNA_v1.0.0\Simply_VNA.exe
echo Linking %THEFILE%
C:\lazarus\fpc\3.2.2\bin\x86_64-win64\ld.exe -b pei-x86-64  --gc-sections   --subsystem windows --entry=_WinMainCRTStartup    -o C:\Users\User\Desktop\Simply_VNA_v1.0.0\Simply_VNA.exe C:\Users\User\Desktop\Simply_VNA_v1.0.0\link4008.res
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
