import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class LiveQuery {
  LiveQuery._();

  static Stream<List<Map<String, dynamic>>> watch({
    required String table,
    String? eq1Column,
    Object? eq1Value,
    String? eq2Column,
    Object? eq2Value,
    String? inColumn,
    List<String>? inValues,
    Duration interval = const Duration(seconds: 8),
  }) {
    late final StreamController<List<Map<String, dynamic>>> controller;
    Timer? timer;
    StreamSubscription<List<Map<String, dynamic>>>? sub;

    Future<void> pull() async {
      try {
        var query = Supabase.instance.client.from(table).select();
        if (eq1Column != null && eq1Value != null) {
          query = query.eq(eq1Column, eq1Value);
        }
        if (eq2Column != null && eq2Value != null) {
          query = query.eq(eq2Column, eq2Value);
        }
        if (inColumn != null && inValues != null && inValues.isNotEmpty) {
          query = query.inFilter(inColumn, inValues);
        }
        final rows = await query;
        if (!controller.isClosed) {
          controller.add(List<Map<String, dynamic>>.from(rows));
        }
      } catch (_) {}
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        if (inColumn != null && (inValues == null || inValues.isEmpty)) {
          controller.add(const []);
          return;
        }

        final source = Supabase.instance.client.from(table);
        Stream<List<Map<String, dynamic>>> realtime;

        if (eq1Column != null && eq2Column != null) {
          realtime = source
              .stream(primaryKey: const ['id'])
              .eq(eq1Column, eq1Value!)
              .eq(eq2Column, eq2Value!);
        } else if (eq1Column != null) {
          realtime =
              source.stream(primaryKey: const ['id']).eq(eq1Column, eq1Value!);
        } else if (inColumn != null) {
          realtime = source
              .stream(primaryKey: const ['id'])
              .inFilter(inColumn, inValues ?? const []);
        } else {
          realtime = source.stream(primaryKey: const ['id']);
        }

        sub = realtime.listen(
          (data) {
            if (!controller.isClosed) controller.add(data);
          },
          onError: (_) {},
        );

        pull();
        timer = Timer.periodic(interval, (_) => pull());
      },
      onPause: () {
        timer?.cancel();
        sub?.pause();
      },
      onResume: () {
        sub?.resume();
        timer?.cancel();
        timer = Timer.periodic(interval, (_) => pull());
        pull();
      },
      onCancel: () {
        timer?.cancel();
        sub?.cancel();
      },
    );

    return controller.stream;
  }
}
