"""
Серверный обработчик рациона (RationInfo)
"""

import pandas as pd
import os
from datetime import datetime

class ServerRationHandler:
    """Обработчик операций с рационом на сервере"""
    
    def __init__(self, db_handler):
        self.db_handler = db_handler
        
    def add_to_ration(self, ration_data):
        """Добавление продукта в серверный рацион"""
        try:
            print(f"🍽️  Добавление в серверный рацион: {ration_data.get('name', 'Unknown product')}")
            
            # Проверяем обязательные поля
            required_fields = [
                'prod_id', 'name', 'volume', 'unit', 'volume_gr',
                'kcal100g', 'prot100g', 'fat100g', 'carb100g', 'meal_id',
                'meal_name', 'ration_date', 'volume_serv', 'volume_serv_gr',
                'kcal_serv', 'prot_serv', 'fat_serv', 'carb_serv', 'user_id'
            ]
            
            missing_fields = [field for field in required_fields if field not in ration_data]
            if missing_fields:
                error_msg = f"Отсутствуют обязательные поля: {', '.join(missing_fields)}"
                print(f"❌ {error_msg}")
                return {"status": "error", "message": error_msg}
            
            # Преобразуем даты
            try:
                # RationDate
                ration_date_str = ration_data.get('ration_date')
                ration_date = datetime.strptime(ration_date_str, "%d.%m.%Y")
                ration_timestamp = int(ration_date.timestamp())
                
                # ExpireDate (может быть пустым)
                expire_date_str = ration_data.get('expire_date', '')
                expire_timestamp = ''
                if expire_date_str and expire_date_str.strip():
                    expire_date = datetime.strptime(expire_date_str, "%d.%m.%Y")
                    expire_timestamp = int(expire_date.timestamp())
            except ValueError as e:
                error_msg = f"Неверный формат даты: {str(e)}. Используйте dd.mm.yyyy"
                print(f"❌ {error_msg}")
                return {"status": "error", "message": error_msg}
            
            # Формируем запись для RationInfo
            ration_record = {
                'ProdID': int(ration_data['prod_id']),
                'Name': str(ration_data['name']),
                'Volume': float(ration_data['volume']),
                'Unit': str(ration_data['unit']),
                'VolumeGr': float(ration_data['volume_gr']),
                'Kcal100g': float(ration_data['kcal100g']),
                'Prot100g': float(ration_data['prot100g']),
                'Fat100g': float(ration_data['fat100g']),
                'Carb100g': float(ration_data['carb100g']),
                'ExpireDate': expire_timestamp,
                'Tag': str(ration_data.get('tag', '')),
                'Cat': str(ration_data.get('cat', '')),
                'MealID': int(ration_data['meal_id']),
                'MealName': str(ration_data['meal_name']),
                'RationDate': ration_timestamp,
                'VolumeServ': float(ration_data['volume_serv']),
                'VolumeServGr': float(ration_data['volume_serv_gr']),
                'KcalServ': float(ration_data['kcal_serv']),
                'ProtServ': float(ration_data['prot_serv']),
                'FatServ': float(ration_data['fat_serv']),
                'CarbServ': float(ration_data['carb_serv']),
                'UserID': str(ration_data['user_id']),  # ← ДОБАВИЛ! (UUID в формате строки)
                'CreatedAt': int(datetime.now().timestamp())
            }
            
            # Сохраняем в RationInfo.xlsx
            success = self.db_handler.save_to_ration_info(ration_record)
            
            if success:
                print(f"✅ Продукт добавлен в серверный рацион:")
                print(f"   Name: {ration_record['Name']}")
                print(f"   UserID: {ration_record['UserID']}")  # ← ДОБАВИЛ логирование
                print(f"   Meal: {ration_record['MealName']} ({ration_record['MealID']})")
                print(f"   Date: {ration_date_str}")
                print(f"   Volume: {ration_record['VolumeServ']} {ration_record['Unit']}")
                
                return {
                    "status": "success",
                    "message": "Продукт успешно добавлен в рацион"
                }
            else:
                return {
                    "status": "error",
                    "message": "Не удалось сохранить в RationInfo"
                }
                
        except Exception as e:
            print(f"❌ Ошибка добавления в рацион: {str(e)}")
            import traceback
            traceback.print_exc()
            return {
                "status": "error",
                "message": f"Ошибка сервера: {str(e)[:200]}"
            }
    
    def get_ration_by_date(self, ration_date_str):
        """Получение ВСЕГО рациона по дате (без фильтрации по UserID)"""
        try:
            if not os.path.exists(self.db_handler.ration_info_path):
                return pd.DataFrame()
            
            df = self.db_handler.read_excel(self.db_handler.ration_info_path)
            
            if df.empty:
                return df
            
            # Преобразуем дату для фильтрации
            ration_date = datetime.strptime(ration_date_str, "%d.%m.%Y")
            ration_timestamp = int(ration_date.timestamp())
            
            # Фильтруем по дате (совпадение дня, месяца, года)
            def is_same_date(timestamp1, timestamp2):
                if pd.isna(timestamp1) or timestamp1 == '':
                    return False
                dt1 = datetime.fromtimestamp(float(timestamp1))
                dt2 = datetime.fromtimestamp(float(timestamp2))
                return dt1.date() == dt2.date()
            
            mask = df['RationDate'].apply(lambda x: is_same_date(x, ration_timestamp))
            return df[mask]
            
        except Exception as e:
            print(f"❌ Ошибка получения рациона: {str(e)}")
            return pd.DataFrame()
            
    def get_ration_by_daterange(self, start_date_str, end_date_str):
        """Получение рациона за период дат"""
        try:
            if not os.path.exists(self.db_handler.ration_info_path):
                return pd.DataFrame()
        
            df = self.db_handler.read_excel(self.db_handler.ration_info_path)
        
            if df.empty:
                return df
        
            # Преобразуем даты для фильтрации
            start_date = datetime.strptime(start_date_str, "%d.%m.%Y")
            end_date = datetime.strptime(end_date_str, "%d.%m.%Y")
        
            # Убедимся, что end_date включает весь день
            end_date = end_date.replace(hour=23, minute=59, second=59)
        
            # Конвертируем в timestamp
            start_timestamp = int(start_date.timestamp())
            end_timestamp = int(end_date.timestamp())
        
            # Фильтруем по периоду дат
            def is_in_range(timestamp):
                if pd.isna(timestamp) or timestamp == '':
                    return False
                try:
                    ts = float(timestamp)
                    return start_timestamp <= ts <= end_timestamp
                except:
                    return False
        
            mask = df['RationDate'].apply(is_in_range)
            return df[mask]
        
        except Exception as e:
            print(f"❌ Ошибка получения рациона за период: {str(e)}")
            import traceback
            traceback.print_exc()
            return pd.DataFrame()
