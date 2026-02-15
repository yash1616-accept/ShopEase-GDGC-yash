@echo off
setlocal EnableDelayedExpansion

:: ShopEase - E-Commerce Application Installation Script (Windows)
:: This script sets up the entire project with all dependencies

set "ERRORS=0"

:: Colors (Windows CMD has limited color support)
set "BLUE=[94m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "RED=[91m"
set "NC=[0m"

:: Banner
echo.
echo   ==================================================================
echo   ShopEase E-Commerce Installation (Windows)
echo   ==================================================================
echo.

:: Check Node.js version
echo [1/6] Checking Prerequisites...
where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] Node.js not found. Please install Node.js 18+ from https://nodejs.org/
    exit /b 1
)

for /f "delims=" %%i in ('node --version') do set "NODE_VERSION=%%i"
echo   [OK] Node.js found: %NODE_VERSION%

:: Check Node version is 18+
set "NODE_MAJOR=%NODE_VERSION:~1,2%"
if %NODE_MAJOR% LSS 18 (
    echo   [ERROR] Node.js version 18+ required. Current version: %NODE_VERSION%
    exit /b 1
)

where npm >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] npm not found
    exit /b 1
)

for /f "delims=" %%i in ('npm --version') do set "NPM_VERSION=%%i"
echo   [OK] npm found: v%NPM_VERSION%
echo.

:: Check if package.json exists
if not exist "package.json" (
    echo [ERROR] package.json not found. Please run this script from the project root.
    exit /b 1
)

:: Install root dependencies first (including concurrently)
echo [2/6] Installing All Dependencies...
call npm install
if %ERRORLEVEL% neq 0 (
    echo   [ERROR] Failed to install dependencies
    set "ERRORS=1"
    goto :error_handler
)
echo   [OK] All dependencies installed (root + workspaces)
echo.

:: Setup database (SQLite)
echo [3/6] Setting Up Database (SQLite)...
if not exist "backend\package.json" (
    echo   [WARNING] Backend not found, skipping database setup
) else (
    cd /d backend
    
    :: Generate Prisma client
    echo   Generating Prisma client...
    call npx prisma generate
    if %ERRORLEVEL% neq 0 (
        echo   [WARNING] Prisma generate failed (this may be OK if no schema)
    )
    
    :: Create and migrate database
    echo   Creating database...
    call npx prisma db push
    if %ERRORLEVEL% neq 0 (
        echo   [WARNING] Prisma db push failed (database may already exist)
    )
    
    :: Seed database
    echo   Seeding database with sample products...
    call npx tsx prisma/seed.ts 2>nul
    if %ERRORLEVEL% neq 0 (
        call npm run prisma:seed 2>nul
        if %ERRORLEVEL% neq 0 (
            echo   [WARNING] Seed may have already run or failed
        )
    )
    
    cd /d ..
    echo   [OK] Database setup complete
)
echo.

:: Build the project
echo [4/6] Building Project...
if not exist "frontend\package.json" (
    echo   [WARNING] Frontend not found, skipping build
) else (
    cd /d frontend
    call npm run build
    if %ERRORLEVEL% neq 0 (
        echo   [ERROR] Frontend build failed
        set "ERRORS=1"
        cd /d ..
        goto :error_handler
    )
    cd /d ..
    echo   [OK] Frontend built successfully
)
echo.

:: Success
echo   ==================================================================
echo   Installation Complete!
echo   ==================================================================
echo.
echo To start the development servers:
echo   npm run dev
echo.
echo This will start:
echo   - Frontend: http://localhost:5173
echo   - Backend:  http://localhost:3000
echo.
echo You can also use these commands:
echo   npm run dev:frontend  - Frontend only
echo   npm run dev:backend   - Backend only
echo.

exit /b 0

:error_handler
echo.
echo   ==================================================================
echo   Installation Failed!
echo   ==================================================================
echo.
echo Please check the errors above and try again.
echo.
echo Common fixes:
echo   - Run as Administrator
echo   - Clear npm cache: npm cache clean --force
echo   - Delete node_modules and try again
echo.
exit /b 1
