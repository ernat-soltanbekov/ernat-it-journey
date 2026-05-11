# 1. Используем официальный легкий образ Python
FROM python:3.11-slim

# 2. Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# 3. Копируем файл с зависимостями (если есть) и устанавливаем их
# Пока у нас только Flask, установим его напрямую
RUN pip install --no-cache-dir flask

# 4. Копируем твой код в контейнер
COPY practice.py .

# 5. Открываем порт 8000
EXPOSE 8000

# 6. Команда для запуска приложения
CMD ["python", "practice.py"]

# 1. Base image (Minimal & Stable)
FROM python:3.11-slim

# 2. Security: Create a non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# 3. Workspace setup
WORKDIR /app

# 4. Dependency Layer (Heavy, cached)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Application Layer (Lightweight, frequent changes)
COPY practice.py .

# 6. Set ownership to non-root user
RUN chown -R appuser:appgroup /app
USER appuser

# 7. Runtime config
EXPOSE 8000
CMD ["python", "practice.py"]