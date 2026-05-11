import psycopg2
import time
import random
import uuid 
from flask import Flask

app = Flask(__name__)

CIRCUIT_OPEN = False 
LAST_FAILURE_TIME = 0
STRIKE_COUNT = 0  # NEW: Счетчик серийных ошибок

@app.route('/health')
def health_check():
    # Имитируем проверку: если STRIKE_COUNT большой, 
    # система считается "больной" (Unhealthy)
    if CIRCUIT_OPEN or STRIKE_COUNT > 0:
        return {"status": "unhealthy", "reason": "high_error_rate"}, 503
    
    return {"status": "healthy"}, 200

@app.route('/api/orders')
def get_orders():
    global CIRCUIT_OPEN, LAST_FAILURE_TIME, STRIKE_COUNT # NEW: добавили STRIKE_COUNT
    
    req_id = str(uuid.uuid4())[:8] 
    start_request = time.time()
    print(f"[{req_id}] START: Обработка нового заказа")
    
    # 1. Проверка предохранителя
    if CIRCUIT_OPEN:
        if time.time() - LAST_FAILURE_TIME > 10:
            CIRCUIT_OPEN = False
            print(f"[{req_id}] INFO: Предохранитель перешел в Half-Open")
        else:
            duration = round(time.time() - start_request, 3)
            print(f"[{req_id}] END: Сработал предохранитель. Время: {duration}s")
            return {"status": "ok", "source": "circuit_fallback", "req_id": req_id}, 200

    # 2. Имитация внешнего сервиса
    external_start = time.time()
    
    if random.random() < 0.3:
        # Имитируем тормоза (30% случаев)
        print(f"[{req_id}] DEBUG: Внешний сервис начал задерживать ответ...")
        time.sleep(2) 
        
        ext_duration = round(time.time() - external_start, 3)
        total_duration = round(time.time() - start_request, 3)
        
        # NEW: Логика умного алерта
        STRIKE_COUNT += 1 
        if STRIKE_COUNT >= 3:
            print(f"[{req_id}] !!! CRITICAL ALERT: Сгорел бюджет ошибок! !!!")
            # РЕАЛЬНОЕ ДЕЙСТВИЕ (переносим сюда):
            CIRCUIT_OPEN = True
            LAST_FAILURE_TIME = time.time()
            print(f"[{req_id}] SYSTEM: Предохранитель РАЗОМКНУТ (Circuit Open).")
        else:
            print(f"[{req_id}] WARN: Задержка ({STRIKE_COUNT}/3). Пока просто наблюдаем.")
            
        return {"status": "ok", "source": "timeout_fallback", "req_id": req_id}, 200

    # 3. Успешный путь
    time.sleep(0.2)
    
    # NEW: Если всё прошло успешно, сбрасываем счетчик ошибок
    STRIKE_COUNT = 0 
    
    ext_duration = round(time.time() - external_start, 3)
    total_duration = round(time.time() - start_request, 3)
    
    print(f"[{req_id}] SUCCESS: Завершено за {total_duration}s")
    return {"status": "ok", "source": "external_service", "req_id": req_id}, 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8000, threaded=True)
