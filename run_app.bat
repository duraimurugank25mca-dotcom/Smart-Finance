@echo off
echo ===================================================================
echo             SMART FINANCE MANAGER - FULL STACK LAUNCHER
echo ===================================================================
echo [1/3] Starting Backend API Server (Node.js/Express/PostgreSQL on port 5000)...
start "Smart Finance Backend API" cmd /k "cd backend && node src/server.js"

timeout /t 2 /nobreak > nul

echo [2/3] Starting AI Service (Python FastAPI on port 8000)...
start "Smart Finance AI Service" cmd /k "cd ai_service && "C:\Users\durai\AppData\Local\Programs\Python\Python311\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000"

timeout /t 2 /nobreak > nul

echo [3/3] Launching Flutter Application on Chrome...
"C:\src\flutter\bin\flutter.bat" run -d chrome

pause
