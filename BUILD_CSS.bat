@echo off
echo ========================================
echo Building Enhanced UI CSS
echo ========================================
echo.

echo Compiling Tailwind CSS...
call npm run build:css

echo.
echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Output file: css/output.css
echo.
echo Next steps:
echo 1. Open ui-components-demo.html in browser
echo 2. Or run: npm run dev (for dev server)
echo.
pause
