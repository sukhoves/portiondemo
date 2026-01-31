"""
Модуль для регистрации API маршрутов
"""

from flask import jsonify, request
from datetime import datetime
import os
import pandas as pd

# Импортируем новый обработчик рациона (ОСТАВЛЯЕМ!)
from modules.server_ration_handler import ServerRationHandler

# Новый код:
def register_routes(app, db_handler, images_dir, lavka_processor,
                   lavka_updater, server_order_creator, server_ration_handler,
                   prodlinks_path=None):
    
    # Если модули Яндекс Лавки не переданы, пропускаем эндпоинты
    has_lavka_modules = lavka_processor is not None and lavka_updater is not None
    """Регистрация всех API маршрутов"""
    
    # Если prodlinks_path не передан, используем стандартный
    if prodlinks_path is None:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        modules_dir = os.path.dirname(current_dir)
        backend_dir = os.path.dirname(modules_dir)
        prodlinks_path = os.path.join(backend_dir, 'database', 'products', 'prodlinks.xlsx')
    
    # ==================== СОЗДАНИЕ ЗАКАЗА (iOS OrderCreator) ====================
    
    @app.route('/create_order', methods=['POST'])
    def create_order():
        """Создание заказа из iOS приложения (заменяет SwiftData логику)"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            print(f"\n{'='*80}")
            print(f"🛒 ПОЛУЧЕН ЗАПРОС НА СОЗДАНИЕ ЗАКАЗА ОТ iOS")
            print(f"{'='*80}")
            
            # Проверяем обязательные поля
            required_fields = ['family_id', 'address_id', 'order_date', 'items']
            missing_fields = [field for field in required_fields if field not in data]
            
            if missing_fields:
                error_msg = f"Missing required fields: {', '.join(missing_fields)}"
                print(f"❌ {error_msg}")
                return jsonify({"status": "error", "message": error_msg}), 400
            
            # Проверяем items
            if not data['items'] or len(data['items']) == 0:
                print("❌ Пустая корзина")
                return jsonify({"status": "error", "message": "Cart is empty"}), 400
            
            # Логируем информацию о заказе
            print(f"📋 Информация о заказе:")
            print(f"   FamilyID: {data['family_id']}")
            print(f"   AddressID: {data['address_id']}")
            print(f"   Order Date: {data['order_date']}")
            print(f"   Items count: {len(data['items'])}")
            
            # Обрабатываем заказ через серверный обработчик
            result = server_order_creator.create_order_from_cart(data)
            
            if result["status"] == "error":
                print(f"❌ Ошибка при создании заказа: {result['message']}")
                return jsonify(result), 400
            
            print(f"✅ Заказ успешно создан!")
            print(f"   Сохранено в AllPurch: {result['data']['all_saved']}")
            print(f"   Обновлено в MainPurch: {result['data']['main_updated']}")
            print(f"   Добавлено в OtherPurch: {result['data']['other_saved']}")
            print(f"{'='*80}")
            
            return jsonify(result)
            
        except Exception as e:
            print(f"\n❌ КРИТИЧЕСКАЯ ОШИБКА ПРИ СОЗДАНИЕ ЗАКАЗА:")
            print(f"   {str(e)}")
            import traceback
            traceback.print_exc()
            print(f"{'='*80}")
            
            return jsonify({
                "status": "error",
                "message": f"Server error: {str(e)[:200]}"
            }), 500
    
    # ==================== ПОЛУЧЕНИЕ ДАННЫХ ПО FAMILYID ИЛИ USERID (НОВЫЕ) ====================
    
    @app.route('/get_main_purch', methods=['POST'])
    def get_main_purch():
        """Получение данных MainPurch по FamilyID или UserID"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            family_id = data.get('family_id')
            user_id = data.get('user_id')
            
            if not family_id and not user_id:
                return jsonify({"status": "error", "message": "Either family_id or user_id is required"}), 400
            
            print(f"🔍 Получен запрос MainPurch с FamilyID: '{family_id}', UserID: '{user_id}'")
            
            # Ищем данные по FamilyID или UserID
            family_data, error = db_handler.get_purch_data(family_id, user_id, 'main')
            
            if error:
                return jsonify({"status": "error", "message": error}), 404 if "not found" in error.lower() else 500
            
            if family_data.empty:
                return jsonify({
                    "status": "success",
                    "products": [],
                    "message": "No products found"
                })
            
            products_data = []
            for _, row in family_data.iterrows():
                order_date_str = ""
                expire_date_str = ""
                
                if pd.notna(row['Date']):
                    if isinstance(row['Date'], (int, float)):
                        order_date_str = datetime.fromtimestamp(row['Date']).strftime("%d.%m.%Y")
                    else:
                        order_date_str = str(row['Date'])
                
                if pd.notna(row['ExpireDate']):
                    if isinstance(row['ExpireDate'], (int, float)):
                        expire_date_str = datetime.fromtimestamp(row['ExpireDate']).strftime("%d.%m.%Y")
                    else:
                        expire_date_str = str(row['ExpireDate'])
                
                # ОТПРАВЛЯЕМ 20 ЭЛЕМЕНТОВ (с UserID и FamilyID)
                product_tuple = (
                    int(row['ProdID']),
                    str(row['Name']),
                    float(row['TotalVolume']),
                    str(row['Unit']),
                    float(row['TotalVolumeGr']),
                    float(row['Kcal100g']),
                    float(row['Prot100g']),
                    float(row['Fat100g']),
                    float(row['Carb100g']),
                    expire_date_str,
                    str(row['Tag']),
                    str(row['Cat']),
                    str(row['Store']),
                    int(row['StoreID']),
                    order_date_str,
                    float(row['TotalCostPerCount']),
                    str(row['Address']),
                    int(row['AddressID']),
                    str(row['UserID']) if 'UserID' in row and pd.notna(row['UserID']) else "",  # ← UserID
                    int(row['FamilyID']) if 'FamilyID' in row and pd.notna(row['FamilyID']) else 0  # ← FamilyID
                )
                products_data.append(product_tuple)
            
            result = {
                "status": "success",
                "products": products_data,
                "count": len(products_data)
            }
            
            print(f"✅ Отправлено {len(products_data)} продуктов (20 элементов каждый)")
            return jsonify(result)
            
        except Exception as e:
            print(f"❌ Ошибка при получении MainPurch: {str(e)}")
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    
    @app.route('/get_other_purch', methods=['POST'])
    def get_other_purch():
        """Получение данных OtherPurch по FamilyID или UserID"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            family_id = data.get('family_id')
            user_id = data.get('user_id')
            
            if not family_id and not user_id:
                return jsonify({"status": "error", "message": "Either family_id or user_id is required"}), 400
            
            print(f"🔍 Получен запрос OtherPurch с FamilyID: '{family_id}', UserID: '{user_id}'")
            
            # Ищем данные по FamilyID или UserID
            family_data, error = db_handler.get_purch_data(family_id, user_id, 'other')
            
            if error:
                return jsonify({"status": "error", "message": error}), 404 if "not found" in error.lower() else 500
            
            if family_data.empty:
                return jsonify({
                    "status": "success",
                    "products": [],
                    "message": "No products found"
                })
            
            products_data = []
            for _, row in family_data.iterrows():
                order_date_str = ""
                expire_date_str = ""
                
                if pd.notna(row['Date']) and row['Date'] != '':
                    if isinstance(row['Date'], (int, float)):
                        order_date_str = datetime.fromtimestamp(row['Date']).strftime("%d.%m.%Y")
                    else:
                        order_date_str = str(row['Date'])
                
                if pd.notna(row['ExpireDate']) and row['ExpireDate'] != '':
                    if isinstance(row['ExpireDate'], (int, float)):
                        expire_date_str = datetime.fromtimestamp(row['ExpireDate']).strftime("%d.%m.%Y")
                    else:
                        expire_date_str = str(row['ExpireDate'])
                
                # ОТПРАВЛЯЕМ 19 ЭЛЕМЕНТОВ (с UserID и FamilyID)
                product_tuple = (
                    int(row['ProdID']),
                    str(row['Name']),
                    float(row['TotalVolume']),
                    str(row['Unit']),
                    float(row['TotalVolumeGr']),
                    float(row['Kcal100g']),
                    float(row['Prot100g']),
                    float(row['Fat100g']),
                    float(row['Carb100g']),
                    str(row['Tag']),
                    str(row['Cat']),
                    str(row['Store']),
                    int(row['StoreID']),
                    order_date_str,
                    float(row['TotalCostPerCount']),
                    str(row['Address']),
                    int(row['AddressID']),
                    str(row['UserID']) if 'UserID' in row and pd.notna(row['UserID']) else "",  # ← UserID
                    int(row['FamilyID']) if 'FamilyID' in row and pd.notna(row['FamilyID']) else 0  # ← FamilyID
                )
                products_data.append(product_tuple)
            
            result = {
                "status": "success",
                "products": products_data,
                "count": len(products_data)
            }
            
            print(f"✅ Отправлено {len(products_data)} продуктов из OtherPurch (19 элементов каждый)")
            return jsonify(result)
            
        except Exception as e:
            print(f"❌ Ошибка при получении OtherPurch: {str(e)}")
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    
    # ==================== УПРАВЛЕНИЕ РАЦИОНОМ (СЕРВЕРНЫЙ) ====================
    
    @app.route('/add_to_ration', methods=['POST'])
    def add_to_ration():
        """Добавление продукта в серверный рацион"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            # Используем новый обработчик рациона
            result = server_ration_handler.add_to_ration(data)
            
            if result["status"] == "error":
                return jsonify(result), 400
            
            return jsonify(result)
                
        except Exception as e:
            print(f"❌ Ошибка добавления в рацион: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({
                "status": "error",
                "message": f"Server error: {str(e)[:200]}"
            }), 500
    
    @app.route('/get_ration_by_date', methods=['POST'])
    def get_ration_by_date():
        """Получение рациона по дате"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            ration_date = data.get('ration_date')
            user_id = data.get('user_id')  # ← ДОБАВИТЬ ЭТУ СТРОКУ
            
            if not ration_date:
                return jsonify({"status": "error", "message": "Ration date is required"}), 400
                
            if not user_id:  # ← ДОБАВИТЬ ЭТУ ПРОВЕРКУ
                return jsonify({"status": "error", "message": "UserID is required"}), 400
            
            print(f"🔍 Получен запрос рациона на дату: {ration_date}, UserID: {user_id}")  # ← ИЗМЕНИТЬ ЛОГ
            
            # Получаем данные через обработчик
            df = server_ration_handler.get_ration_by_date(ration_date)
            
            if df.empty:
                return jsonify({
                    "status": "success",
                    "rations": [],
                    "message": f"No ration data for {ration_date}"
                })
            
            # ФИЛЬТРАЦИЯ ПО UserID ← ДОБАВИТЬ ЭТОТ БЛОК
            if 'UserID' in df.columns:
                # Фильтруем только записи текущего пользователя
                filtered_df = df[df['UserID'] == user_id]
                print(f"📊 Всего записей на дату: {len(df)}, для UserID {user_id}: {len(filtered_df)}")
            
                if filtered_df.empty:
                    return jsonify({
                        "status": "success",
                        "rations": [],
                        "message": f"No ration data for user {user_id} on {ration_date}"
                    })
            
                df = filtered_df
            
            else:
                print("⚠️  В таблице RationInfo нет колонки UserID, фильтрация невозможна")
            # КОНЕЦ БЛОКА ФИЛЬТРАЦИИ
            
            # Преобразуем данные для отправки
            rations_data = []
            for _, row in df.iterrows():
                # Форматируем даты
                ration_date_str = ""
                expire_date_str = ""
                
                if pd.notna(row.get('RationDate')):
                    if isinstance(row['RationDate'], (int, float)):
                        ration_date_str = datetime.fromtimestamp(row['RationDate']).strftime("%d.%m.%Y")
                    else:
                        ration_date_str = str(row['RationDate'])
                
                if pd.notna(row.get('ExpireDate')) and row['ExpireDate'] != '':
                    if isinstance(row['ExpireDate'], (int, float)):
                        expire_date_str = datetime.fromtimestamp(row['ExpireDate']).strftime("%d.%m.%Y")
                    else:
                        expire_date_str = str(row['ExpireDate'])
                
                ration_tuple = (
                    int(row['ProdID']) if pd.notna(row.get('ProdID')) else 0,
                    str(row.get('Name', '')),
                    float(row.get('Volume', 0)),
                    str(row.get('Unit', '')),
                    float(row.get('VolumeGr', 0)),
                    float(row.get('Kcal100g', 0)),
                    float(row.get('Prot100g', 0)),
                    float(row.get('Fat100g', 0)),
                    float(row.get('Carb100g', 0)),
                    expire_date_str,
                    str(row.get('Tag', '')),
                    str(row.get('Cat', '')),
                    int(row.get('MealID', 0)),
                    str(row.get('MealName', '')),
                    ration_date_str,
                    float(row.get('VolumeServ', 0)),
                    float(row.get('VolumeServGr', 0)),
                    float(row.get('KcalServ', 0)),
                    float(row.get('ProtServ', 0)),
                    float(row.get('FatServ', 0)),
                    float(row.get('CarbServ', 0)),
                    str(row.get('UserID', ''))
                )
                rations_data.append(ration_tuple)
            
            result = {
                "status": "success",
                "rations": rations_data,
                "count": len(rations_data)
            }
            
            print(f"✅ Отправлено {len(rations_data)} записей рациона на {ration_date} для UserID: {user_id}")  # ← ИЗМЕНИТЬ ЛОГ
            return jsonify(result)
            
        except Exception as e:
            print(f"❌ Ошибка при получении рациона: {str(e)}")
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
            
    @app.route('/get_ration_by_daterange', methods=['POST'])
    def get_ration_by_daterange():
        """Получение рациона за период дат"""
        try:
            data = request.get_json()
        
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
        
            start_date = data.get('start_date')
            end_date = data.get('end_date')
            user_id = data.get('user_id')
        
            # Валидация входных данных
            if not start_date:
                return jsonify({"status": "error", "message": "Start date is required"}), 400
            if not end_date:
                return jsonify({"status": "error", "message": "End date is required"}), 400
            if not user_id:
                return jsonify({"status": "error", "message": "UserID is required"}), 400
        
            print(f"🔍 Получен запрос рациона за период: {start_date} - {end_date}, UserID: {user_id}")
        
            # Проверяем, что start_date <= end_date
            try:
                start_dt = datetime.strptime(start_date, "%d.%m.%Y")
                end_dt = datetime.strptime(end_date, "%d.%m.%Y")
            
                if start_dt > end_dt:
                    return jsonify({
                        "status": "error",
                        "message": "Start date must be earlier than or equal to end date"
                    }), 400
            except ValueError as e:
                return jsonify({
                    "status": "error",
                    "message": f"Invalid date format: {str(e)}. Use dd.mm.yyyy"
                }), 400
        
            # Получаем данные через обработчик
            df = server_ration_handler.get_ration_by_daterange(start_date, end_date)
        
            if df.empty:
                return jsonify({
                    "status": "success",
                    "rations": [],
                    "message": f"No ration data for period {start_date} - {end_date}"
                })
        
            # ФИЛЬТРАЦИЯ ПО UserID
            if 'UserID' in df.columns:
                # Фильтруем только записи текущего пользователя
                filtered_df = df[df['UserID'] == user_id]
                print(f"📊 Всего записей за период: {len(df)}, для UserID {user_id}: {len(filtered_df)}")
        
                if filtered_df.empty:
                    return jsonify({
                        "status": "success",
                        "rations": [],
                        "message": f"No ration data for user {user_id} in period {start_date} - {end_date}"
                    })
        
                df = filtered_df
        
            else:
                print("⚠️  В таблице RationInfo нет колонки UserID, фильтрация невозможна")
                return jsonify({
                    "status": "error",
                    "message": "UserID column not found in database"
                }), 500
        
            # Преобразуем данные для отправки
            rations_data = []
            for _, row in df.iterrows():
                # Форматируем даты
                ration_date_str = ""
                expire_date_str = ""
            
                # RationDate
                if pd.notna(row.get('RationDate')):
                    if isinstance(row['RationDate'], (int, float)):
                        ration_date_str = datetime.fromtimestamp(row['RationDate']).strftime("%d.%m.%Y")
                    else:
                        ration_date_str = str(row['RationDate'])
            
                # ExpireDate
                if pd.notna(row.get('ExpireDate')) and row['ExpireDate'] != '':
                    if isinstance(row['ExpireDate'], (int, float)):
                        expire_date_str = datetime.fromtimestamp(row['ExpireDate']).strftime("%d.%m.%Y")
                    else:
                        expire_date_str = str(row['ExpireDate'])
            
                ration_tuple = (
                    int(row['ProdID']) if pd.notna(row.get('ProdID')) else 0,
                    str(row.get('Name', '')),
                    float(row.get('Volume', 0)),
                    str(row.get('Unit', '')),
                    float(row.get('VolumeGr', 0)),
                    float(row.get('Kcal100g', 0)),
                    float(row.get('Prot100g', 0)),
                    float(row.get('Fat100g', 0)),
                    float(row.get('Carb100g', 0)),
                    expire_date_str,
                    str(row.get('Tag', '')),
                    str(row.get('Cat', '')),
                    int(row.get('MealID', 0)),
                    str(row.get('MealName', '')),
                    ration_date_str,
                    float(row.get('VolumeServ', 0)),
                    float(row.get('VolumeServGr', 0)),
                    float(row.get('KcalServ', 0)),
                    float(row.get('ProtServ', 0)),
                    float(row.get('FatServ', 0)),
                    float(row.get('CarbServ', 0)),
                    str(row.get('UserID', ''))
                )
                rations_data.append(ration_tuple)
        
                # ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА - ВСТАВЬТЕ ЗДЕСЬ
                print("🔍 ПРОВЕРКА ДАТ ПЕРЕД ОТПРАВКОЙ:")
                for i, ration in enumerate(rations_data[:3]):  # первые 3
                    print(f"   [{i}] Name: {ration[1]}")
                    print(f"       RationDate (позиция 14): '{ration[14]}'")
            # Дополнительная группировка по датам (опционально)
            grouped_by_date = {}
            for ration in rations_data:
                date = ration[14]  # ration_date_str находится на 14 позиции
                if date not in grouped_by_date:
                    grouped_by_date[date] = []
                grouped_by_date[date].append(ration)
        
            result = {
                "status": "success",
                "rations": rations_data,
                "count": len(rations_data),
                "date_range": {
                    "start_date": start_date,
                    "end_date": end_date
                },
                "grouped_by_date": grouped_by_date,  # Опционально
                "date_count": len(grouped_by_date)  # Количество дней с данными
            }
        
            print(f"✅ Отправлено {len(rations_data)} записей рациона за период {start_date} - {end_date} для UserID: {user_id}")
            print(f"   Дней с данными: {len(grouped_by_date)}")
        
            return jsonify(result)
        
        except Exception as e:
            print(f"❌ Ошибка при получении рациона за период: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
            
    @app.route('/get_allpurch_by_daterange', methods=['POST'])
    def get_allpurch_by_daterange():
        """Получение AllPurch за период дат для StatisticView"""
        try:
            data = request.get_json()
        
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
        
            start_date = data.get('start_date')
            end_date = data.get('end_date')
            user_id = data.get('user_id')
            family_id = data.get('family_id')
            user_acc_type = data.get('user_acc_type')  # 0 - личный, >0 - семейный
        
            # Валидация входных данных
            required_fields = ['start_date', 'end_date', 'user_id', 'family_id', 'user_acc_type']
            missing_fields = [field for field in required_fields if field not in data]
        
            if missing_fields:
                return jsonify({
                    "status": "error",
                    "message": f"Missing required fields: {', '.join(missing_fields)}"
                }), 400
        
            print(f"🔍 Получен запрос AllPurch за период: {start_date} - {end_date}")
            print(f"   UserID: {user_id}, FamilyID: {family_id}, AccType: {user_acc_type}")
        
            # Проверяем, что start_date <= end_date
            try:
                start_dt = datetime.strptime(start_date, "%d.%m.%Y")
                end_dt = datetime.strptime(end_date, "%d.%m.%Y")
            
                if start_dt > end_dt:
                    return jsonify({
                        "status": "error",
                        "message": "Start date must be earlier than or equal to end date"
                    }), 400
            except ValueError as e:
                return jsonify({
                    "status": "error",
                    "message": f"Invalid date format: {str(e)}. Use dd.mm.yyyy"
                }), 400
        
            # Получаем данные через DatabaseHandler
            df, error = db_handler.get_allpurch_by_daterange(start_date, end_date, user_id, family_id, user_acc_type)
        
            if error:
                return jsonify({"status": "error", "message": error}), 500
        
            if df.empty:
                return jsonify({
                    "status": "success",
                    "purchases": [],
                    "message": f"No purchase data for period {start_date} - {end_date}"
                })
        
            # Преобразуем данные для отправки - 15 элементов для существующей модели AllPurch
            purchases_data = []
            for _, row in df.iterrows():
                # Форматируем даты
                order_date_str = ""
                expire_date_str = ""
            
                # OrderDate (Date в Excel)
                if pd.notna(row.get('Date')):
                    if isinstance(row['Date'], (int, float)):
                        order_date_str = datetime.fromtimestamp(row['Date']).strftime("%d.%m.%Y")
                    else:
                        order_date_str = str(row['Date'])
            
                # ExpireDate
                if pd.notna(row.get('ExpireDate')) and row['ExpireDate'] != '':
                    if isinstance(row['ExpireDate'], (int, float)):
                        expire_date_str = datetime.fromtimestamp(row['ExpireDate']).strftime("%d.%m.%Y")
                    else:
                        expire_date_str = str(row['ExpireDate'])
            
                # PrefMeal и PrefMealID - устанавливаем по умолчанию, так как нет в Excel
                pref_meal_id = 0
                pref_meal = ""
            
                # Address и AddressID - берем из Excel
                address = str(row.get('Address', '')) if pd.notna(row.get('Address')) else ""
                address_id = int(row.get('AddressID', 0)) if pd.notna(row.get('AddressID')) else 0
            
                # Store и StoreID
                store = str(row.get('Store', '')) if pd.notna(row.get('Store')) else ""
                store_id = int(row.get('StoreID', 0)) if pd.notna(row.get('StoreID')) else 0
            
                # TotalCost - используем TotalCostPerCount вместо TotalCost
                # Проверяем наличие TotalCostPerCount, если нет - используем TotalCost как запасной вариант
                total_cost = 0.0
                if 'TotalCostPerCount' in df.columns and pd.notna(row.get('TotalCostPerCount')):
                    total_cost = float(row.get('TotalCostPerCount', 0))
                    print(f"   Используем TotalCostPerCount: {total_cost}")
                elif 'TotalCost' in df.columns and pd.notna(row.get('TotalCost')):
                    total_cost = float(row.get('TotalCost', 0))
                    print(f"   Используем TotalCost (запасной): {total_cost}")
                else:
                    print(f"   ⚠️ Нет TotalCostPerCount и TotalCost для строки {index}")
            
                # Формируем кортеж из 15 элементов для существующей модели AllPurch
                purchase_tuple = (
                    int(row.get('ProdID', 0)) if pd.notna(row.get('ProdID')) else 0,
                    str(row.get('Name', '')),
                    float(row.get('Volume', 0)) if pd.notna(row.get('Volume')) else 0,
                    str(row.get('Unit', '')),
                    float(row.get('VolumeGr', 0)) if pd.notna(row.get('VolumeGr')) else 0,
                    float(row.get('Kcal100g', 0)) if pd.notna(row.get('Kcal100g')) else 0,
                    float(row.get('Prot100g', 0)) if pd.notna(row.get('Prot100g')) else 0,
                    float(row.get('Fat100g', 0)) if pd.notna(row.get('Fat100g')) else 0,
                    float(row.get('Carb100g', 0)) if pd.notna(row.get('Carb100g')) else 0,
                    expire_date_str,
                    str(row.get('Tag', '')),
                    str(row.get('Cat', '')),
                    store,                     # Store
                    store_id,                  # StoreID
                    order_date_str,            # OrderDate
                    pref_meal_id,              # PrefMealID (по умолчанию)
                    pref_meal,                 # PrefMeal (по умолчанию)
                    total_cost,                # TotalCost
                    address,                   # Address
                    address_id                 # AddressID
                )
                purchases_data.append(purchase_tuple)
        
            result = {
                "status": "success",
                "purchases": purchases_data,
                "count": len(purchases_data),
                "date_range": {
                    "start_date": start_date,
                    "end_date": end_date
                }
            }
        
            print(f"✅ Отправлено {len(purchases_data)} записей AllPurch за период {start_date} - {end_date}")
        
            return jsonify(result)
        
        except Exception as e:
            print(f"❌ Ошибка при получении AllPurch за период: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    
    # ==================== ОБНОВЛЕНИЕ И УДАЛЕНИЕ ПОКУПОК ====================
    
    @app.route('/update_main_purch', methods=['POST'])
    def update_main_purch():
        """Обновление MainPurch (удаляет запись если объем = 0)"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            prod_id = data.get('prod_id')
            family_id = data.get('family_id')
            new_volume_gr = data.get('new_volume_gr')
            new_volume = data.get('new_volume')
            user_id = data.get('user_id')  # ← ДОБАВЛЯЕМ user_id
            
            print(f"🔧 Обновление MainPurch: ProdID {prod_id}, FamilyID {family_id}, UserID {user_id}")
            
            if not all([prod_id is not None, family_id, user_id, new_volume_gr is not None, new_volume is not None]):
                return jsonify({"status": "error", "message": "Missing required fields"}), 400
            
            try:
                df = db_handler.read_excel(db_handler.main_purch_path)
                
                family_id_int = int(family_id)
                prod_id_int = int(prod_id)
                
                # Создаем маску для поиска по полному ключу
                mask = (df['ProdID'] == prod_id_int) & (df['FamilyID'] == family_id_int)
                
                if user_id:
                    # Если есть UserID, добавляем его в фильтр
                    mask = mask & (df['UserID'] == user_id)
                
                if mask.any():
                    # ЕСЛИ ОБЪЕМ СТАЛ 0 - УДАЛЯЕМ ЗАПИСЬ
                    if new_volume_gr == 0:
                        df = df[~mask]  # Удаляем строку
                        print(f"🗑️ MainPurch УДАЛЕН: ProdID {prod_id}, FamilyID {family_id_int}, UserID {user_id}")
                        message = "MainPurch deleted successfully (volume reached 0)"
                    else:
                        # ИНАЧЕ ОБНОВЛЯЕМ
                        df.loc[mask, 'TotalVolumeGr'] = new_volume_gr
                        df.loc[mask, 'TotalVolume'] = new_volume
                        print(f"✅ MainPurch обновлен: ProdID {prod_id}, VolumeGr: {new_volume_gr}, Volume: {new_volume}")
                        message = "MainPurch updated successfully"
                    
                    db_handler.save_excel(df, db_handler.main_purch_path)
                    
                    return jsonify({
                        "status": "success",
                        "message": message,
                        "action": "deleted" if new_volume_gr == 0 else "updated"
                    })
                else:
                    print(f"❌ Продукт не найден: ProdID {prod_id}, FamilyID {family_id_int}, UserID {user_id}")
                    return jsonify({"status": "error", "message": "Product not found"}), 404
                    
            except Exception as e:
                print(f"❌ Ошибка обновления MainPurch: {str(e)}")
                return jsonify({"status": "error", "message": f"Database error: {str(e)}"}), 500
                
        except Exception as e:
            print(f"❌ Ошибка запроса: {str(e)}")
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    
    @app.route('/update_other_purch', methods=['POST'])
    def update_other_purch():
        """Обновление OtherPurch (удаляет запись если объем = 0)"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            prod_id = data.get('prod_id')
            family_id = data.get('family_id')
            store_id = data.get('store_id')
            order_date_str = data.get('order_date')
            new_volume_gr = data.get('new_volume_gr')
            new_volume = data.get('new_volume')
            user_id = data.get('user_id')  # ← ДОБАВЛЯЕМ user_id
            
            print(f"🔧 Обновление OtherPurch: ProdID {prod_id}, FamilyID {family_id}, StoreID {store_id}, UserID {user_id}, Date {order_date_str}")
            
            # Проверяем обязательные поля
            required_fields = ['prod_id', 'family_id', 'store_id', 'order_date', 'new_volume_gr', 'new_volume', 'user_id']
            missing_fields = [field for field in required_fields if data.get(field) is None]
            
            if missing_fields:
                error_msg = f"Missing required fields: {', '.join(missing_fields)}"
                print(f"❌ {error_msg}")
                return jsonify({"status": "error", "message": error_msg}), 400
            
            try:
                df = db_handler.read_excel(db_handler.other_purch_path)
                
                # Преобразуем типы
                family_id_int = int(family_id)
                store_id_int = int(store_id)
                prod_id_int = int(prod_id)
                
                # Конвертируем строку даты для сравнения
                order_date_formatted = None
                try:
                    order_date_dt = datetime.strptime(order_date_str, "%d.%m.%Y")
                    order_date_formatted = order_date_dt.strftime("%d.%m.%Y")
                except ValueError:
                    order_date_formatted = order_date_str
                
                # Создаем маску для поиска записи по полному ключу
                mask = (
                    (df['ProdID'] == prod_id_int) &
                    (df['FamilyID'] == family_id_int) &
                    (df['StoreID'] == store_id_int) &
                    (df['UserID'] == user_id)
                )
                
                # Фильтруем по дате
                date_matches = []
                for idx in df[mask].index:
                    date_val = df.loc[idx, 'Date']
                    if pd.isna(date_val):
                        continue
                        
                    if isinstance(date_val, (int, float)):
                        try:
                            date_dt = datetime.fromtimestamp(date_val)
                            date_str = date_dt.strftime("%d.%m.%Y")
                        except:
                            date_str = str(date_val)
                    else:
                        date_str = str(date_val)
                    
                    if date_str == order_date_formatted:
                        date_matches.append(idx)
                
                if date_matches:
                    idx = date_matches[0]
                    
                    if new_volume_gr == 0:
                        df = df.drop(idx)
                        print(f"🗑️ OtherPurch УДАЛЕН: ProdID {prod_id}, FamilyID {family_id_int}, StoreID {store_id_int}, UserID {user_id}, Date {order_date_formatted}")
                        message = "OtherPurch deleted successfully (volume reached 0)"
                        action = "deleted"
                    else:
                        df.loc[idx, 'TotalVolumeGr'] = new_volume_gr
                        df.loc[idx, 'TotalVolume'] = new_volume
                        print(f"✅ OtherPurch обновлен: ProdID {prod_id}, VolumeGr: {new_volume_gr}, Volume: {new_volume}, UserID {user_id}")
                        message = "OtherPurch updated successfully"
                        action = "updated"
                    
                    db_handler.save_excel(df, db_handler.other_purch_path)
                    
                    return jsonify({
                        "status": "success",
                        "message": message,
                        "action": action
                    })
                else:
                    print(f"❌ Продукт не найден: ProdID {prod_id}, FamilyID {family_id_int}, StoreID {store_id_int}, UserID {user_id}, Date {order_date_formatted}")
                    return jsonify({"status": "error", "message": "Product not found"}), 404
                    
            except Exception as e:
                print(f"❌ Ошибка обновления OtherPurch: {str(e)}")
                import traceback
                traceback.print_exc()
                return jsonify({"status": "error", "message": f"Database error: {str(e)}"}), 500
                
        except Exception as e:
            print(f"❌ Ошибка запроса: {str(e)}")
            return jsonify({"status": "error", "message": f"Server error: {str(e)}"}), 500
    
    @app.route('/search_products', methods=['POST'])
    def search_products():
        """Поиск товаров"""
        try:
            data = request.get_json()
            
            if not data:
                return jsonify({"status": "error", "message": "No JSON data provided"}), 400
            
            search_term = data.get('search_term', '').lower()
            
            if not search_term or search_term.strip() == '':
                return jsonify({"status": "success", "products": [], "count": 0, "message": "Введите поисковый запрос"})
            
            print(f"🔍 Поиск товара: '{search_term}'")
            
            results, error = db_handler.search_products(search_term)
            
            if error:
                return jsonify({"status": "error", "message": error}), 500
            
            return jsonify({
                "status": "success",
                "products": results,
                "count": len(results),
                "message": f"Найдено {len(results)} товаров по запросу '{search_term}'"
            })
            
        except Exception as e:
            print(f"❌ Ошибка при поиске: {str(e)}")
            return jsonify({"status": "error", "message": f"Ошибка сервера: {str(e)}"}), 500
    
    # ==================== ИЗОБРАЖЕНИЯ ====================
    
    @app.route('/image/<int:prod_id>')
    def get_image(prod_id):
        """Получение изображения продукта"""
        from modules.images_handler import get_image_handler
        image_handler = get_image_handler()
        
        if not image_handler:
            return jsonify({"error": "Images handler not initialized"}), 500
        
        response = image_handler.serve_image(prod_id)
        if response:
            return response
        else:
            return jsonify({"error": "Image not found"}), 404
            
    @app.route('/product_link/<int:prod_id>')
    def get_product_link(prod_id):
        """Получение ссылки на продукт из Excel файла"""
        try:
            excel_path = prodlinks_path
        
            # Проверяем существование файла
            if not os.path.exists(excel_path):
                return jsonify({
                    "success": False,
                    "error": "Excel file not found"
                }), 404
        
            # Читаем Excel файл
            df = pd.read_excel(excel_path)
        
            # Проверяем наличие необходимых колонок
            required_columns = ['ProdID', 'ProductURL']
            for col in required_columns:
                if col not in df.columns:
                    return jsonify({
                        "success": False,
                        "error": f"Excel file must contain '{col}' column"
                    }), 400
        
            # Ищем продукт по ProdID
            product_row = df[df['ProdID'] == prod_id]
        
            if not product_row.empty:
                # Получаем URL из первого найденного ряда
                url_value = product_row.iloc[0]['ProductURL']
            
                # Проверяем, что значение не NaN/None и не пустая строка
                if pd.notna(url_value):
                    url = str(url_value).strip()
                    if url and url.lower() != 'nan':
                        return jsonify({
                            "success": True,
                            "data": {
                                "prodID": prod_id,
                                "url": url
                            }
                        })
        
            # Если продукт не найден или URL пустой
            return jsonify({
                "success": False,
                "error": "Product link not found"
            })
        
        except pd.errors.EmptyDataError:
            return jsonify({
                "success": False,
                "error": "Excel file is empty or corrupted"
            }), 400
        except Exception as e:
            print(f"❌ Error in get_product_link: {str(e)}")
            return jsonify({
                "success": False,
                "error": f"Internal server error: {str(e)}"
            }), 500
    
    print("✅ Все API маршруты зарегистрированы")
    print("   Новые endpoint'ы с UserID и FamilyID:")
    print("   - /get_main_purch - 20 элементов")
    print("   - /get_other_purch - 19 элементов")
    print("   Старые endpoint'ы для совместимости:")
    print("   - /get_family_main - 17 элементов")
    print("   - /get_family_other - 17 элементов")
