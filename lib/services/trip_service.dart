import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class TripService {
  TripService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static const List<String> paidStatuses = [
    'confirmed',
    'picked_up',
    'dropped_off',
  ];

  // ------------------------------------------------------------------
  // Time helpers
  // ------------------------------------------------------------------

  static DateTime? resolveDeparture(Map<String, dynamic>? post) {
    if (post == null) return null;
    final iso = post['departure_at']?.toString();
    if (iso != null && iso.isNotEmpty) {
      final parsed = DateTime.tryParse(iso);
      if (parsed != null) return parsed.toLocal();
    }
    return _parseLegacyTime(post['time']?.toString());
  }

  static DateTime? _parseLegacyTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso.toLocal();

    final parts = raw.split(RegExp(r'[•·|]'));
    if (parts.length < 2) return null;

    final datePart = parts[0];
    final timePart = parts[parts.length - 1];

    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final monthMatch =
        RegExp(r'([A-Za-z]{3})').allMatches(datePart).toList();
    final dayMatch = RegExp(r'(\d{1,2})').firstMatch(datePart);
    final timeMatch = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
      caseSensitive: false,
    ).firstMatch(timePart);

    if (monthMatch.isEmpty || dayMatch == null || timeMatch == null) {
      return null;
    }

    final monthWord = monthMatch.last.group(1)?.toLowerCase();
    final month = months[monthWord];
    final day = int.tryParse(dayMatch.group(1)!);
    var hour = int.tryParse(timeMatch.group(1)!) ?? 0;
    final minute = int.tryParse(timeMatch.group(2)!) ?? 0;
    final period = timeMatch.group(3)?.toUpperCase();

    if (month == null || day == null) return null;
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    final now = DateTime.now();
    var candidate = DateTime(now.year, month, day, hour, minute);
    if (candidate.isBefore(now.subtract(const Duration(days: 2)))) {
      candidate = DateTime(now.year + 1, month, day, hour, minute);
    }
    return candidate;
  }

  static bool trackingOpen(DateTime? departure) {
    if (departure == null) return false;
    return DateTime.now().isAfter(departure.subtract(const Duration(hours: 24)));
  }

  static String countdownText(DateTime? departure) {
    if (departure == null) return "Departure time not set";
    final diff = departure.difference(DateTime.now());
    if (diff.isNegative) return "Departure time reached";
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    if (days > 0) return "$days d $hours h until departure";
    if (hours > 0) return "$hours h $minutes m until departure";
    return "$minutes m until departure";
  }

  static bool isPaidStatus(String? status) =>
      status != null && paidStatuses.contains(status);

  // ------------------------------------------------------------------
  // Driver payout details
  // ------------------------------------------------------------------

  static Future<Map<String, dynamic>?> getProfile(String userId) async {
    if (userId.isEmpty) return null;
    return _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  static bool hasCompleteBankDetails(Map<String, dynamic>? profile) {
    if (profile == null) return false;
    final bank = (profile['bank_name'] ?? '').toString().trim();
    final holder = (profile['bank_account_holder'] ?? '').toString().trim();
    final account = (profile['bank_account_number'] ?? '').toString().trim();
    return bank.isNotEmpty && holder.isNotEmpty && account.isNotEmpty;
  }

  static Future<void> saveBankDetails({
    required String userId,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
  }) async {
    await _client.from('profiles').update({
      'bank_name': bankName.trim(),
      'bank_account_holder': accountHolder.trim(),
      'bank_account_number': accountNumber.trim(),
    }).eq('id', userId);
  }

  static Future<void> acceptRequest(Map<String, dynamic> request) async {
    final driverId = request['driver_id'].toString();
    final profile = await getProfile(driverId);

    await updateRideRequest(request['id'].toString(), {
      'status': 'accepted',
      'pay_bank_name': (profile?['bank_name'] ?? '').toString(),
      'pay_bank_holder': (profile?['bank_account_holder'] ?? '').toString(),
      'pay_account_number': (profile?['bank_account_number'] ?? '').toString(),
    });

    await addNotification(
      userId: request['passenger_id'].toString(),
      title: "Ride Accepted",
      body:
          "${request['driver_name']} accepted your ride. "
          "Send ${request['price']} ETB to ${(profile?['bank_name'] ?? 'the driver bank account')} — "
          "${(profile?['bank_account_holder'] ?? '')}, Account No: "
          "${(profile?['bank_account_number'] ?? '')}. Then upload your payment receipt in Activity.",
    );
  }

  static Future<void> declineRequest(Map<String, dynamic> request) async {
    await updateRideRequest(request['id'].toString(), {'status': 'declined'});
    await addNotification(
      userId: request['passenger_id'].toString(),
      title: "Ride Declined",
      body:
          "${request['driver_name'] ?? 'The driver'} can't take this ride. Try booking another one.",
    );
  }

  // ------------------------------------------------------------------
  // Passenger payment submission
  // ------------------------------------------------------------------

  static Future<void> submitPayment({
    required Map<String, dynamic> request,
    required File receiptFile,
    String? transactionNumber,
  }) async {
    final passengerId = request['passenger_id'].toString();
    final requestId = request['id'].toString();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = receiptFile.path.toLowerCase().endsWith('.png')
        ? 'png'
        : 'jpeg';
    final path = '$passengerId/${requestId}_$timestamp.$ext';

    await _client.storage.from('payment-receipts').upload(
          path,
          receiptFile,
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );

    final publicUrl =
        _client.storage.from('payment-receipts').getPublicUrl(path);

    await updateRideRequest(requestId, {
      'status': 'payment_submitted',
      'payment_receipt_url': publicUrl,
      'payment_txn': (transactionNumber ?? '').trim(),
      'payment_submitted_at': DateTime.now().toUtc().toIso8601String(),
    });

    await addNotification(
      userId: request['driver_id'].toString(),
      title: "Payment Receipt Received",
      body:
          "${request['passenger_name']} sent a payment receipt of "
          "${request['price']} ETB for ${request['from']} → ${request['to']}. "
          "Review and verify it in your requests.",
    );
  }

  // ------------------------------------------------------------------
  // Driver verifies payment -> seat reserved + ticket generated
  // ------------------------------------------------------------------

  static Future<bool> verifyPayment(Map<String, dynamic> request) async {
    final requestId = request['id'].toString();
    final rideId = request['ride_id'].toString();

    final current = await _client
        .from('ride_requests')
        .select()
        .eq('id', requestId)
        .maybeSingle();
    if (current == null) return false;
    if (current['status'] != 'payment_submitted') return false;

    final post = await _client
        .from('posts')
        .select()
        .eq('id', rideId)
        .maybeSingle();

    final available = (post?['available_seats'] is num)
        ? (post!['available_seats'] as num).toInt()
        : int.tryParse('${post?['available_seats'] ?? 0}') ?? 0;

    if (available <= 0) return false;

    final remaining = available - 1;
    final seatUpdate = await _client.from('posts').update({
      'available_seats': remaining,
      'is_full': remaining <= 0,
    }).eq('id', rideId).select('id');

    if (seatUpdate.isEmpty) {
      throw Exception(
        'Database blocked the seat reservation (RLS policy). '
        'Check posts update policies in supabase/ride_flow_migration.sql.',
      );
    }

    final ticketCode = _generateTicketCode();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await updateRideRequest(requestId, {
      'status': 'confirmed',
      'ticket_code': ticketCode,
      'payment_verified_at': nowIso,
    });

    await addNotification(
      userId: request['passenger_id'].toString(),
      title: "Payment Accepted — Seat Reserved",
      body:
          "${request['driver_name']} verified your payment of "
          "${request['price']} ETB. Your seat is reserved and ticket "
          "$ticketCode is ready in Activity. Keep it as evidence.",
    );

    await addNotification(
      userId: request['driver_id'].toString(),
      title: "Payment Verified",
      body:
          "You accepted ${request['passenger_name']}'s payment. Ticket "
          "$ticketCode generated. Live tracking unlocks 1 day before departure.",
    );

    return true;
  }

  static String _generateTicketCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final suffix =
        List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    final stamp =
        DateTime.now().millisecondsSinceEpoch.remainder(1000000).toString().padLeft(6, '0');
    return 'DO-$stamp-$suffix';
  }

  // ------------------------------------------------------------------
  // Pickup / dropoff / start / finish
  // ------------------------------------------------------------------

  static Future<void> markPicked(Map<String, dynamic> request) async {
    await updateRideRequest(request['id'].toString(), {
      'status': 'picked_up',
      'picked_at': DateTime.now().toUtc().toIso8601String(),
    });
    await addNotification(
      userId: request['passenger_id'].toString(),
      title: "You've Been Picked Up",
      body:
          "${request['driver_name']} picked you up. Live tracking between you "
          "and the driver has stopped. Your route to ${request['to']} is now on your map.",
    );
  }

  static Future<void> markDropped(Map<String, dynamic> request) async {
    await updateRideRequest(request['id'].toString(), {
      'status': 'dropped_off',
      'dropped_at': DateTime.now().toUtc().toIso8601String(),
    });
    await addNotification(
      userId: request['passenger_id'].toString(),
      title: "Trip Completed Successfully",
      body:
          "You have arrived at ${request['to']}. Thanks for riding with DriveOn! "
          "Your ticket remains valid as proof of travel.",
    );
  }

  static Future<void> startTrip({
    required Map<String, dynamic> post,
    required List<Map<String, dynamic>> passengers,
  }) async {
    final started = await _client.from('posts').update({
      'trip_status': 'in_progress',
      'trip_started_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', post['id'].toString()).select('id');

    if (started.isEmpty) {
      throw Exception(
        'Database blocked Start Trip (RLS policy on posts).',
      );
    }

    for (final p in passengers) {
      await addNotification(
        userId: p['passenger_id'].toString(),
        title: "Trip Started",
        body:
            "${post['driver_name']} started the trip from ${p['from']} to ${p['to']}. Follow your route in Track.",
      );
    }
  }

  static Future<void> finishTrip({
    required Map<String, dynamic> post,
    required List<Map<String, dynamic>> passengers,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();

    for (final p in passengers) {
      await _client.from('ride_history').insert({
        'ride_id': post['id'],
        'driver_id': post['driver_id'],
        'driver_name': post['driver_name'],
        'passenger_id': p['passenger_id'],
        'passenger_name': p['passenger_name'],
        'passenger_phone': p['passenger_phone'] ?? '',
        'from': p['from'],
        'to': p['to'],
        'price': p['price'],
        'time': post['time'] ?? '',
        'ticket_code': p['ticket_code'] ?? '',
        'status': 'completed',
        'created_at': nowIso,
      });
    }

    final finished = await _client.from('posts').update({
      'trip_status': 'completed',
      'status': 'completed',
      'is_online': false,
      'trip_finished_at': nowIso,
    }).eq('id', post['id'].toString()).select('id');

    if (finished.isEmpty) {
      throw Exception(
        'Database blocked Finish Trip (RLS policy on posts).',
      );
    }

    for (final p in passengers) {
      await updateRideRequest(p['id'].toString(), {'status': 'completed'});
    }

    for (final p in passengers) {
      await addNotification(
        userId: p['passenger_id'].toString(),
        title: "Trip Finished",
        body:
            "Your trip ${p['from']} → ${p['to']} is complete. Rate your driver and keep your ticket.",
      );
    }

    await addNotification(
      userId: post['driver_id'].toString(),
      title: "Trip Completed Successfully",
      body:
          "All passengers dropped. You earned from ${passengers.length} "
          "passenger${passengers.length == 1 ? '' : 's'} on "
          "${post['from']} → ${post['to']}. Well done!",
    );
  }

  // ------------------------------------------------------------------
  // Low-level helpers
  // ------------------------------------------------------------------

  static Future<void> updateRideRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final updated = await _client
        .from('ride_requests')
        .update(data)
        .eq('id', requestId)
        .select('id');

    if (updated.isEmpty) {
      throw Exception(
        'Database blocked this update (RLS policy). '
        'Run the latest supabase/ride_flow_migration.sql.',
      );
    }
  }

  static Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    if (userId.isEmpty) return;
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }
}
