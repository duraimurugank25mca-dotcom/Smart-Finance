@echo off
echo ========================================================
echo Starting Smart Finance Manager Python AI Service...
echo ========================================================
cd ai_service
"C:\Users\durai\AppData\Local\Programs\Python\Python311\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000
pause
