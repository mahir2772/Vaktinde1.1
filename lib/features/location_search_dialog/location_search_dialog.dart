import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/data/services/location_catalog.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../home/view_model/home_view_model.dart';

/// Konum seçimi (alttan açılan sayfa): internetsiz liste (Türkiye → il → ilçe,
/// Avrupa / KKTC → ülke → şehir) ve arama; gömülü listede yoksa dünya geneli
/// çevrimiçi arama.
///
/// Çağıran `showModalBottomSheet(isScrollControlled: true,
/// backgroundColor: Colors.transparent)` ile açar; arka planı kendisi çizer.
class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

enum _SearchError { notFound, failed }

/// Ülke kodunun dildeki adı (gömülü listedeki ülkeler)
String countryName(AppLocalizations loc, String code) => switch (code) {
  'TR' => loc.countryTurkey,
  'DE' => loc.countryGermany,
  'NL' => loc.countryNetherlands,
  'BE' => loc.countryBelgium,
  'FR' => loc.countryFrance,
  'AT' => loc.countryAustria,
  'CH' => loc.countrySwitzerland,
  'GB' => loc.countryUnitedKingdom,
  'DK' => loc.countryDenmark,
  'SE' => loc.countrySweden,
  'NO' => loc.countryNorway,
  'KKTC' => loc.countryNorthernCyprus,
  _ => code,
};

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Placemark> _searchResults = [];
  List<Location> _resultLocations = [];
  bool _isLoading = false;
  _SearchError? _error;
  String _lastQuery = '';
  Timer? _debounce;

  /// Eski aramanın geç gelen sonucu yenisinin üstüne yazmasın
  int _searchId = 0;

  /// Yazılan sorgu için çevrimiçi sonuçlar gösteriliyor
  bool _online = false;

  /// Gömülü liste (yüklenene kadar null; yüklenemezse sadece çevrimiçi arama)
  LocationCatalog? _catalog = LocationCatalog.loaded;
  bool _catalogFailed = false;

  /// Gezinme: null = kök, 'TR' = iller (il seçiliyse ilçeleri), diğeri şehirler
  String? _country;
  LocationProvince? _province;

  @override
  void initState() {
    super.initState();
    if (_catalog == null) {
      LocationCatalog.load().then(
        (catalog) {
          if (mounted) setState(() => _catalog = catalog);
        },
        onError: (Object _) {
          if (mounted) setState(() => _catalogFailed = true);
        },
      );
    }
  }

  List<LocationPlace> _offline(String query) =>
      _catalog?.search(query) ?? const [];

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _searchId++;
    final trimmed = query.trim();
    setState(() {
      _online = false;
      _isLoading = false;
      _error = null;
      _searchResults = [];
      _resultLocations = [];
    });
    // Gömülü listede yoksa eskisi gibi çevrimiçi aranır
    if (trimmed.length <= 2 || _offline(trimmed).isNotEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 800), () {
      // Bu arada liste yüklendiyse ve yer bulunduysa gerek yok
      if (_offline(trimmed).isEmpty) _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    _debounce?.cancel();
    final id = ++_searchId;
    _lastQuery = query;
    setState(() {
      _online = true;
      _isLoading = true;
      _error = null;
      _searchResults = [];
      _resultLocations = [];
    });

    var results = <Placemark>[];
    var locations = <Location>[];
    _SearchError? error;
    try {
      final found = await locationFromAddress(query);
      if (found.isEmpty) {
        error = _SearchError.notFound;
      } else {
        final tempResults = <Placemark>[];
        final tempLocations = <Location>[];
        final limit = found.length > 5 ? 5 : found.length;
        for (var i = 0; i < limit; i++) {
          try {
            final placemarks = await placemarkFromCoordinates(
              found[i].latitude,
              found[i].longitude,
            );
            if (placemarks.isNotEmpty) {
              tempResults.add(placemarks.first);
              tempLocations.add(found[i]);
            }
          } catch (e) {
            continue;
          }
        }
        final unique = <String>{};
        for (var i = 0; i < tempResults.length; i++) {
          final place = tempResults[i];
          final key =
              "${place.name}-${place.administrativeArea}-${place.country}";
          if (unique.add(key)) {
            results.add(place);
            locations.add(tempLocations[i]);
          }
        }
        if (results.isEmpty) error = _SearchError.notFound;
      }
    } catch (e) {
      error = _SearchError.failed;
      results = [];
      locations = [];
    }

    if (!mounted || id != _searchId) return;
    setState(() {
      _isLoading = false;
      _error = error;
      _searchResults = results;
      _resultLocations = locations;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  static String _titleOf(Placemark place) {
    var mainText =
        place.subAdministrativeArea ?? place.locality ?? place.name ?? "";
    final subText = place.administrativeArea ?? "";
    if (mainText.isEmpty || mainText == subText) {
      if (place.name != null && place.name!.isNotEmpty) {
        mainText = place.name!;
      }
    }
    var title = mainText;
    if (subText.isNotEmpty && subText != mainText) title += ", $subText";
    return title;
  }

  void _select(int index, AppLocalizations loc) {
    final place = _searchResults[index];
    final selected = _resultLocations[index];

    String cityToSend;
    String? districtToSend;
    if (place.isoCountryCode == "TR") {
      cityToSend =
          place.administrativeArea ?? place.locality ?? place.name ?? "";
      districtToSend = place.subAdministrativeArea ?? place.locality;
      if (districtToSend == cityToSend) districtToSend = null;
    } else {
      cityToSend =
          place.locality ?? place.administrativeArea ?? place.name ?? "";
      districtToSend = null;
    }
    if (cityToSend.isEmpty) cityToSend = _searchController.text.trim();

    _save(
      loc,
      city: cityToSend,
      district: districtToSend,
      lat: selected.latitude,
      lng: selected.longitude,
      title: _titleOf(place),
      country: place.isoCountryCode,
    );
  }

  /// Gömülü listeden seçim: "İlçe, İl", il merkezi ya da "Şehir, Ülke"
  void _selectPlace(LocationPlace place, AppLocalizations loc) {
    _save(
      loc,
      city: place.city,
      district: place.district,
      lat: place.lat,
      lng: place.lng,
      title: place.province != null
          ? '${place.name}, ${place.province}'
          : place.country == 'TR'
          ? place.name
          : '${place.name}, ${countryName(loc, place.country)}',
      country: place.country,
    );
  }

  /// Mevcut konum akışı: koordinat kaydı, vakitler, widget ve alarmlar
  void _save(
    AppLocalizations loc, {
    required String city,
    required String? district,
    required double lat,
    required double lng,
    required String title,
    required String? country,
  }) {
    final viewModel = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    viewModel.changeCityAndDistrict(city, district, lat: lat, lng: lng);
    // Vakitler telefonun saatiyle gösterilir: yerin saati farklıysa söylenir
    final otherZone =
        country != null && LocationCatalog.timeZoneDiffers(country);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          otherZone
              ? '${loc.locationSelected(title)}\n${loc.timesFollowPhoneClock}'
              : loc.locationSelected(title),
        ),
        duration: Duration(seconds: otherZone ? 8 : 4),
      ),
    );
  }

  void _goBack() => setState(() {
    if (_province != null) {
      _province = null;
    } else {
      _country = null;
    }
  });

  Widget _buildResults(AppLocalizations loc) {
    if (_isLoading) return const LoadingState();
    switch (_error) {
      case _SearchError.failed:
        return ErrorState(
          message: loc.searchError,
          onRetry: () => _performSearch(_lastQuery),
        );
      case _SearchError.notFound:
        return EmptyState(icon: Icons.search_off, title: loc.searchNotFound);
      case null:
        break;
    }
    if (_searchResults.isEmpty) {
      return EmptyState(icon: Icons.travel_explore, title: loc.searchInitial);
    }
    return _list(_searchResults.length, (context, index) {
      final place = _searchResults[index];
      return AppListTile(
        leadingIcon: Icons.location_on_outlined,
        title: _titleOf(place),
        subtitle: place.country ?? "",
        showChevron: false,
        onTap: () => _select(index, loc),
      );
    });
  }

  /// Ayraçlı satır listesi (sayfanın ortak görünümü)
  Widget _list(int count, IndexedWidgetBuilder builder, {Key? key}) =>
      ListView.separated(
        key: key,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: count,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          indent: AppSpacing.lg,
          endIndent: AppSpacing.lg,
        ),
        itemBuilder: builder,
      );

  /// Gömülü listede bulunanlar + sonda çevrimiçi arama (köy, başka ülke)
  Widget _buildMatches(
    List<LocationPlace> matches,
    String query,
    AppLocalizations loc,
  ) {
    return _list(matches.length + 1, (context, index) {
      if (index == matches.length) {
        return AppListTile(
          leadingIcon: Icons.travel_explore,
          title: loc.searchOnline,
          subtitle: query,
          showChevron: false,
          onTap: () => _performSearch(query),
        );
      }
      final place = matches[index];
      final area =
          place.province ?? (place.country == 'TR' ? loc.provinceCenter : null);
      return AppListTile(
        leadingIcon: Icons.location_on_outlined,
        title: place.name,
        subtitle: [?area, countryName(loc, place.country)].join(', '),
        showChevron: false,
        onTap: () => _selectPlace(place, loc),
      );
    });
  }

  /// İnternetsiz gezinme: kök → il/ülke → ilçe/şehir
  Widget _buildBrowser(AppLocalizations loc) {
    final catalog = _catalog;
    if (catalog == null) {
      return _catalogFailed
          ? EmptyState(icon: Icons.travel_explore, title: loc.searchInitial)
          : const LoadingState();
    }
    final province = _province;
    final country = _country;
    if (province != null) {
      final places = [province.center, ...province.districts];
      return _level(
        province.name,
        _list(
          places.length,
          key: PageStorageKey<String>('location_${province.name}'),
          (context, index) => AppListTile(
            title: places[index].name,
            subtitle: index == 0 ? loc.provinceCenter : null,
            showChevron: false,
            onTap: () => _selectPlace(places[index], loc),
          ),
        ),
      );
    }
    if (country == 'TR') {
      return _level(
        loc.countryTurkey,
        _list(
          catalog.provinces.length,
          key: const PageStorageKey<String>('location_TR'),
          (context, index) {
            final p = catalog.provinces[index];
            return AppListTile(
              title: p.name,
              onTap: () => setState(() => _province = p),
            );
          },
        ),
      );
    }
    if (country != null) {
      final cities = catalog.countries
          .firstWhere((c) => c.code == country)
          .cities;
      return _level(
        countryName(loc, country),
        _list(
          cities.length,
          key: PageStorageKey<String>('location_$country'),
          (context, index) => AppListTile(
            title: cities[index].name,
            showChevron: false,
            onTap: () => _selectPlace(cities[index], loc),
          ),
        ),
      );
    }
    Widget countryTile(String code, IconData icon) => AppListTile(
      leadingIcon: icon,
      title: countryName(loc, code),
      onTap: () => setState(() => _country = code),
    );
    const divider = Divider(
      height: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
    return ListView(
      key: const PageStorageKey<String>('location_root'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        countryTile('TR', Icons.flag_outlined),
        // Sayfa opak: arka plan resminde de düz başlık
        SectionHeader(loc.locationEuropeKktc, onImage: false),
        for (final (i, c) in catalog.countries.indexed) ...[
          if (i > 0) divider,
          countryTile(c.code, Icons.public),
        ],
      ],
    );
  }

  /// Alt seviye: geri düğmeli başlık + liste
  Widget _level(String title, Widget list) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.xs,
            end: AppSpacing.lg,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const BackButtonIcon(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: _goBack,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: list),
      ],
    );
  }

  Widget _buildBody(AppLocalizations loc) {
    final query = _searchController.text.trim();
    final matches = query.isEmpty || _online
        ? const <LocationPlace>[]
        : _offline(query);
    // Sistem geri tuşu önce listede bir üst seviyeye çıkar
    return PopScope(
      canPop: _country == null || query.isNotEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: query.isEmpty
          ? _buildBrowser(loc)
          : matches.isNotEmpty
          ? _buildMatches(matches, query, loc)
          : _buildResults(loc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);

    return Padding(
      // Klavye açılınca sayfa yukarı kayar
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Material(
        color: theme.bottomSheetTheme.backgroundColor ?? scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: media.size.height * 0.85,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(top: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            loc.searchLocationTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: loc.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      final query = value.trim();
                      if (_offline(query).isEmpty) _performSearch(query);
                    },
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: loc.searchLocationHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: _buildBody(loc)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
