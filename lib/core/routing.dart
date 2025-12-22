import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ceiling_crm/screens/home_screen.dart';
import 'package:ceiling_crm/screens/project_detail_screen.dart';
import 'package:ceiling_crm/screens/estimate_edit_screen.dart';
import 'package:ceiling_crm/models/estimate.dart';

class AppRouter {
  static final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/project/:id',
        builder: (context, state) {
          // Здесь нужно будет добавить логику загрузки проекта
          return const Placeholder();
        },
      ),
      GoRoute(
        path: '/estimate/:id',
        builder: (context, state) {
          final estimateId = int.tryParse(state.pathParameters['id'] ?? '');
          if (estimateId == null) {
            return const Scaffold(body: Center(child: Text('Ошибка: неверный ID')));
          }
          // Здесь будет загрузка сметы из базы
          return EstimateEditScreen(
            estimate: Estimate(
              title: 'Смета #$estimateId',
              items: [],
              createdAt: DateTime.now(),
            ),
            projectId: estimateId,
          );
        },
      ),
    ],
  );

  static GoRouter get router => _router;
}
