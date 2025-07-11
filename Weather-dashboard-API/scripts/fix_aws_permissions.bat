@echo off
echo ====================================
echo    AWS Resource Cleanup and Setup
echo ====================================
echo.

echo Step 1: Cleaning up conflicting resources...
bash cleanup_conflicting_resources.sh
if errorlevel 1 (
    echo ERROR: Cleanup failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Updating IAM permissions...
bash setup_aws_oidc.sh
if errorlevel 1 (
    echo ERROR: IAM setup failed!
    pause
    exit /b 1
)

echo.
echo ====================================
echo    ✅ All tasks completed successfully!
echo ====================================
echo.
echo Your AWS permissions have been updated.
echo You can now run your Terraform workflow.
echo.
pause
