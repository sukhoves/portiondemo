"""
Модуль для работы с изображениями продуктов
"""

import os
from flask import send_file

class ImagesHandler:
    """Обработчик изображений"""
    
    def __init__(self, images_dir):
        self.images_dir = images_dir
        print(f"🖼️ ImagesHandler инициализирован: {images_dir}")
    
    def get_image_path(self, prod_id):
        """Получение пути к изображению по ProdID"""
        extensions = ['.jpg', '.jpeg', '.png', '.webp']
        
        for ext in extensions:
            test_path = os.path.join(self.images_dir, f"{prod_id}{ext}")
            if os.path.exists(test_path):
                return test_path
        
        return None
    
    def serve_image(self, prod_id):
        """Отправка изображения клиенту"""
        image_path = self.get_image_path(prod_id)
        
        if image_path:
            print(f"✅ Отправляем изображение: {image_path}")
            return send_file(image_path, mimetype='image/jpeg')
        else:
            print(f"❌ Изображение не найдено для ProdID: {prod_id}")
            return None

# Глобальный обработчик изображений
_image_handler = None

def init_images(images_dir):
    """Инициализация обработчика изображений"""
    global _image_handler
    _image_handler = ImagesHandler(images_dir)
    return _image_handler

def get_image_handler():
    """Получение обработчика изображений"""
    return _image_handler

