import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/core/ui/ui.dart';
import 'package:ezan_saati/l10n/app_localizations.dart';
import '../home/view_model/home_view_model.dart';

/// Dünya genelinde konum arama (alttan açılan sayfa).
///
/// Çağıran `showModalBottomSheet(isScrollControlled: true,
/// backgroundColor: Colors.transparent)` ile açar; arka planı kendisi çizer.
class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

enum _SearchError { notFound, failed }

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

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() {}); // temizle düğmesi
    final trimmed = query.trim();
    if (trimmed.length <= 2) {
      _searchId++;
      setState(() {
        _isLoading = false;
        _error = null;
        _searchResults = [];
        _resultLocations = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _performSearch(trimmed);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    _debounce?.cancel();
    final id = ++_searchId;
    _lastQuery = query;
    setState(() {
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
    final titleDisplay = _titleOf(place);
    final viewModel = context.read<HomeViewModel>();
    final messenger = ScaffoldMessenger.of(context);

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

    Navigator.pop(context);
    viewModel.changeCityAndDistrict(
      cityToSend,
      districtToSend,
      lat: selected.latitude,
      lng: selected.longitude,
    );
    messenger.showSnackBar(
      SnackBar(content: Text(loc.locationSelected(titleDisplay))),
    );
  }

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
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: AppSpacing.lg,
        endIndent: AppSpacing.lg,
      ),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return AppListTile(
          leadingIcon: Icons.location_on_outlined,
          title: _titleOf(place),
          subtitle: place.country ?? "",
          showChevron: false,
          onTap: () => _select(index, loc),
        );
      },
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
                    onSubmitted: (value) => _performSearch(value.trim()),
                    autofocus: true,
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
                Expanded(child: _buildResults(loc)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
