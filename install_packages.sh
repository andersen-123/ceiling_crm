#!/bin/bash
echo "Устанавливаем зависимости Flutter..."
flutter pub get

echo "Проверяем установленные пакеты..."
flutter pub deps

echo "Запускаем сборку..."
flutter build apk --release
