@echo off
echo 开始构建Docker镜像...

REM 构建Docker镜像
docker build -t email-app .

REM 检查构建是否成功
if %errorlevel% equ 0 (
    echo 镜像构建成功！
    echo.
    echo 运行容器：
    echo docker run -p 80:80 -p 8000:8000 email-app
    echo.
    echo 或者后台运行：
    echo docker run -d -p 80:80 -p 8000:8000 --name email-app-container email-app
    echo.
    echo 访问应用：
    echo 前端: http://localhost
    echo 后端API: http://localhost:8000
) else (
    echo 镜像构建失败！
    exit /b 1
) 