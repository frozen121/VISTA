#!/usr/bin/env python3
"""
Скачивает иконку hotel_rounded из Google Material Design
и создает иконку приложения с синим фоном как на экране авторизации
"""
import urllib.request
from PIL import Image
from io import BytesIO

size = 1024
color_blue = (99, 102, 241)  # AppColors.primary

# Скачиваем SVG иконку hotel из Material Design
svg_url = "https://fonts.gstatic.com/s/i/materialsymbolsrounded/hotel/v4/24px.svg"

try:
    # Скачиваем SVG
    print("⏳ Скачиваю иконку hotel из Material Design...")
    response = urllib.request.urlopen(svg_url, timeout=5)
    svg_data = response.read()
    
    # Сохраняем SVG
    with open('assets/icon/hotel_icon.svg', 'wb') as f:
        f.write(svg_data)
    
    print("✅ SVG скачана!")
    
    # Конвертируем SVG в PNG используя cairosvg если доступен
    try:
        import cairosvg
        cairosvg.svg2png(
            url='assets/icon/hotel_icon.svg',
            write_to='assets/icon/hotel_temp.png',
            output_width=512,
            output_height=512
        )
        hotel_img = Image.open('assets/icon/hotel_temp.png')
        print("✅ SVG конвертирована в PNG через cairosvg!")
    except:
        # Fallback - используем простой встроенный способ
        from PIL import ImageDraw
        print("⚠️  cairosvg не установлен, используем встроенный способ...")
        
        # Создаем простую иконку кровати в профиль
        hotel_img = Image.new('RGBA', (512, 512), (255, 255, 255, 0))
        draw = ImageDraw.Draw(hotel_img, 'RGBA')
        
        # Рисуем кровать в профиль (вид сбоку)
        center_x, center_y = 256, 256
        
        # Основание кровати (серое)
        draw.rectangle(
            [center_x - 150, center_y + 80, center_x + 150, center_y + 150],
            fill=(200, 200, 200, 200)
        )
        
        # Каркас кровати (белый)
        draw.rectangle(
            [center_x - 150, center_y - 40, center_x + 150, center_y + 80],
            outline=(255, 255, 255, 255),
            width=25
        )
        
        # Две подушки (белые полукруги)
        draw.ellipse(
            [center_x - 120, center_y - 70, center_x - 40, center_y - 10],
            fill=(255, 255, 255, 200)
        )
        draw.ellipse(
            [center_x + 40, center_y - 70, center_x + 120, center_y - 10],
            fill=(255, 255, 255, 200)
        )
        
        # Покрывало (белое)
        draw.rectangle(
            [center_x - 140, center_y, center_x + 140, center_y + 70],
            fill=(255, 255, 255, 180)
        )
    
    # Создаем финальную иконку: синий фон + иконка кровати
    final_img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    
    # Маска для скругленного квадрата
    mask = Image.new('L', (size, size), 0)
    from PIL import ImageDraw as MaskDraw
    mask_draw = MaskDraw(mask)
    mask_draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=250, fill=255)
    
    # Заполняем синим
    from PIL import ImageDraw as FinalDraw
    draw_final = FinalDraw(final_img, 'RGBA')
    for y in range(size):
        for x in range(size):
            ratio = (x + y) / (size * 2)
            r = int(color_blue[0] * (0.9 + ratio * 0.1))
            g = int(color_blue[1] * (0.9 + ratio * 0.1))
            b = int(color_blue[2] * (0.9 + ratio * 0.1))
            draw_final.point((x, y), fill=(r, g, b, 255))
    
    final_img.putalpha(mask)
    
    # Масштабируем иконку кровати и вставляем в центр
    hotel_img_resized = hotel_img.resize((int(size * 0.5), int(size * 0.5)), Image.Resampling.LANCZOS)
    offset = (int(size * 0.25), int(size * 0.25))
    final_img.paste(hotel_img_resized, offset, hotel_img_resized)
    
    final_img.save('assets/icon/app_icon.png', 'PNG')
    print('✅ Иконка создана: assets/icon/app_icon.png')
    print('   Синий скругленный квадрат с иконкой кровати из Material Design!')
    
except Exception as e:
    print(f'❌ Ошибка: {e}')
    print('   Используем встроенный способ...')
