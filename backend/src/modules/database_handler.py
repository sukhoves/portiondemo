"""
Модуль для работы с Excel файлами и данными
"""

import pandas as pd
import os
from datetime import datetime, timedelta
import random

class DatabaseHandler:
    """Обработчик базы данных с новой структурой"""
    
    def __init__(self, orders_dir, users_dir, products_dir):
        self.orders_dir = orders_dir
        self.users_dir = users_dir
        self.products_dir = products_dir
        
        # Основные файлы
        self.main_purch_path = os.path.join(orders_dir, 'mainpurch.xlsx')
        self.other_purch_path = os.path.join(orders_dir, 'otherpurch.xlsx')
        self.all_purch_path = os.path.join(orders_dir, 'allpurch.xlsx')
        self.ration_info_path = os.path.join(users_dir, 'rationinfo.xlsx')
        self.products_db_path = os.path.join(products_dir, 'appdb2.xlsx')
        self.images_dir = os.path.join(products_dir, 'images')
        
        print(f"📁 DatabaseHandler инициализирован с новой структурой")
        print(f"   Orders Dir: {orders_dir}")
        print(f"   Users Dir: {users_dir}")
        print(f"   Products Dir: {products_dir}")
    
    def read_excel(self, filepath):
        """Чтение Excel файла"""
        if os.path.exists(filepath):
            return pd.read_excel(filepath)
        else:
            raise FileNotFoundError(f"Файл не найден: {filepath}")
    
    def save_excel(self, df, filepath):
        """Сохранение DataFrame в Excel"""
        df.to_excel(filepath, index=False)
        return True
    
    def update_purchases_files(self, df):
        """Обновление файлов MainPurch.xlsx и OtherPurch.xlsx"""
        try:
            # Разделяем данные по StoreID
            main_purch_data = df[df['StoreID'] == 1].copy()
            other_purch_data = df[df['StoreID'] != 1].copy()
            
            # Обрабатываем MainPurch.xlsx
            if not main_purch_data.empty:
                if os.path.exists(self.main_purch_path):
                    existing_main = self.read_excel(self.main_purch_path)
                    combined_main = pd.concat([existing_main, main_purch_data], ignore_index=True)
                    
                    # Агрегируем по полному ключу
                    agg_main = combined_main.groupby(['ProdID', 'UserID', 'FamilyID']).agg({
                        'Name': 'first',
                        'Volume': 'sum',
                        'Unit': 'first',
                        'VolumeGr': 'sum',
                        'Kcal100g': 'first',
                        'Prot100g': 'first',
                        'Fat100g': 'first',
                        'Carb100g': 'first',
                        'ExpireDate': 'min',
                        'Tag': 'first',
                        'Cat': 'first',
                        'Store': 'first',
                        'StoreID': 'first',
                        'Date': 'min',
                        'TotalCost': 'sum',
                        'Address': 'first',
                        'AddressID': 'first'
                    }).reset_index()
                    
                    self.save_excel(agg_main, self.main_purch_path)
                    print(f"✅ MainPurch.xlsx обновлен. Добавлено {len(main_purch_data)} записей")
                else:
                    self.save_excel(main_purch_data, self.main_purch_path)
                    print(f"✅ MainPurch.xlsx создан. Добавлено {len(main_purch_data)} записей")
            
            # Обрабатываем OtherPurch.xlsx
            if not other_purch_data.empty:
                if os.path.exists(self.other_purch_path):
                    existing_other = self.read_excel(self.other_purch_path)
                    combined_other = pd.concat([existing_other, other_purch_data], ignore_index=True)
                    
                    # Агрегируем по полному ключу
                    agg_other = combined_other.groupby(['ProdID', 'UserID', 'FamilyID', 'StoreID', 'Date']).agg({
                        'Name': 'first',
                        'Volume': 'sum',
                        'Unit': 'first',
                        'VolumeGr': 'sum',
                        'Kcal100g': 'first',
                        'Prot100g': 'first',
                        'Fat100g': 'first',
                        'Carb100g': 'first',
                        'Tag': 'first',
                        'Cat': 'first',
                        'Store': 'first',
                        'TotalCost': 'sum',
                        'Address': 'first',
                        'AddressID': 'first'
                    }).reset_index()
                    
                    self.save_excel(agg_other, self.other_purch_path)
                    print(f"✅ OtherPurch.xlsx обновлен. Добавлено {len(other_purch_data)} записей")
                else:
                    self.save_excel(other_purch_data, self.other_purch_path)
                    print(f"✅ OtherPurch.xlsx создан. Добавлено {len(other_purch_data)} записей")
            
            return True
            
        except Exception as e:
            print(f"❌ Ошибка при обновлении файлов покупок: {e}")
            return False
    
    def get_family_data(self, family_id, file_type='main'):
        """Получение данных по FamilyID (старый метод для обратной совместимости)"""
        try:
            family_id_int = int(family_id)
            
            if file_type == 'main':
                filepath = self.main_purch_path
                file_name = "MainPurch"
            else:
                filepath = self.other_purch_path
                file_name = "OtherPurch"
            
            if not os.path.exists(filepath):
                return None, f"{file_name}.xlsx не найден"
            
            df = self.read_excel(filepath)
            family_data = df[df['FamilyID'] == family_id_int]
            
            return family_data, None
            
        except Exception as e:
            return None, str(e)
    
    def get_purch_data(self, family_id=None, user_id=None, file_type='main'):
        """Получение данных по FamilyID или UserID с учетом типа аккаунта"""
        try:
            if file_type == 'main':
                filepath = self.main_purch_path
                file_name = "MainPurch"
                is_main_purch = True
            else:
                filepath = self.other_purch_path
                file_name = "OtherPurch"
                is_main_purch = False
            
            if not os.path.exists(filepath):
                return None, f"{file_name}.xlsx не найден"
            
            df = self.read_excel(filepath)
            
            # Проверяем наличие необходимых колонок
            has_family_id = 'FamilyID' in df.columns
            has_user_id = 'UserID' in df.columns
            has_store_id = 'StoreID' in df.columns
            has_date = 'Date' in df.columns
            
            filtered_data = pd.DataFrame()
            
            # ЛОГИКА ФИЛЬТРАЦИИ:
            if user_id and family_id == "0":
                # 1. ЛИЧНЫЙ АККАУНТ: UserID = UUID и FamilyID = 0
                if has_user_id and has_family_id:
                    try:
                        # Приводим FamilyID к числу для сравнения
                        df['FamilyID_numeric'] = pd.to_numeric(df['FamilyID'], errors='coerce')
                        filtered_data = df[(df['UserID'] == user_id) & (df['FamilyID_numeric'] == 0)]
                        print(f"🔍 {file_name}: Личный аккаунт - UserID={user_id}, FamilyID=0, найдено: {len(filtered_data)} записей")
                    except Exception as e:
                        print(f"⚠️ {file_name}: Ошибка фильтрации личного аккаунта: {e}")
                        # Fallback: только по UserID
                        filtered_data = df[df['UserID'] == user_id]
                elif has_user_id:
                    # Если нет колонки FamilyID, фильтруем только по UserID
                    filtered_data = df[df['UserID'] == user_id]
                    print(f"🔍 {file_name}: Личный аккаунт (без FamilyID) - UserID={user_id}, найдено: {len(filtered_data)} записей")
                else:
                    print(f"⚠️ {file_name}: Нет колонки UserID для личного аккаунта")
                    filtered_data = pd.DataFrame()
            
            elif family_id and family_id != "0":
                # 2. СЕМЕЙНЫЙ АККАУНТ: только по FamilyID
                if has_family_id:
                    try:
                        family_id_int = int(family_id)
                        # Фильтруем по FamilyID
                        filtered_data = df[df['FamilyID'] == family_id_int]
                        print(f"🔍 {file_name}: Семейный аккаунт - FamilyID={family_id_int}, найдено: {len(filtered_data)} записей")
                        
                        # НЕ АГРЕГИРУЕМ! Отправляем как есть, т.к. уже агрегировано при создании заказа
                        # но для защиты на случай дублей делаем финальную агрегацию:
                        if not filtered_data.empty:
                            if is_main_purch:
                                filtered_data = self._aggregate_main_purch(filtered_data)
                            else:
                                filtered_data = self._aggregate_other_purch(filtered_data)
                            
                            print(f"🔍 {file_name}: После финальной агрегации - {len(filtered_data)} записей")
                            
                    except ValueError:
                        return None, f"Invalid family_id format: {family_id}"
                else:
                    print(f"⚠️ {file_name}: Нет колонки FamilyID для семейного аккаунта")
                    filtered_data = pd.DataFrame()
            
            else:
                # 3. НЕКОРРЕКТНЫЕ ПАРАМЕТРЫ
                if not family_id and not user_id:
                    return None, "Не указан family_id или user_id"
                elif family_id == "0" and not user_id:
                    return None, "Для личного аккаунта (family_id=0) требуется user_id"
                else:
                    return None, "Некорректные параметры запроса"
            
            return filtered_data, None
            
        except Exception as e:
            print(f"❌ Ошибка в get_purch_data: {str(e)}")
            import traceback
            traceback.print_exc()
            return None, str(e)
    
    def _aggregate_main_purch(self, df):
        """Агрегация MainPurch по полному ключу"""
        # Определяем колонки для агрегации
        sum_columns = ['Volume', 'VolumeGr']
        if 'TotalCost' in df.columns:
            sum_columns.append('TotalCost')
        
        # Агрегируем: суммы для числовых колонок, первое значение для остальных
        agg_dict = {}
        for col in df.columns:
            if col in sum_columns:
                agg_dict[col] = 'sum'
            elif col == 'Date':
                agg_dict[col] = 'min'
            elif col == 'ExpireDate' and col in df.columns:
                agg_dict[col] = 'min'
            else:
                agg_dict[col] = 'first'
        
        # Группируем по полному ключу
        group_columns = ['ProdID', 'UserID', 'FamilyID']
        existing_columns = [col for col in group_columns if col in df.columns]
        
        return df.groupby(existing_columns, as_index=False).agg(agg_dict)
    
    def _aggregate_other_purch(self, df):
        """Агрегация OtherPurch по полному ключу"""
        # Определяем колонки для агрегации
        sum_columns = ['Volume', 'VolumeGr']
        if 'TotalCost' in df.columns:
            sum_columns.append('TotalCost')
        
        # Агрегируем: суммы для числовых колонок, первое значение для остальных
        agg_dict = {}
        for col in df.columns:
            if col in sum_columns:
                agg_dict[col] = 'sum'
            else:
                agg_dict[col] = 'first'
        
        # Группируем по полному ключу
        base_columns = ['ProdID', 'UserID', 'FamilyID', 'StoreID', 'Date']
        existing_columns = [col for col in base_columns if col in df.columns]
        
        return df.groupby(existing_columns, as_index=False).agg(agg_dict)
    
    def save_to_ration_info(self, ration_data):
        """Сохранение записи в RationInfo.xlsx"""
        try:
            # Создаем DataFrame из данных
            ration_df = pd.DataFrame([ration_data])
            
            # Проверяем существование файла
            if os.path.exists(self.ration_info_path):
                existing_df = self.read_excel(self.ration_info_path)
                # Объединяем с существующими данными
                combined_df = pd.concat([existing_df, ration_df], ignore_index=True)
            else:
                combined_df = ration_df
            
            # Сохраняем
            self.save_excel(combined_df, self.ration_info_path)
            print(f"✅ Запись добавлена в RationInfo.xlsx")
            print(f"   Продукт: {ration_data.get('Name', 'Unknown')}")
            print(f"   UserID: {ration_data.get('UserID', 'Unknown')}")
            print(f"   Прием пищи: {ration_data.get('MealName', 'Unknown')}")
            return True
            
        except Exception as e:
            print(f"❌ Ошибка сохранения в RationInfo: {str(e)}")
            return False
    
    def get_family_ration(self, family_id):
        """Получение данных RationInfo по FamilyID"""
        try:
            if not os.path.exists(self.ration_info_path):
                return pd.DataFrame(), None
            
            df = self.read_excel(self.ration_info_path)
            
            # Проверяем наличие колонки FamilyID
            if 'FamilyID' not in df.columns:
                # Если нет FamilyID, возвращаем все данные
                return df, None
            
            family_id_int = int(family_id)
            family_data = df[df['FamilyID'] == family_id_int]
            
            return family_data, None
            
        except Exception as e:
            return None, str(e)
    
    def search_products(self, search_term):
        """Поиск товаров в базе"""
        try:
            df = self.read_excel(self.products_db_path)
            search_term_lower = search_term.lower()
            
            # Функция для получения store_id
            def get_store_id(row):
                if 'StoreID' in df.columns:
                    store_id = row.get('StoreID')
                    if pd.notna(store_id):
                        return int(store_id)
                return 1
            
            # Функция для получения названия магазина
            def get_store_name(store_id):
                store_names = {1: "Лавка", 2: "Супермаркет", 3: "Онлайн", 4: "Рынок"}
                return store_names.get(store_id, f"Магазин {store_id}")
            
            # Поиск
            results = []
            found_count = 0
            
            for _, row in df.iterrows():
                name = str(row.get('Name', '')).lower() if pd.notna(row.get('Name')) else ''
                tag = str(row.get('Tag', '')).lower() if pd.notna(row.get('Tag')) else ''
                cat = str(row.get('Cat', '')).lower() if pd.notna(row.get('Cat')) else ''
                
                matches = (search_term_lower in name or search_term_lower in tag or search_term_lower in cat)
                
                if matches:
                    found_count += 1
                    store_id = get_store_id(row)
                    store_name = get_store_name(store_id)
                    
                    # Парсим данные
                    product = {
                        'id': int(row.get('ProdID', 0)) if pd.notna(row.get('ProdID')) else found_count,
                        'prod_id': int(row.get('ProdID', 0)) if pd.notna(row.get('ProdID')) else found_count,
                        'name': str(row.get('Name', 'Без названия')).strip(),
                        'volume': float(row.get('Volume', 0)) if pd.notna(row.get('Volume')) else 0,
                        'unit': str(row.get('Unit', 'шт')).strip(),
                        'volume_gr': float(row.get('VolumeGr', 0)) if pd.notna(row.get('VolumeGr')) else 0,
                        'kcal100g': float(row.get('Kcal100g', 0)) if pd.notna(row.get('Kcal100g')) else 0,
                        'prot100g': float(row.get('Prot100g', 0)) if pd.notna(row.get('Prot100g')) else 0,
                        'fat100g': float(row.get('Fat100g', 0)) if pd.notna(row.get('Fat100g')) else 0,
                        'carb100g': float(row.get('Carb100g', 0)) if pd.notna(row.get('Carb100g')) else 0,
                        'tag': str(row.get('Tag', '')).strip(),
                        'cat': str(row.get('Cat', '')).strip(),
                        'total_cost': float(row.get('TotalCost', 0)) if pd.notna(row.get('TotalCost')) else 0,
                        'store_id': store_id,
                        'store': store_name
                    }
                    
                    results.append(product)
                    
                    if found_count >= 50:
                        break
            
            # Сортируем по релевантности
            results.sort(key=lambda x: (
                0 if search_term_lower in x['name'].lower() else 1,
                0 if search_term_lower in x['cat'].lower() else 2,
                0 if search_term_lower in x['tag'].lower() else 3
            ))
            
            return results, None
            
        except Exception as e:
            return None, str(e)
            
    # database_handler.py - обновленная функция

    def get_allpurch_by_daterange(self, start_date_str, end_date_str, user_id, family_id, user_acc_type):
        """Получение AllPurch за период дат с учетом типа аккаунта"""
        try:
            all_purch_path = os.path.join(self.orders_dir, 'AllPurch.xlsx')
        
            if not os.path.exists(all_purch_path):
                print(f"⚠️  Файл AllPurch.xlsx не найден по пути: {all_purch_path}")
                return pd.DataFrame(), "AllPurch.xlsx not found"
        
            df = self.read_excel(all_purch_path)
        
            if df.empty:
                print("ℹ️  Файл AllPurch.xlsx пуст")
                return df, None
        
            # Преобразуем даты для фильтрации
            start_date = datetime.strptime(start_date_str, "%d.%m.%Y")
            end_date = datetime.strptime(end_date_str, "%d.%m.%Y")
        
            # Убедимся, что end_date включает весь день
            end_date = end_date.replace(hour=23, minute=59, second=59)
        
            # Конвертируем в timestamp
            start_timestamp = int(start_date.timestamp())
            end_timestamp = int(end_date.timestamp())
        
            # Функция для проверки, находится ли дата в диапазоне
            def is_in_range(timestamp):
                if pd.isna(timestamp) or timestamp == '':
                    return False
                try:
                    ts = float(timestamp)
                    return start_timestamp <= ts <= end_timestamp
                except:
                    return False
        
            # ФИЛЬТРАЦИЯ ПО ДАТАМ (столбец Date)
            if 'Date' in df.columns:
                mask_date = df['Date'].apply(is_in_range)
                filtered_df = df[mask_date]
                print(f"📊 Записей в AllPurch за период {start_date_str}-{end_date_str}: {len(filtered_df)}")
            else:
                print("⚠️  В AllPurch нет колонки Date для фильтрации")
                return pd.DataFrame(), "No Date column found in AllPurch"
        
            if filtered_df.empty:
                return filtered_df, None
        
            # ФИЛЬТРАЦИЯ ПО ТИПУ АККАУНТА
            final_df = pd.DataFrame()
        
            if user_acc_type == 0:
                # ЛИЧНЫЙ АККАУНТ: фильтруем по UserID и FamilyID=0
                print(f"🔍 Фильтрация для личного аккаунта (UserID={user_id}, FamilyID=0)")
            
                has_user_id = 'UserID' in filtered_df.columns
                has_family_id = 'FamilyID' in filtered_df.columns
            
                if has_user_id and has_family_id:
                    # Приводим FamilyID к числу для сравнения
                    filtered_df['FamilyID_numeric'] = pd.to_numeric(filtered_df['FamilyID'], errors='coerce')
                    final_df = filtered_df[
                        (filtered_df['UserID'] == user_id) &
                        (filtered_df['FamilyID_numeric'] == 0)
                    ]
                    print(f"   Найдено записей: {len(final_df)}")
                elif has_user_id:
                    final_df = filtered_df[filtered_df['UserID'] == user_id]
                    print(f"   Найдено записей (без FamilyID): {len(final_df)}")
                else:
                    print("⚠️  Нет колонки UserID для фильтрации личного аккаунта")
                    return pd.DataFrame(), "No UserID column found in AllPurch"
                
            else:
                # СЕМЕЙНЫЙ АККАУНТ: фильтруем по FamilyID
                print(f"🔍 Фильтрация для семейного аккаунта (FamilyID={family_id})")
            
                if 'FamilyID' in filtered_df.columns:
                    try:
                        family_id_int = int(family_id)
                        final_df = filtered_df[filtered_df['FamilyID'] == family_id_int]
                        print(f"   Найдено записей: {len(final_df)}")
                    except ValueError:
                        return pd.DataFrame(), f"Invalid family_id format: {family_id}"
                else:
                    print("⚠️  Нет колонки FamilyID для фильтрации семейного аккаунта")
                    return pd.DataFrame(), "No FamilyID column found in AllPurch"
        
            return final_df, None
        
        except Exception as e:
            print(f"❌ Ошибка при получении AllPurch за период: {str(e)}")
            import traceback
            traceback.print_exc()
            return pd.DataFrame(), str(e)

def get_current_timestamp():
    """Получение текущего timestamp"""
    return int(datetime.now().timestamp())

def parse_date(date_str, format="%d.%m.%Y"):
    """Парсинг даты из строки"""
    try:
        return datetime.strptime(date_str, format)
    except ValueError:
        return None

def generate_expire_dates(order_date, num_dates, max_short_days_percent=25):
    """Генерация сроков годности"""
    order_dt = datetime.fromtimestamp(order_date)
    
    max_short_dates = int(num_dates * max_short_days_percent / 100)
    num_short_dates = random.randint(0, max_short_dates)
    num_long_dates = num_dates - num_short_dates
    
    expire_dates = []
    
    for _ in range(num_short_dates):
        days = random.randint(10, 19)
        expire_date = order_dt + timedelta(days=days)
        expire_dates.append(int(expire_date.timestamp()))
    
    for _ in range(num_long_dates):
        days = random.randint(20, 365)
        expire_date = order_dt + timedelta(days=days)
        expire_dates.append(int(expire_date.timestamp()))
    
    random.shuffle(expire_dates)
    return expire_dates
