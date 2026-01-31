#!/usr/bin/env python3
"""
Главный сервер для iOS приложения.
Запускает все модули и управляет маршрутами.
"""

from flask import Flask, jsonify
import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), 'modules'))
from modules import api_routes, images_handler, database_handler
from modules.server_order_creator import ServerOrderCreator
from modules.server_ration_handler import ServerRationHandler

app = Flask(__name__)

# ==================== КОНФИГУРАЦИЯ ПУТЕЙ ====================

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP_ROOT = PROJECT_ROOT

# Основные директории
ORDERS_DIR = os.path.join(APP_ROOT, 'database/orders')
USERS_DIR = os.path.join(APP_ROOT, 'database/users')
PRODUCTS_DIR = os.path.join(APP_ROOT, 'database/products')

# Файлы
MAIN_PURCH_PATH = os.path.join(ORDERS_DIR, 'mainpurch.xlsx')
OTHER_PURCH_PATH = os.path.join(ORDERS_DIR, 'otherpurch.xlsx')
ALL_PURCH_PATH = os.path.join(ORDERS_DIR, 'allpurch.xlsx')
RATION_INFO_PATH = os.path.join(USERS_DIR, 'rationinfo.xlsx')
PRODUCTS_DB_PATH = os.path.join(PRODUCTS_DIR, 'appdb2.xlsx')
IMAGES_DIR = os.path.join(PRODUCTS_DIR, 'images')
PRODLINKS_PATH = os.path.join(PRODUCTS_DIR, 'prodlinks.xlsx')


# Инициализация модулей
print("🔄 Инициализация модулей...")

# Инициализируем обработчик базы данных
db_handler = database_handler.DatabaseHandler(
    orders_dir=ORDERS_DIR,
    users_dir=USERS_DIR,
    products_dir=PRODUCTS_DIR
)

# Инициализируем обработчик изображений
images_handler.init_images(IMAGES_DIR)

# Инициализируем серверный обработчик заказов
server_order_creator = ServerOrderCreator(db_handler)

# Инициализируем серверный обработчик рациона
server_ration_handler = ServerRationHandler(db_handler)

# Регистрируем API routes
api_routes.register_routes(
    app,
    db_handler,
    IMAGES_DIR,
    None,
    None,
    server_order_creator,
    server_ration_handler,
    prodlinks_path=PRODLINKS_PATH
)

# Основные маршруты сервера
@app.route('/')
def index():
    """Главная страница сервера"""
    return jsonify({
        "status": "running",
        "name": "iOS App Server",
        "version": "1.0.0",
        "paths": {
            "app_root": APP_ROOT,
            "orders_dir": ORDERS_DIR,
            "users_dir": USERS_DIR,
            "products_dir": PRODUCTS_DIR,
            "images_dir": IMAGES_DIR
        },
        "modules": {
            "order_creator": "active",
            "server_order_creator": "active",
            "server_ration_handler": "active",
            "images_handler": "active",
            "database_handler": "active",
            "api_routes": "active",
            "check_processor": "active",
            "appdb_updater": "active"
        }
    })

@app.route('/config', methods=['GET'])
def get_config():
    """Получение конфигурации сервера"""
    files = {
        "main_purch": MAIN_PURCH_PATH,
        "other_purch": OTHER_PURCH_PATH,
        "all_purch": ALL_PURCH_PATH,
        "products_db": PRODUCTS_DB_PATH,
        "ration_info": RATION_INFO_PATH,
        "prodlinks": PRODLINKS_PATH
    }
    
    # Проверяем существование файлов
    existing_files = {}
    for name, path in files.items():
        if os.path.exists(path):
            existing_files[name] = path
    
    return jsonify({
        "app_root": APP_ROOT,
        "directories": {
            "orders": ORDERS_DIR,
            "users": USERS_DIR,
            "products": PRODUCTS_DIR,
            "images": IMAGES_DIR,
        },
        "files": existing_files,
        "files_status": {name: os.path.exists(path) for name, path in files.items()}
    })

if __name__ == '__main__':
    print("🚀 Запуск iOS App Server")
    print("=" * 50)
    print(f"📍 Корень: {APP_ROOT}")
    print(f"📁 Папки:")
    print(f"   • Orders: {ORDERS_DIR}")
    print(f"   • Users: {USERS_DIR}")
    print(f"   • Products: {PRODUCTS_DIR}")
    print(f"   • Images: {IMAGES_DIR}")
    
    print(f"\n📄 Файлы:")
    files_to_check = [
        (MAIN_PURCH_PATH, 'MainPurch'),
        (OTHER_PURCH_PATH, 'OtherPurch'),
        (ALL_PURCH_PATH, 'AllPurch'),
        (PRODUCTS_DB_PATH, 'Products DB'),
        (RATION_INFO_PATH, 'RationInfo'),
        (PRODLINKS_PATH, 'ProdLinks')
    ]
    
    for path, description in files_to_check:
        if os.path.exists(path):
            print(f"   ✓ {os.path.basename(path)} ({description})")
        else:
            print(f"   ⚠  {os.path.basename(path)} ({description}) - не найден")
    
    print(f"\n🌐 Локальный доступ: http://localhost:8000")
    print(f"📱 Доступ с телефона: http://your_ip:8000")
    print("=" * 50)
    
    app.run(host='0.0.0.0', port=8000, debug=True)
