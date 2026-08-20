import 'package:supabase_flutter/supabase_flutter.dart';

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
      'is_online': true,
      'is_full': false,
      'status': 'active',
    });
  }

  static Stream<List<Map<String, dynamic>>> getRides() {
    return _client
        .from('posts')
        .stream(primaryKey: ['id']);
  }

  static Stream<List<Map<String, dynamic>>> getRideRequests(String driverId) {
    return _client
        .from('ride_requests')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId);
  }

  static Stream<List<Map<String, dynamic>>> getRideHistory(String userId, {String? field}) {
    final query = _client
        .from('ride_history')
        .stream(primaryKey: ['id']);

    if (field != null) {
      return query.eq(field, userId);
    }
    return query;
  }

  static Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
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
