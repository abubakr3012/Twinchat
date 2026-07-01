import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twinchat/presentation/widgets/avatar_widget.dart';
import 'package:twinchat/presentation/widgets/empty_state.dart';
import 'package:twinchat/presentation/widgets/loading_view.dart';
import 'package:twinchat/presentation/widgets/message_bubble.dart';
import 'package:twinchat/presentation/widgets/message_status_icon.dart';

void main() {
  group('UserAvatar', () {
    testWidgets('показывает инициалы когда url == null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: 'Alice', size: 48),
          ),
        ),
      );
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('для двойного имени показывает 2 буквы', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(name: 'Anna Petrova', size: 48),
          ),
        ),
      );
      expect(find.text('AP'), findsOneWidget);
    });
  });

  group('MessageBubble', () {
    testWidgets('own vs other выравнивает влево/вправо', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MessageBubble(text: 'mine', isMine: true),
                MessageBubble(text: 'other', isMine: false),
              ],
            ),
          ),
        ),
      );
      expect(find.text('mine'), findsOneWidget);
      expect(find.text('other'), findsOneWidget);
    });

    testWidgets('показывает иконку замка в encrypted режиме', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageBubble(text: 'cipher', isMine: false, encrypted: true),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });
  });

  group('MessageStatusIcon', () {
    testWidgets('seen → done_all с primary цветом', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MessageStatusIcon(status: 'seen')),
        ),
      );
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('sent → done', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MessageStatusIcon(status: 'sent')),
        ),
      );
      expect(find.byIcon(Icons.done), findsOneWidget);
    });

    testWidgets('failed → error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MessageStatusIcon(status: 'failed')),
        ),
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('LoadingView / ErrorView / EmptyState', () {
    testWidgets('LoadingView показывает спиннер', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingView(message: 'Подождите')),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Подождите'), findsOneWidget);
    });

    testWidgets('ErrorView с retry-кнопкой', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              message: 'Сеть упала',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Сеть упала'), findsOneWidget);
      await tester.tap(find.text('Повторить'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('EmptyState с action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Нет чатов',
              subtitle: 'Создайте первый чат',
              action: FilledButton(onPressed: () {}, child: const Text('Создать')),
            ),
          ),
        ),
      );
      expect(find.text('Нет чатов'), findsOneWidget);
      expect(find.text('Создать'), findsOneWidget);
    });
  });
}