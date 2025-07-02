# Tech Interview Service - Summary

## 🎯 Overview
Полностью автоматизированный сервис для проведения технических собеседований по data engineering с автоматическим развертыванием на Hetzner Cloud.

## 📋 Features
- ✅ Автоматическое создание пользователей и SSH ключей
- ✅ Развертывание Gitea (Git сервер) через Docker
- ✅ Создание репозитория с заданиями
- ✅ Настройка Code-Server (VS Code в браузере)
- ✅ Полное логирование и обработка ошибок
- ✅ Сохранение всех credentials

## 🚀 Quick Start

### Hetzner Cloud (Recommended)
1. Создайте новый сервер в Hetzner Cloud Console
2. Выберите Ubuntu 22.04 LTS (минимум 4GB RAM)
3. В User Data вставьте содержимое `cloud-init.yaml`
4. Создайте сервер и дождитесь завершения установки (5-10 минут)
5. Подключитесь по SSH и проверьте `/root/deployment-info.txt`

### Local Testing
```bash
sudo ./test_deploy.sh
```

## 📁 Project Structure
```
├── cloud-init.yaml          # Hetzner Cloud init config
├── deploy_new.sh             # Main deployment script
├── deploy.sh                 # Legacy script (deprecated)
├── test_deploy.sh            # Local testing script
├── README.md                 # Full documentation
├── SUMMARY.md                # This file
└── assignments/
    ├── task1/                # Data cleaning task (pandas)
    │   ├── assignment.md
    │   ├── trades.csv
    │   └── exchange_mapping.csv
    └── task2/                # Event processing task (algorithms)
        ├── assignment.md
        ├── app.py
        └── test_app.py
```

## 🔧 Services
- **Gitea**: http://SERVER_IP:3000 (Git repository)
- **Code-Server**: http://SERVER_IP:8080 (VS Code interface)
- **SSH**: PORT 22 (Admin access)

## 🐛 Recent Fixes
- ✅ **Removed Docker dependency** - Gitea now runs natively on host
- ✅ **Fixed token scopes** - Added proper scopes for repository and user operations
- ✅ **Improved repository creation** - Multiple fallback methods for repo creation
- ✅ **Fixed code-server installation** - No more sudo password issues
- ✅ **Enhanced push-to-create** - Enabled push-to-create in Gitea configuration
- ✅ **Fixed permission errors** - Resolved /root access issues for user file copying
- ✅ **Better error handling** - Graceful fallbacks when operations fail
- ✅ **Robust cloning** - Creates local folder if remote clone fails

## 🛠️ Troubleshooting Tools
- `./cleanup.sh` - Clean up failed deployment
- `./test_deploy.sh` - Local testing (no Docker required)
- `./check_status.sh` - Quick system status check with user info
- `./test_copy_fix.sh` - Test the permission fix specifically
- `/root/deployment.log` - Full deployment log
- `systemctl status gitea` - Check Gitea service
- `systemctl status code-server@USERNAME` - Check Code-Server

## 📊 What Gets Created
1. **Admin User**: Random username with SSH key access and sudo rights
2. **Gitea Instance**: Docker-based Git server with assignments repository
3. **Code-Server**: Browser-based VS Code pointing to assignments folder
4. **Service Files**: Systemd services for automatic startup

## 🎓 Interview Tasks

### Task 1: Data Cleaning (30 min)
- Clean and enrich trading data using pandas
- Handle missing exchange mappings
- Calculate trade statistics
- Skills: pandas, data cleaning, joins

### Task 2: Event Processing (30 min)
- Implement sliding window algorithm
- Process stream of timestamped events
- Calculate max bytes in time windows
- Skills: algorithms, data structures, optimization

## 🔐 Security
- Random usernames and passwords
- SSH key-based authentication
- No root SSH access
- Service isolation

## 📝 Logs & Debugging
- Deployment log: `/root/deployment.log`
- Credentials: `/root/deployment-info.txt`
- Service logs: `journalctl -u code-server@USERNAME`
- Container logs: `docker logs gitea`

## 🔄 Common Commands
```bash
# Check service status
systemctl status code-server@USERNAME
docker ps

# Restart services
systemctl restart code-server@USERNAME
cd /opt/gitea && docker-compose restart

# View logs
cat /root/deployment.log
docker logs gitea
```

## 💡 Troubleshooting
- If services don't start: Check Docker status and logs
- If ports are blocked: Verify firewall settings
- If Git operations fail: Check Gitea container health
- If Code-Server is inaccessible: Verify systemd service status

## 🎯 Next Steps After Deployment
1. Access Code-Server at http://SERVER_IP:8080
2. Open assignments folder
3. Review task1 and task2 assignments
4. Test candidate workflow
5. Customize tasks if needed

---
For detailed documentation see README.md
