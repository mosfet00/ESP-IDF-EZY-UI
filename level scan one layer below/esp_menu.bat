@echo off
call "C:\Espressif\idf_cmd_init.bat" esp-idf-a42363d30ca3a4b9ae7b7003b5ba8a20""
cmd /k call "%~dp0esp_worker.bat"