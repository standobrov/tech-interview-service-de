# Tech Interview Service - Data Engineering

Автоматизированный сервис для проведения технических собеседований по data engineering.

## Быстрый старт

### Развертывание на Hetzner Cloud

1. Создайте новый сервер через Hetzner Cloud Console
2. Выберите Ubuntu 22.04 LTS
3. В разделе "User data" вставьте содержимое файла `cloud-init.yaml`
4. Создайте сервер
5. Дождитесь завершения установки (5-10 минут)
6. Получите данные для доступа из файла `/root/deployment-info.txt` на сервере

### Локальное тестирование

```bash
# Клонирование репозитория
git clone https://github.com/standobrov/tech-interview-service-de.git
cd tech-interview-service-de

# Установка зависимостей (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y python3 python3-pip git curl wget

# Запуск автоматического развертывания
sudo ./deploy_new.sh
```

## Структура заданий

### Task 1: Data Cleaning (30 минут)
- **Файл**: `assignments/task1/assignment.md`
- **Данные**: `trades.csv`, `exchange_mapping.csv`
- **Цель**: Очистка и обогащение данных о торгах с помощью pandas
- **Навыки**: pandas, data cleaning, joins

### Task 2: Event Processing (30 минут)
- **Файл**: `assignments/task2/assignment.md`
- **Код**: `app.py`, тесты в `test_app.py`
- **Цель**: Реализация sliding window для обработки событий
- **Навыки**: алгоритмы, обработка потоков данных

## Доступы после развертывания

### SSH доступ
```bash
ssh <username>@<server_ip>
# Пароль и private key будут выданы после развертывания
```

### Gitea (Git сервер)
- URL: `http://<server_ip>:3000`
- Репозиторий с заданиями: `assignments`

### Code-Server (VS Code в браузере)
- URL: `http://<server_ip>:8080`
- Рабочая папка: `/home/<username>/assignments`
- **Предустановленные расширения**:
  - Rainbow CSV - для красивого отображения CSV файлов
  - Python - поддержка Python с автодополнением
  - Jupyter - поддержка Jupyter notebooks
  - CSV Edit - интерактивное редактирование CSV
- **Предустановленные Python пакеты**: pandas, numpy, matplotlib, seaborn, jupyter
- **Тема**: Темная тема включена по умолчанию

## Управление сервисами

### Перезапуск Gitea
```bash
sudo systemctl restart gitea
```

### Перезапуск Code-Server
```bash
sudo systemctl restart code-server@<username>
```

### Просмотр логов
```bash
# Логи развертывания
sudo cat /root/deployment.log

# Логи Gitea
sudo journalctl -u gitea -f

# Логи Code-Server
sudo systemctl status code-server@<username>
sudo journalctl -u code-server@<username> -f
```

### Сброс паролей

#### Пароль пользователя
```bash
sudo passwd <username>
```

#### Пароль Code-Server
```bash
# Редактировать файл конфигурации
sudo nano /home/<username>/.config/code-server/config.yaml
# Перезапустить сервис
sudo systemctl restart code-server@<username>
```

#### Пароль Gitea
```bash
cd /opt/gitea
sudo docker exec gitea gitea admin user change-password --username <username> --password <new_password>
```

## Решение проблем

### Сервисы не запускаются
1. Проверьте статус Docker:
   ```bash
   sudo systemctl status docker
   sudo systemctl start docker
   ```

2. Проверьте порты:
   ```bash
   sudo netstat -tlnp | grep -E "(3000|8080)"
   ```

### Gitea недоступен
```bash
cd /opt/gitea
sudo docker-compose down
sudo docker-compose up -d
```

### Code-Server недоступен
```bash
sudo systemctl stop code-server@<username>
sudo systemctl start code-server@<username>
```

### Репозиторий не синхронизируется
```bash
cd /home/<username>/assignments
git pull origin main
```

## Сеть и безопасность

### Открытые порты
- 22: SSH
- 3000: Gitea
- 8080: Code-Server

### Firewall (при необходимости)
```bash
# UFW
sudo ufw allow 22
sudo ufw allow 3000
sudo ufw allow 8080
sudo ufw enable

# iptables
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

## Мониторинг ресурсов

### Использование диска
```bash
df -h
du -sh /opt/gitea
du -sh /home/<username>
```

### Использование памяти
```bash
free -h
docker stats
```

### Процессы
```bash
ps aux | grep -E "(gitea|code-server)"
```

## Файлы конфигурации

- **Cloud-init**: `cloud-init.yaml`
- **Развертывание**: `deploy_new.sh`
- **Gitea**: `/opt/gitea/docker-compose.yml`
- **Code-Server**: `/home/<username>/.config/code-server/config.yaml`
- **Системный сервис**: `/etc/systemd/system/code-server@.service`

## Технические требования

### Минимальные требования сервера
- **CPU**: 2 ядра
- **RAM**: 4 GB
- **Диск**: 20 GB SSD
- **ОС**: Ubuntu 22.04 LTS

### Рекомендуемые требования
- **CPU**: 4 ядра
- **RAM**: 8 GB
- **Диск**: 40 GB SSD

## Поддержка

При возникновении проблем:
1. Проверьте логи сервисов
2. Убедитесь в доступности портов
3. Перезапустите проблемные сервисы
4. Проверьте файл `/root/deployment-info.txt` для получения актуальных паролей
