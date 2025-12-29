#!/bin/bash

echo "🔍 Проверка проекта перед сборкой..."

# 1. Проверка структуры иконок
echo "1. Проверка иконок..."
if [ ! -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
    echo "⚠️  Отсутствует: ic_launcher.png в mipmap-hdpi"
    # Создаем простую иконку
    mkdir -p android/app/src/main/res/mipmap-hdpi
    echo "✅ Создана папка для иконок"
fi

if [ ! -f "android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png" ]; then
    echo "⚠️  Отсутствует: ic_launcher_round.png"
fi

# 2. Проверка AndroidManifest.xml
echo "2. Проверка AndroidManifest.xml..."
if grep -q "ic_launcher_round" android/app/src/main/AndroidManifest.xml; then
    echo "⚠️  Найдена ссылка на ic_launcher_round"
    # Автоматически исправляем
    sed -i 's|android:roundIcon="@mipmap/ic_launcher_round"||g' android/app/src/main/AndroidManifest.xml
    echo "✅ AndroidManifest.xml исправлен"
fi

# 3. Проверка зависимостей
echo "3. Проверка зависимостей..."
flutter pub get

# 4. Проверка синтаксиса Dart
echo "4. Проверка синтаксиса Dart..."
flutter analyze

echo "✅ Проверка завершена!"
echo "🚀 Запускаем сборку..."
