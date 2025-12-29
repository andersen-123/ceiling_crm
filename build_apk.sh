#!/bin/bash

echo "🚀 ЗАПУСК ФИНАЛЬНОЙ СБОРКИ APK"
echo "=============================="

# 1. Очистка
echo "1. Очистка проекта..."
flutter clean

# 2. Установка зависимостей
echo "2. Установка зависимостей..."
flutter pub get

# 3. Проверка
echo "3. Проверка проекта..."
flutter analyze

# 4. Сборка APK
echo "4. Запуск сборки APK..."
echo "📱 Это может занять несколько минут..."
flutter build apk --release

# 5. Проверка результата
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo "🎉🎉🎉 УСПЕХ! APK собран!"
    echo "📁 Файл: build/app/outputs/flutter-apk/app-release.apk"
    echo "📦 Размер: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
else
    echo "❌ Ошибка: APK не найден"
    exit 1
fi
