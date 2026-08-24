import 'package:supabase_flutter/supabase_flutter.dart';
import 'live_query.dart';

class RideService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> addRide({
    required String from,
    required String to,
    required String time,
    required String price,
    required String driverId,
    required String driverName,
    required String vehicleModel,
    required int seats,
    DateTime? departureAt,
    String? pickupLocation,
    String? dropLocation,
  }) async {
    await _client.from('posts').insert({
      'driver_id': driverId,
      'driver_name': driverName,
      'from': from,
      'to': to,
      'time': time,
      'price': price,
      'seats': seats.toString(),
      'total_seats': seats,
      'available_seats': seats,
      'vehicle_model': vehicleModel,
      if (departureAt != null) 'departure_at': departureAt.toUtc().toIso8601String(),
      if (pickupLocation != null) 'pickup_location': pickupLocation,
      if (dropLocation != null) 'drop_location': dropLocation,
      'is_online': true,
      'is_full': false,
      'status': 'active',
      'trip_status': 'scheduled',
    });
  }

  static Stream<List<Map<String, dynamic>>> getRides() {
    return LiveQuery.watch(table: 'posts');
  }

  static Stream<List<Map<String, dynamic>>> getRideRequests(String driverId) {
    return LiveQuery.watch(
      table: 'ride_requests',
      eq1Column: 'driver_id',
      eq1Value: driverId,
    );
  }

  static Stream<List<Map<String, dynamic>>> getPassengerRequests(
    String passengerId,
  ) {
    return LiveQuery.watch(
      table: 'ride_requests',
      eq1Column: 'passenger_id',
      eq1Value: passengerId,
    );
  }

  static Stream<List<Map<String, dynamic>>> getDriverPosts(String driverId) {
    return LiveQuery.watch(
      table: 'posts',
      eq1Column: 'driver_id',
      eq1Value: driverId,
    );
  }

  static Stream<List<Map<String, dynamic>>> getRideHistory(String userId,
      {String? field}) {
    return LiveQuery.watch(
      table: 'ride_history',
      eq1Column: field,
      eq1Value: field != null ? userId : null,
    );
  }

  static Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return LiveQuery.watch(
      table: 'notifications',
      eq1Column: 'user_id',
      eq1Value: userId,
      interval: const Duration(seconds: 6),
    );
  }

  static Future<void> addNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
    });
  }

  static Future<void> updateRideRequest(String requestId, Map<String, dynamic> data) async {
    await _client.from('ride_requests').update(data).eq('id', requestId);
  }

  static Future<void> deleteRideRequest(String requestId) async {
    await _client.from('ride_requests').delete().eq('id', requestId);
  }

  static Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _client.from('posts').update(data).eq('id', postId);
  }

  static Future<void> deletePost(String postId) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  static Future<void> addRideRequest(Map<String, dynamic> data) async {
    await _client.from('ride_requests').insert(data);
  }

  static Future<void> addRideHistory(Map<String, dynamic> data) async {
    await _client.from('ride_history').insert(data);
  }

  static Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', uid);
  }
}
