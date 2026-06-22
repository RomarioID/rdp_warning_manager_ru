@echo off
chcp 1251 >nul
setlocal EnableExtensions DisableDelayedExpansion
title Управление предупреждением безопасности RDP

rem ============================================================
rem  Управление предупреждением безопасности RDP
rem  Один обычный BAT-файл. Все сообщения и комментарии на русском.
rem  Для изменения настройки запустите файл от имени администратора.
rem ============================================================

set "REG_KEY=HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services\Client"
set "REG_VALUE=RedirectionWarningDialogVersion"
set "REG_VIEW="
set "CLI_MODE="

rem На 64-битной Windows явно используем 64-битную ветку реестра.
if defined PROCESSOR_ARCHITEW6432 set "REG_VIEW=/reg:64"
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "REG_VIEW=/reg:64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "REG_VIEW=/reg:64"

rem Аргументы ниже нужны только для быстрой проверки из командной строки.
if /i "%~1"=="статус" (
    set "CLI_MODE=1"
    goto show_status
)
if /i "%~1"=="status" (
    set "CLI_MODE=1"
    goto show_status
)
if /i "%~1"=="отключить" (
    set "CLI_MODE=1"
    goto disable_warning
)
if /i "%~1"=="disable" (
    set "CLI_MODE=1"
    goto disable_warning
)
if /i "%~1"=="включить" (
    set "CLI_MODE=1"
    goto enable_warning
)
if /i "%~1"=="enable" (
    set "CLI_MODE=1"
    goto enable_warning
)

:menu
cls
echo ============================================================
echo   Управление предупреждением безопасности RDP
echo ============================================================
echo.
echo   1 - ОТКЛЮЧИТЬ предупреждение с галочками буфера обмена/принтеров
echo   2 - ВКЛЮЧИТЬ предупреждение обратно
echo   3 - Показать текущее состояние настройки
echo   0 - Выход
echo.
set "CHOICE="
set /p "CHOICE=Выберите действие: "

if "%CHOICE%"=="1" goto disable_warning
if "%CHOICE%"=="2" goto enable_warning
if "%CHOICE%"=="3" goto show_status
if "%CHOICE%"=="0" goto exit_ok

echo.
echo Неверный выбор. Нажмите любую клавишу и попробуйте снова.
pause >nul
goto menu

:no_admin
cls
echo ============================================================
echo   Требуются права администратора
echo ============================================================
echo.
echo Этот файл изменяет параметры политики в разделе HKLM.
echo Закройте это окно, нажмите правой кнопкой по BAT-файлу
echo и выберите "Запуск от имени администратора".
echo.
if defined CLI_MODE goto exit_error
pause
goto exit_error

:disable_warning
fltmc >nul 2>&1
if errorlevel 1 goto no_admin

cls
echo ============================================================
echo   Отключение предупреждения RDP
echo ============================================================
echo.
echo Будет записан параметр реестра:
echo %REG_VALUE% = 1
echo.

reg add "%REG_KEY%" /v "%REG_VALUE%" /t REG_DWORD /d 1 /f %REG_VIEW%
if errorlevel 1 goto registry_write_error

echo.
echo Готово. Предупреждение RDP отключено.
echo Закройте все окна удалённого рабочего стола и подключитесь заново.
echo.
goto pause_or_exit

:enable_warning
fltmc >nul 2>&1
if errorlevel 1 goto no_admin

cls
echo ============================================================
echo   Включение предупреждения RDP обратно
echo ============================================================
echo.
echo Будет удалён параметр реестра:
echo %REG_VALUE%
echo.

reg query "%REG_KEY%" /v "%REG_VALUE%" %REG_VIEW% >nul 2>&1
if errorlevel 1 goto value_not_found

reg delete "%REG_KEY%" /v "%REG_VALUE%" /f %REG_VIEW%
if errorlevel 1 goto registry_delete_error

echo.
echo Готово. Предупреждение RDP включено обратно.
echo Закройте все окна удалённого рабочего стола и подключитесь заново.
echo.
goto pause_or_exit

:show_status
cls
echo ============================================================
echo   Текущее состояние настройки RDP
echo ============================================================
echo.

reg query "%REG_KEY%" /v "%REG_VALUE%" %REG_VIEW% >nul 2>&1
if errorlevel 1 goto status_not_configured

reg query "%REG_KEY%" /v "%REG_VALUE%" %REG_VIEW%
echo.
echo Состояние: параметр найден.
echo Если значение равно REG_DWORD 0x1, предупреждение RDP отключено через политику клиента.
echo.
goto pause_or_exit

:status_not_configured
echo Состояние: параметр %REG_VALUE% не найден.
echo Windows использует стандартное поведение.
echo Предупреждение RDP может появляться, если Windows считает RDP-файл неподписанным или недоверенным.
echo.
goto pause_or_exit

:value_not_found
echo.
echo Параметр не найден.
echo Windows уже использует стандартное поведение.
echo.
goto pause_or_exit

:registry_write_error
echo.
echo Ошибка: не удалось записать параметр реестра.
echo Убедитесь, что BAT-файл запущен от имени администратора.
echo.
goto pause_or_exit

:registry_delete_error
echo.
echo Ошибка: не удалось удалить параметр реестра.
echo Убедитесь, что BAT-файл запущен от имени администратора.
echo.
goto pause_or_exit

:pause_or_exit
if defined CLI_MODE goto exit_ok
pause
goto menu

:exit_error
endlocal
exit /b 1

:exit_ok
endlocal
exit /b 0