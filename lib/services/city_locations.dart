import 'package:latlong2/latlong.dart';

class CityLocations {
  CityLocations._();

  static const Map<String, LatLng> _cities = {
    'addis ababa': LatLng(9.0054, 38.7636),
    'addis abeba': LatLng(9.0054, 38.7636),
    'finfinne': LatLng(9.0054, 38.7636),
    'adama': LatLng(8.5424, 39.2706),
    'nazret': LatLng(8.5424, 39.2706),
    'mojo': LatLng(8.5833, 39.1167),
    'debre zeit': LatLng(8.9833, 39.2167),
    'bishoftu': LatLng(8.9833, 39.2167),
    'dire dawa': LatLng(9.5931, 41.8661),
    'dirre dhawaa': LatLng(9.5931, 41.8661),
    'harar': LatLng(9.3129, 42.1183),
    'harari': LatLng(9.3129, 42.1183),
    'jijiga': LatLng(9.35, 42.80),
    'mekelle': LatLng(13.4967, 39.4753),
    'mekele': LatLng(13.4967, 39.4753),
    'adigrat': LatLng(14.2772, 39.4561),
    'axum': LatLng(14.1211, 38.7233),
    'aksum': LatLng(14.1211, 38.7233),
    'shire': LatLng(14.10, 38.34),
    'wukro': LatLng(13.7833, 39.60),
    'alamata': LatLng(12.4167, 39.55),
    'bahir dar': LatLng(11.5936, 37.3908),
    'bahirdar': LatLng(11.5936, 37.3908),
    'gondar': LatLng(12.60, 37.4667),
    'lalibela': LatLng(12.0333, 39.0417),
    'werota': LatLng(11.9167, 37.7167),
    'woreta': LatLng(11.9167, 37.7167),
    'addis zemen': LatLng(12.1167, 37.7833),
    'debre markos': LatLng(10.35, 37.7333),
    'debre birhan': LatLng(9.6833, 39.5333),
    'debreberhan': LatLng(9.6833, 39.5333),
    'fiche': LatLng(9.80, 38.7333),
    'selale': LatLng(9.80, 38.7333),
    'dessie': LatLng(11.1333, 39.6333),
    'dese': LatLng(11.1333, 39.6333),
    'kombolcha': LatLng(11.0833, 39.7333),
    'combolcha': LatLng(11.0833, 39.7333),
    'bati': LatLng(11.1833, 40.0167),
    'kemissie': LatLng(10.7167, 39.8667),
    'kembolcha': LatLng(10.7167, 39.8667),
    'woldia': LatLng(11.8333, 39.60),
    'weldiya': LatLng(11.8333, 39.60),
    'semera': LatLng(11.7935, 41.0058),
    'hawassa': LatLng(7.0621, 38.4764),
    'hawasa': LatLng(7.0621, 38.4764),
    'awassa': LatLng(7.0621, 38.4764),
    'shashamane': LatLng(7.20, 38.5833),
    'shashemene': LatLng(7.20, 38.5833),
    'ziway': LatLng(8.00, 38.7667),
    'butajira': LatLng(8.1167, 38.3667),
    'hosaina': LatLng(7.60, 37.85),
    'hosaena': LatLng(7.60, 37.85),
    'wolaita sodo': LatLng(6.8333, 37.75),
    'sodo': LatLng(6.8333, 37.75),
    'arba minch': LatLng(6.0333, 37.55),
    'arbaminch': LatLng(6.0333, 37.55),
    'dilla': LatLng(6.4167, 38.10),
    'yirga alem': LatLng(6.7667, 38.35),
    'jimma': LatLng(7.6739, 36.8344),
    'jima': LatLng(7.6739, 36.8344),
    'agaro': LatLng(7.85, 36.5833),
    'bedele': LatLng(8.45, 36.4667),
    'nekemte': LatLng(9.0875, 36.5503),
    'ambo': LatLng(8.9833, 37.85),
    'waliso': LatLng(8.5333, 37.9667),
    'woliso': LatLng(8.5333, 37.9667),
    'gedo': LatLng(9.0333, 38.4833),
    'metu': LatLng(8.30, 35.5833),
    'gore': LatLng(8.15, 35.5333),
    'bonga': LatLng(7.2833, 36.2333),
    'mizan teferi': LatLng(7.35, 36.65),
    'tepi': LatLng(7.4333, 36.6833),
    'assosa': LatLng(10.0667, 34.5333),
    'gambela': LatLng(8.25, 34.5833),
    'gambella': LatLng(8.25, 34.5833),
    'goba': LatLng(7.0205, 39.9840),
    'robe': LatLng(7.1167, 40.00),
    'bale robe': LatLng(7.1167, 40.00),
    'ginner': LatLng(6.1667, 39.5833),
    'jinka': LatLng(5.7833, 36.5667),
    'negele': LatLng(5.3333, 39.5833),
    'negele borana': LatLng(5.3333, 39.5833),
    'bule hora': LatLng(5.5667, 38.2333),
    'yabelo': LatLng(4.8833, 38.10),
    'moyale': LatLng(3.5275, 39.0547),
    'awash': LatLng(8.8667, 40.1667),
    'metehara': LatLng(8.90, 39.9167),
    'matahara': LatLng(8.90, 39.9167),
    'chiro': LatLng(9.0833, 40.3333),
    'asebe teferi': LatLng(9.1000, 40.7000),
    'dire dawa city': LatLng(9.5931, 41.8661),
    'aysha': LatLng(11.2167, 41.4167),
    'adanah': LatLng(10.3333, 41.4333),
  };

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static LatLng? findCity(String? name) {
    if (name == null) return null;
    final key = _normalize(name);
    if (key.isEmpty) return null;

    if (_cities.containsKey(key)) return _cities[key];

    for (final entry in _cities.entries) {
      final cityKey = entry.key;
      if (cityKey.length >= 4 && key.contains(cityKey)) return entry.value;
      if (key.length >= 4 && cityKey.contains(key)) return entry.value;
    }
    return null;
  }

  static List<LatLng>? buildRoute(String? from, String? to) {
    final origin = findCity(from);
    final destination = findCity(to);
    if (origin == null || destination == null) return null;
    return [origin, destination];
  }
}
