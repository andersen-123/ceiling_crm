import 'package:ceiling_crm/models/quote.dart';
import 'package:ceiling_crm/models/line_item.dart';
import 'package:ceiling_crm/repositories/quote_repository.dart';

class TestDataGenerator {
  static final QuoteRepository _repo = QuoteRepository();

  static Future<void> generateTestData() async {
    try {
      print('Генерация тестовых данных...');
      
      // Генерируем 5 тестовых КП
      for (int i = 1; i <= 5; i++) {
        final quoteId = await _repo.createQuote(
          clientName: 'Тестовый Клиент $i',
          clientPhone: '+7 (999) 111-22-${i.toString().padLeft(2, '0')}',
          objectAddress: 'г. Москва, ул. Тестовая, д. $i',
          notes: i.isEven ? 'Тестовое примечание для КП $i' : null,
          vatRate: i == 3 ? 0.0 : 20.0, // Третий КП без НДС
        );
        
        print('Создан КП №$quoteId');
        
        // Добавляем позиции
        await _repo.addLineItem(
          quoteId: quoteId,
          name: 'Монтаж натяжного потолка',
          description: 'Монтаж потолка стандартной сложности',
          quantity: 15.5,
          unit: 'м²',
          price: 1200.0,
        );
        
        await _repo.addLineItem(
          quoteId: quoteId,
          name: 'Точечный светильник',
          description: 'Установка светильника с подготовкой отверстия',
          quantity: 6.0,
          unit: 'шт.',
          price: 800.0,
        );
        
        if (i > 2) {
          await _repo.addLineItem(
            quoteId: quoteId,
            name: 'Люстра',
            description: 'Монтаж люстры с креплением',
            quantity: 1.0,
            unit: 'шт.',
            price: 2500.0,
          );
        }
        
        // Устанавливаем разные статусы
        final statuses = ['draft', 'sent', 'accepted', 'rejected'];
        final status = statuses[(i - 1) % statuses.length];
        await _repo.updateQuoteStatus(quoteId, status);
      }
      
      print('✅ Тестовые данные успешно созданы!');
      
    } catch (e) {
      print('❌ Ошибка генерации тестовых данных: $e');
    }
  }

  static Future<void> clearTestData() async {
    try {
      print('Очистка тестовых данных...');
      final quotes = await _repo.getAllQuotes();
      
      for (final quote in quotes) {
        if (quote.clientName.contains('Тестовый Клиент')) {
          await _repo.deleteQuote(quote.id!);
        }
      }
      
      print('✅ Тестовые данные очищены!');
    } catch (e) {
      print('❌ Ошибка очистки тестовых данных: $e');
    }
  }

  static Future<Map<String, dynamic>> runTests() async {
    final results = <String, bool>{};
    
    try {
      print('=== ЗАПУСК ТЕСТОВ Ceiling CRM ===');
      
      // Тест 1: Создание КП
      print('\n1. Тест создания КП...');
      final quoteId = await _repo.createQuote(
        clientName: 'Тест Создания',
        clientPhone: '+7 (999) 999-99-99',
        objectAddress: 'г. Тест, ул. Тестовая, д. 1',
      );
      results['create_quote'] = quoteId > 0;
      print('   Результат: ${results['create_quote'] ? '✅ УСПЕХ' : '❌ ОШИБКА'}');
      
      // Тест 2: Добавление позиций
      print('\n2. Тест добавления позиций...');
      final itemId = await _repo.addLineItem(
        quoteId: quoteId,
        name: 'Тестовая позиция',
        quantity: 2.0,
        unit: 'шт.',
        price: 1000.0,
      );
      results['add_line_item'] = itemId > 0;
      print('   Результат: ${results['add_line_item'] ? '✅ УСПЕХ' : '❌ ОШИБКА'}');
      
      // Тест 3: Получение КП
      print('\n3. Тест получения КП...');
      final quote = await _repo.getQuote(quoteId);
      results['get_quote'] = quote != null;
      print('   Результат: ${results['get_quote'] ? '✅ УСПЕХ' : '❌ ОШИБКА'}');
      
      // Тест 4: Получение позиций
      print('\n4. Тест получения позиций...');
      final items = await _repo.getLineItems(quoteId);
      results['get_line_items'] = items.isNotEmpty;
      print('   Результат: ${results['get_line_items'] ? '✅ УСПЕХ' : '❌ ОШИБКА'}');
      
      // Тест 5: Расчет суммы
      print('\n5. Тест расчета суммы...');
      final total = await _repo.calculateQuoteTotal(quoteId);
      results['calculate_total'] = total == 2000.0;
      print('   Результат: ${results['calculate_total'] ? '✅ УСПЕХ' : '❌ ОШИБКА'} (сумма: $total)');
      
      // Тест 6: Обновление статуса
      print('\n6. Тест обновления статуса...');
      await _repo.updateQuoteStatus(quoteId, 'sent');
      final updatedQuote = await _repo.getQuote(quoteId);
      results['update_status'] = updatedQuote?.status == 'sent';
      print('   Результат: ${results['update_status'] ? '✅ УСПЕХ' : '❌ ОШИБКА'}');
      
      // Тест 7: Поиск КП
      print('\n7. Тест поиска КП...');
      final searchResults = await _repo.searchQuotes('Тест');
      results['search_quotes'] = searchResults.isNotEmpty;
      print('   Результат: ${results['search_quotes'] ? '✅ УСПЕХ' : '❌ ОШИБКА'} (найдено: ${searchResults.length})');
      
      // Тест 8: Удаление КП
      print('\n8. Тест удаления КП...');
      await _repo.deleteQuote(quoteId);
      final deletedQuote = await _repo.getQuote(quoteId);
      results['delete_quote'] = deletedQuote == null;
      print('   Результат: ${results['delete_quote'] ? '✅ УСПЕХ' : '❌ ОШИБКА'}');
      
      // Итоги
      print('\n=== ИТОГИ ТЕСТИРОВАНИЯ ===');
      final passedTests = results.values.where((result) => result).length;
      final totalTests = results.length;
      
      print('Пройдено тестов: $passedTests/$totalTests');
      print('Общий результат: ${passedTests == totalTests ? '✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ' : '❌ ЕСТЬ ОШИБКИ'}');
      
      if (passedTests < totalTests) {
        print('\nНеудачные тесты:');
        results.forEach((key, value) {
          if (!value) print('  - $key');
        });
      }
      
      return {
        'passed': passedTests,
        'total': totalTests,
        'all_passed': passedTests == totalTests,
        'results': results,
      };
      
    } catch (e) {
      print('❌ КРИТИЧЕСКАЯ ОШИБКА В ТЕСТАХ: $e');
      return {
        'passed': 0,
        'total': 8,
        'all_passed': false,
        'error': e.toString(),
      };
    }
  }
}
