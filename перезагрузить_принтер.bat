@echo off

echo Stopping print spooler.

echo.

net stop spooler

echo deleting stuff� where? I�m not sure. Just deleting stuff.

echo.

del %systemroot%\system32\spool\printers\*.shd

del %systemroot%\system32\spool\printers\*.spl

echo Starting print spooler.

echo.

net start spooler