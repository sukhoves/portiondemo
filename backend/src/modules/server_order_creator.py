"""
Серверный обработчик создания заказов (для endpoint /create_order)
"""

import pandas as pd
import os
from datetime import datetime

class ServerOrderCreator:
    """Серверный обработчик создания заказов (заменяет SwiftData логику)"""
    
    def __init__(self, db_handler):
        self.db_handler = db_handler
        # ИСПРАВЛЯЕМ ЭТУ СТРОКУ:
        self.all_purch_path = os.path.join(db_handler.orders_dir, 'allpurch.xlsx')  # ← было db_handler.data_dir
        
        # Создаем файл AllPurch.xlsx если его нет
        self._ensure_allpurch_file()
        
    def _ensure_allpurch_file(self):
        """Создает файл AllPurch.xlsx если его не существует (с новыми колонками)"""
        if not os.path.exists(self.all_purch_path):
            print(f"📄 Создаю файл AllPurch.xlsx...")
            
            # Определяем колонки (добавляем новые)
            columns = [
                'ProdID', 'Name', 'Volume', 'Unit', 'VolumeGr',
                'Kcal100g', 'Prot100g', 'Fat100g', 'Carb100g',
                'ExpireDate', 'Tag', 'Cat', 'Store', 'StoreID',
                'Date', 'FamilyID', 'TotalCost', 'Address', 'AddressID',
                'Count', 'TotalVolume', 'TotalVolumeGr', 'TotalCostPerCount',
                'UserID'  # ← ДОБАВИЛ UserID В КОЛОНКИ
            ]
            
            # Создаем пустой DataFrame
            df = pd.DataFrame(columns=columns)
            
            # Сохраняем
            df.to_excel(self.all_purch_path, index=False)
            print(f"✅ Файл AllPurch.xlsx создан: {self.all_purch_path}")
    
    def create_order_from_cart(self, order_data):
        """Основная логика создания заказа на сервере"""
        # Добавим отладочную печать
        print(f"📱 DEBUG: Получен order_data: {list(order_data.keys())}")
        print(f"📱 DEBUG: family_id = {order_data.get('family_id')}")
        print(f"📱 DEBUG: address_id = {order_data.get('address_id')}")
        print(f"📱 DEBUG: user_id = {order_data.get('user_id')}")
        print(f"📱 DEBUG: items count = {len(order_data.get('items', []))}")
        
        # Проверяем обязательные поля
        required_fields = ['family_id', 'address_id', 'order_date', 'items']
        for field in required_fields:
            if field not in order_data:
                return {"status": "error", "message": f"Missing required field: {field}"}
        
        if not order_data['items']:
            return {"status": "error", "message": "Cart is empty"}
            
        # Получаем user_id если есть
        user_id = order_data.get('user_id', '')
        
        # Получаем данные из базы товаров
        products_df = self.db_handler.read_excel(self.db_handler.products_db_path)
        
        # Готовим данные для сохранения
        all_items = []
        main_items = []
        other_items = []
        
        for cart_item in order_data['items']:
            prod_id = cart_item.get('prod_id')
            quantity = cart_item.get('quantity', 1)
            
            # Ищем товар в базе
            product_row = products_df[products_df['ProdID'] == prod_id]
            
            if product_row.empty:
                print(f"⚠️ Товар ProdID {prod_id} не найден в базе, пропускаем")
                continue
            
            # Получаем данные товара
            row = product_row.iloc[0]
            
            # Обрабатываем StoreID
            store_id_value = row.get('StoreID')
            if pd.isna(store_id_value):
                store_id = 1
            else:
                try:
                    store_id = int(store_id_value)
                except:
                    store_id = 1
            
            # Сохраняем исходные значения (для 1 единицы товара)
            volume_per_unit = float(row.get('Volume', 0))
            volume_gr_per_unit = float(row.get('VolumeGr', 0))
            total_cost_per_unit = float(row.get('TotalCost', 0))
            
            # Формируем запись с оригинальными значениями (для 1 единицы)
            record = {
                'ProdID': int(prod_id),
                'Name': str(row.get('Name', '')),
                'Volume': float(volume_per_unit),  # Для 1 единицы
                'Unit': str(row.get('Unit', 'шт')),
                'VolumeGr': float(volume_gr_per_unit),  # Для 1 единицы
                'Kcal100g': float(row.get('Kcal100g', 0)),
                'Prot100g': float(row.get('Prot100g', 0)),
                'Fat100g': float(row.get('Fat100g', 0)),
                'Carb100g': float(row.get('Carb100g', 0)),
                'ExpireDate': '',  # Пустая строка
                'Tag': str(row.get('Tag', '')),
                'Cat': str(row.get('Cat', '')),
                'Store': str(row.get('Store', 'Лавка')),
                'StoreID': int(store_id),
                'Date': str(order_data['order_date']),
                'FamilyID': int(order_data['family_id']),
                'TotalCost': float(total_cost_per_unit),  # Для 1 единицы
                'Address': f"Адрес {order_data['address_id']}",
                'AddressID': int(order_data['address_id']),
                'UserID': user_id,  # ← UserID из заказа
                'quantity': quantity  # Добавляем quantity для использования в агрегации
            }
            
            # Добавляем во все коллекции
            all_items.append(record)
            
            if store_id == 1:
                main_items.append(record)
            else:
                other_items.append(record)
        
        if not all_items:
            return {"status": "error", "message": "No valid items found in cart"}
        
        print(f"📦 Подготовлено для сохранения:")
        print(f"   Всего товаров: {len(all_items)}")
        print(f"   UserID: {user_id}")
        print(f"   Для MainPurch (StoreID=1): {len(main_items)}")
        print(f"   Для OtherPurch: {len(other_items)}")
        
        # Сохраняем в файлы
        try:
            # 1. Сохраняем в AllPurch
            all_saved = self._save_to_all_purch(all_items)
            
            # 2. Сохраняем/обновляем в MainPurch (с новой агрегацией)
            main_updated = self._update_main_purch_with_aggregation(main_items)
            
            # 3. Сохраняем в OtherPurch с агрегацией
            other_saved = self._save_to_other_purch(other_items)
            
            return {
                "status": "success",
                "message": f"✅ Заказ успешно создан! Сохранено {all_saved} товаров в AllPurch, обновлено {main_updated} в MainPurch, обновлено {other_saved} в OtherPurch",
                "data": {
                    "all_saved": all_saved,
                    "main_updated": main_updated,
                    "other_saved": other_saved,
                    "total_items": len(all_items),
                    "user_id": user_id
                }
            }
            
        except Exception as e:
            print(f"❌ Ошибка при сохранении заказа: {str(e)}")
            import traceback
            traceback.print_exc()
            return {"status": "error", "message": f"Error saving order: {str(e)}"}
    
    def _save_to_all_purch(self, items):
        """Сохраняет все товары в AllPurch.xlsx (с расчетными полями, но без агрегации)"""
        try:
            if not items:
                return 0
            
            # Подготавливаем данные для AllPurch с расчетными полями
            all_purch_items = []
            for item in items:
                quantity = item.get('quantity', 1)
                
                order_date = datetime.strptime(item['Date'], "%d.%m.%Y")
                item['Date'] = int(order_date.timestamp())
                
                # Копируем основные поля
                all_purch_item = {k: v for k, v in item.items()
                                 if k not in ['quantity']}
                
                # Добавляем расчетные поля
                all_purch_item['Count'] = quantity
                all_purch_item['TotalVolume'] = item['Volume'] * quantity
                all_purch_item['TotalVolumeGr'] = item['VolumeGr'] * quantity
                all_purch_item['TotalCostPerCount'] = item['TotalCost'] * quantity
                
                # Убедимся, что UserID есть
                if 'UserID' not in all_purch_item:
                    all_purch_item['UserID'] = item.get('UserID', '')
                
                all_purch_items.append(all_purch_item)
            
            # Создаем DataFrame
            df = pd.DataFrame(all_purch_items)
            
            # Если файл существует, добавляем к существующим данным
            if os.path.exists(self.all_purch_path):
                existing_df = pd.read_excel(self.all_purch_path)
                
                # Заполняем NaN в новых столбцах
                for col in ['Count', 'TotalVolume', 'TotalVolumeGr', 'TotalCostPerCount']:
                    if col in existing_df.columns:
                        existing_df[col] = existing_df[col].fillna(0)
                    else:
                        # Если столбца нет, создаем его с нулями
                        existing_df[col] = 0
                
                # Для UserID заполняем пустыми строками
                if 'UserID' in existing_df.columns:
                    existing_df['UserID'] = existing_df['UserID'].fillna('')
                else:
                    existing_df['UserID'] = ''
                
                combined_df = pd.concat([existing_df, df], ignore_index=True)
            else:
                combined_df = df
            
            # Сохраняем
            combined_df.to_excel(self.all_purch_path, index=False)
            print(f"✅ Сохранено {len(items)} товаров в AllPurch.xlsx (с расчетными полями)")
            return len(items)
            
        except Exception as e:
            print(f"❌ Ошибка сохранения в AllPurch: {e}")
            import traceback
            traceback.print_exc()
            return 0
    
    def _update_main_purch_with_aggregation(self, items):
        """Обновляет MainPurch.xlsx с агрегацией (ProdID + FamilyID + UserID)"""
        try:
            if not items:
                return 0
                
            main_purch_path = self.db_handler.main_purch_path
            
            print(f"🔄 Обновление MainPurch: получено {len(items)} товаров")
            
            # Создаем DataFrame из новых товаров с расчетными полями
            new_items_list = []
            for item in items:
                quantity = item.get('quantity', 1)
                new_item = item.copy()  # Копируем все поля
                
                # Добавляем расчетные поля
                new_item['Count'] = quantity
                new_item['TotalVolume'] = item['Volume'] * quantity
                new_item['TotalVolumeGr'] = item['VolumeGr'] * quantity
                new_item['TotalCostPerCount'] = item['TotalCost'] * quantity
                
                # Удаляем временное поле quantity
                if 'quantity' in new_item:
                    del new_item['quantity']
                
                new_items_list.append(new_item)
            
            new_df = pd.DataFrame(new_items_list)
            
            if os.path.exists(main_purch_path):
                # Читаем существующие данные
                existing_df = pd.read_excel(main_purch_path)
                print(f"📊 Существующий MainPurch содержит {len(existing_df)} записей")
                
                # Объединяем
                combined_df = pd.concat([existing_df, new_df], ignore_index=True)
                print(f"📊 После объединения: {len(combined_df)} записей")
                
                # Заполняем NaN значения
                for col in ['Count', 'TotalVolume', 'TotalVolumeGr', 'TotalCostPerCount']:
                    if col in combined_df.columns:
                        combined_df[col] = combined_df[col].fillna(0)
                
                # Заполняем UserID пустыми строками
                if 'UserID' in combined_df.columns:
                    combined_df['UserID'] = combined_df['UserID'].fillna('')
                else:
                    combined_df['UserID'] = ''
                
                # Определяем функции агрегации
                agg_functions = {
                    'Name': 'first',
                    'Volume': 'first',
                    'Unit': 'first',
                    'VolumeGr': 'first',
                    'Kcal100g': 'first',
                    'Prot100g': 'first',
                    'Fat100g': 'first',
                    'Carb100g': 'first',
                    'ExpireDate': 'first',
                    'Tag': 'first',
                    'Cat': 'first',
                    'Store': 'first',
                    'StoreID': 'first',
                    'Date': 'min',
                    'TotalCost': 'first',
                    'Address': 'first',
                    'AddressID': 'first',
                    'Count': 'sum',
                    'TotalVolume': 'sum',
                    'TotalVolumeGr': 'sum',
                    'TotalCostPerCount': 'sum'
                }
                
                # Убираем столбцы, которых нет в DataFrame
                agg_functions = {k: v for k, v in agg_functions.items()
                               if k in combined_df.columns}
                
                # Агрегируем по ProdID, FamilyID и UserID
                print(f"🔍 Агрегация по ['ProdID', 'FamilyID', 'UserID']...")
                agg_df = combined_df.groupby(['ProdID', 'FamilyID', 'UserID']).agg(agg_functions).reset_index()
                
                print(f"📊 После агрегации: {len(agg_df)} уникальных записей (ProdID+FamilyID+UserID)")
                
                # Сохраняем агрегированные данные
                agg_df.to_excel(main_purch_path, index=False)
                print(f"✅ MainPurch обновлен. Уникальных записей: {len(agg_df)}")
                return len(agg_df)
            else:
                # Создаем новый файл
                new_df.to_excel(main_purch_path, index=False)
                print(f"✅ MainPurch создан. Добавлено {len(items)} товаров")
                return len(items)
                
        except Exception as e:
            print(f"❌ Ошибка обновления MainPurch: {e}")
            import traceback
            traceback.print_exc()
            return 0
    
    def _save_to_other_purch(self, items):
        """Сохраняет товары в OtherPurch.xlsx с агрегацией (ProdID + FamilyID + StoreID + Date + UserID)"""
        try:
            if not items:
                return 0
                
            other_purch_path = self.db_handler.other_purch_path
            
            print(f"🔄 Обновление OtherPurch: получено {len(items)} товаров")
            
            # Создаем DataFrame из новых товаров с расчетными полями
            new_items_list = []
            for item in items:
                quantity = item.get('quantity', 1)
                new_item = item.copy()  # Копируем все поля
                
                # Добавляем расчетные поля
                new_item['Count'] = quantity
                new_item['TotalVolume'] = item['Volume'] * quantity
                new_item['TotalVolumeGr'] = item['VolumeGr'] * quantity
                new_item['TotalCostPerCount'] = item['TotalCost'] * quantity
                
                # Удаляем временное поле quantity
                if 'quantity' in new_item:
                    del new_item['quantity']
                
                new_items_list.append(new_item)
            
            new_df = pd.DataFrame(new_items_list)
            
            if os.path.exists(other_purch_path):
                # Читаем существующие данные
                existing_df = pd.read_excel(other_purch_path)
                print(f"📊 Существующий OtherPurch содержит {len(existing_df)} записей")
                
                # Объединяем
                combined_df = pd.concat([existing_df, new_df], ignore_index=True)
                print(f"📊 После объединения: {len(combined_df)} записей")
                
                # Заполняем NaN значения
                for col in ['Count', 'TotalVolume', 'TotalVolumeGr', 'TotalCostPerCount']:
                    if col in combined_df.columns:
                        combined_df[col] = combined_df[col].fillna(0)
                
                # Заполняем UserID пустыми строками
                if 'UserID' in combined_df.columns:
                    combined_df['UserID'] = combined_df['UserID'].fillna('')
                else:
                    combined_df['UserID'] = ''
                
                # Определяем функции агрегации
                agg_functions = {
                    'Name': 'first',
                    'Volume': 'first',
                    'Unit': 'first',
                    'VolumeGr': 'first',
                    'Kcal100g': 'first',
                    'Prot100g': 'first',
                    'Fat100g': 'first',
                    'Carb100g': 'first',
                    'ExpireDate': 'first',
                    'Tag': 'first',
                    'Cat': 'first',
                    'Store': 'first',
                    'TotalCost': 'first',
                    'Address': 'first',
                    'AddressID': 'first',
                    'Count': 'sum',
                    'TotalVolume': 'sum',
                    'TotalVolumeGr': 'sum',
                    'TotalCostPerCount': 'sum'
                }
                
                # Убираем столбцы, которых нет в DataFrame
                agg_functions = {k: v for k, v in agg_functions.items()
                               if k in combined_df.columns}
                
                # Агрегируем по ProdID, FamilyID, StoreID, Date и UserID
                print(f"🔍 Агрегация OtherPurch по ['ProdID', 'FamilyID', 'StoreID', 'Date', 'UserID']...")
                agg_df = combined_df.groupby(['ProdID', 'FamilyID', 'StoreID', 'Date', 'UserID']).agg(agg_functions).reset_index()
                
                print(f"📊 После агрегации: {len(agg_df)} уникальных записей")
                
                # Сохраняем агрегированные данные
                agg_df.to_excel(other_purch_path, index=False)
                print(f"✅ OtherPurch обновлен. Уникальных записей: {len(agg_df)}")
                return len(agg_df)
            else:
                # Создаем новый файл
                new_df.to_excel(other_purch_path, index=False)
                print(f"✅ OtherPurch создан. Добавлено {len(items)} товаров")
                return len(items)
                
        except Exception as e:
            print(f"❌ Ошибка обновления OtherPurch: {e}")
            import traceback
            traceback.print_exc()
            return 0
