@echo off
echo ========================================
echo XOA TAT CA USERS (TRU ADMIN)
echo ========================================
echo.
echo WARNING: This will delete ALL users except admin!
echo Press Ctrl+C to cancel, or
pause

cd backend

echo Deleting users...
sqlite3 drawing_app.db "DELETE FROM Users WHERE role != 'admin';"

echo Deleting task history...
sqlite3 drawing_app.db "DELETE FROM TaskHistory WHERE userId NOT IN (SELECT id FROM Users);"

echo Deleting notifications...
sqlite3 drawing_app.db "DELETE FROM Notifications WHERE userId NOT IN (SELECT id FROM Users);"

echo.
echo Done! All users have been deleted (admin kept).
echo.
pause





