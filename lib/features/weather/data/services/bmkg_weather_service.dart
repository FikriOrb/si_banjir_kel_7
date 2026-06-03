import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/bmkg_weather_warning.dart';

final bmkgWeatherServiceProvider = Provider<BmkgWeatherService>((ref) {
  return BmkgWeatherService(http.Client());
});

final bmkgMedanWarningProvider =
    FutureProvider.autoDispose<BmkgWeatherWarning?>((ref) async {
  return ref.watch(bmkgWeatherServiceProvider).fetchMedanWarning();
});

class BmkgWeatherService {
  BmkgWeatherService(this._client);

  final http.Client _client;

  static final Uri _nowcastFeedUri = Uri.parse(
    'https://www.bmkg.go.id/alerts/nowcast/id',
  );

  Future<BmkgWeatherWarning?> fetchMedanWarning() async {
    final response = await _client.get(_nowcastFeedUri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('BMKG mengembalikan HTTP ${response.statusCode}.');
    }

    final feed = XmlDocument.parse(response.body);
    final items = feed.findAllElements('item');

    for (final item in items) {
      final title = _childText(item, 'title');
      final description = _childText(item, 'description');
      final detailLink = _childText(item, 'link');
      final searchableText = '$title $description'.toLowerCase();

      if (_containsMedan(searchableText)) {
        return BmkgWeatherWarning(
          headline: title.isEmpty ? 'Peringatan dini BMKG Medan' : title,
          area: 'Kota Medan',
          rawSeverity: description,
        );
      }

      if (_isNorthSumatra(searchableText) && detailLink.isNotEmpty) {
        final capWarning = await _fetchCapWarning(Uri.parse(detailLink));
        if (capWarning != null) return capWarning;
      }
    }

    return null;
  }

  Future<BmkgWeatherWarning?> _fetchCapWarning(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('BMKG CAP mengembalikan HTTP ${response.statusCode}.');
    }

    final cap = XmlDocument.parse(response.body);
    final headline = _firstElementText(cap, 'headline');
    final description = _firstElementText(cap, 'description');
    final severity = _firstElementText(cap, 'severity');
    final impactedAreas = cap
        .findAllElements('areaDesc')
        .map((element) => element.innerText)
        .join(' ');

    if (!_containsMedan('$headline $description $impactedAreas'.toLowerCase())) {
      return null;
    }

    return BmkgWeatherWarning(
      headline: headline.isEmpty ? 'Peringatan dini BMKG Medan' : headline,
      area: impactedAreas.isEmpty ? 'Kota Medan' : impactedAreas,
      rawSeverity: severity.isEmpty ? description : severity,
    );
  }

  bool _containsMedan(String value) {
    return value.contains('medan') || 
           value.contains('kota medan') || 
           value.contains('sumatera utara') || 
           value.contains('sumatra utara');
  }

  bool _isNorthSumatra(String value) {
    return value.contains('sumatera utara') || value.contains('sumatra utara');
  }

  String _childText(XmlElement element, String name) {
    return element.getElement(name)?.innerText.trim() ?? '';
  }

  String _firstElementText(XmlDocument document, String name) {
    final matches = document.findAllElements(name);
    return matches.isEmpty ? '' : matches.first.innerText.trim();
  }
}
