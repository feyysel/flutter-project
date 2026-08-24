import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';
import 'trip_service.dart';

class PassengerLocationSharer {
  PassengerLocationSharer._();

  static Timer? _timer;
  static bool _busy = false;

  static void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    _tick();
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id ?? '';
      if (uid.isEmpty) return;

      final myRequests = await client
          .from('ride_requests')
          .select('id, ride_id, status')
          .eq('passenger_id', uid)
          .eq('status', 'confirmed');

      if (myRequests.isEmpty) return;

      final rideIds =
          myRequests.map((r) => r['ride_id'].toString()).toSet().toList();
      if (rideIds.isEmpty) return;

      final posts = await client
          .from('posts')
          .select('id, departure_at, time')
          .inFilter('id', rideIds);

      final eligible = posts.any((post) {
        final departure = TripService.resolveDeparture(post);
        return TripService.trackingOpen(departure);
      });

      if (!eligible) return;

      final position = await LocationService.getCurrentPosition();
      if (position == null) return;

      await client.from('profiles').update({
        'lat': position.latitude,
        'lng': position.longitude,
      }).eq('id', uid);
    } catch (_) {
    } finally {
      _busy = false;
    }
  }
}
