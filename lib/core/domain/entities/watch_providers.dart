import 'package:flutter/foundation.dart';

/// An individual streaming or purchase provider (e.g. Netflix, Canal+).
@immutable
class WatchProviderItem {
  final int providerId;
  final String providerName;
  final String? logoPath;
  final int? displayPriority;

  const WatchProviderItem({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    this.displayPriority,
  });

  factory WatchProviderItem.fromJson(Map<String, dynamic> json) {
    return WatchProviderItem(
      providerId: (json['provider_id'] as num?)?.toInt() ?? 0,
      providerName: (json['provider_name'] as String?) ?? '',
      logoPath: json['logo_path'] as String?,
      displayPriority: (json['display_priority'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'provider_id': providerId,
    'provider_name': providerName,
    if (logoPath != null) 'logo_path': logoPath,
    if (displayPriority != null) 'display_priority': displayPriority,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchProviderItem &&
          runtimeType == other.runtimeType &&
          providerId == other.providerId &&
          providerName == other.providerName &&
          logoPath == other.logoPath &&
          displayPriority == other.displayPriority;

  @override
  int get hashCode =>
      Object.hash(providerId, providerName, logoPath, displayPriority);
}

/// Where to watch a media in a single country, grouped by offer type.
@immutable
class WatchProviderCountryInfo {
  final String? link;
  final List<WatchProviderItem> flatrate;
  final List<WatchProviderItem> rent;
  final List<WatchProviderItem> buy;
  final List<WatchProviderItem> free;
  final List<WatchProviderItem> ads;

  const WatchProviderCountryInfo({
    this.link,
    this.flatrate = const [],
    this.rent = const [],
    this.buy = const [],
    this.free = const [],
    this.ads = const [],
  });

  bool get isEmpty =>
      flatrate.isEmpty &&
      rent.isEmpty &&
      buy.isEmpty &&
      free.isEmpty &&
      ads.isEmpty;

  bool get isNotEmpty => !isEmpty;

  factory WatchProviderCountryInfo.fromJson(Map<String, dynamic> json) {
    List<WatchProviderItem> parseList(dynamic list) {
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map(
            (item) =>
                WatchProviderItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return WatchProviderCountryInfo(
      link: json['link'] as String?,
      flatrate: parseList(json['flatrate']),
      rent: parseList(json['rent']),
      buy: parseList(json['buy']),
      free: parseList(json['free']),
      ads: parseList(json['ads']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (link != null) 'link': link,
    if (flatrate.isNotEmpty)
      'flatrate': flatrate.map((e) => e.toJson()).toList(),
    if (rent.isNotEmpty) 'rent': rent.map((e) => e.toJson()).toList(),
    if (buy.isNotEmpty) 'buy': buy.map((e) => e.toJson()).toList(),
    if (free.isNotEmpty) 'free': free.map((e) => e.toJson()).toList(),
    if (ads.isNotEmpty) 'ads': ads.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchProviderCountryInfo &&
          runtimeType == other.runtimeType &&
          link == other.link &&
          listEquals(flatrate, other.flatrate) &&
          listEquals(rent, other.rent) &&
          listEquals(buy, other.buy) &&
          listEquals(free, other.free) &&
          listEquals(ads, other.ads);

  @override
  int get hashCode => Object.hash(
    link,
    Object.hashAll(flatrate),
    Object.hashAll(rent),
    Object.hashAll(buy),
    Object.hashAll(free),
    Object.hashAll(ads),
  );
}

/// Parsed results of TMDB's `/watch/providers` endpoint, keyed by 2-letter
/// ISO 3166-1 country code (uppercase).
@immutable
class WatchProviders {
  final Map<String, WatchProviderCountryInfo> byCountry;

  const WatchProviders({this.byCountry = const {}});

  bool get isEmpty => byCountry.isEmpty;
  bool get isNotEmpty => byCountry.isNotEmpty;

  /// Returns the offers for [countryCode] (case-insensitive), or `null`.
  WatchProviderCountryInfo? forCountry(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return null;
    return byCountry[countryCode.toUpperCase()];
  }

  /// Parses a TMDB watch/providers payload, either directly keyed by country
  /// or wrapped in a `results` object.
  factory WatchProviders.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const WatchProviders();
    }

    final Map<String, dynamic> source =
        json.containsKey('results') && json['results'] is Map
        ? Map<String, dynamic>.from(json['results'] as Map)
        : json;

    final map = <String, WatchProviderCountryInfo>{};
    for (final entry in source.entries) {
      if (entry.value is Map) {
        final info = WatchProviderCountryInfo.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        map[entry.key.toUpperCase()] = info;
      }
    }
    return WatchProviders(byCountry: map);
  }

  Map<String, dynamic> toJson() =>
      byCountry.map((k, v) => MapEntry(k, v.toJson()));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchProviders &&
          runtimeType == other.runtimeType &&
          mapEquals(byCountry, other.byCountry);

  @override
  int get hashCode => Object.hashAll(byCountry.entries);
}
