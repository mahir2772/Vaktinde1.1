import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import 'package:ezan_saati/l10n/app_localizations.dart';

import '../home/view_model/home_view_model.dart';

class LocationSearchDialog extends StatefulWidget {
  const LocationSearchDialog({super.key});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Placemark> _searchResults = [];
  bool _isLoading = false;
  String _error = ''; // Hata durumunu kod olarak tutacağız (örn: 'NOT_FOUND')
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (query.length > 2) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = '';
      _searchResults = [];
    });

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        List<Placemark> tempResults = [];
        int limit = locations.length > 5 ? 5 : locations.length;

        for (int i = 0; i < limit; i++) {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              locations[i].latitude,
              locations[i].longitude,
            );
            if (placemarks.isNotEmpty) {
              tempResults.add(placemarks.first);
            }
          } catch (e) {
            continue;
          }
        }

        final uniqueResults = <String>{};
        final filteredResults = tempResults.where((element) {
          final key =
              "${element.name}-${element.administrativeArea}-${element.country}";
          return uniqueResults.add(key);
        }).toList();

        setState(() {
          _searchResults = filteredResults;
        });
      } else {
        // Hata mesajını direkt yazmıyoruz, kod atıyoruz. Build'de çevireceğiz.
        setState(() => _error = 'NOT_FOUND');
      }
    } catch (e) {
      setState(() => _error = 'ERROR');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- ÇEVİRİ NESNESİ ---
    final loc = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text(
            loc.searchLocationTitle, // ARTIK DEĞİŞKENDEN GELİYOR
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: loc.searchLocationHint, // ARTIK DEĞİŞKENDEN GELİYOR
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                ? Center(
                    child: Text(
                      // Hata mesajları da dil desteğine kavuştu
                      _error == 'NOT_FOUND'
                          ? loc.searchNotFound
                          : _error == 'ERROR'
                          ? loc.searchError
                          : loc.searchInitial, // "Aramak için yazın..." yerine değişkenden geliyor
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];

                      String mainText =
                          place.subAdministrativeArea ??
                          place.locality ??
                          place.name ??
                          "";
                      String subText = place.administrativeArea ?? "";
                      String country = place.country ?? "";

                      if (mainText.isEmpty || mainText == subText) {
                        if (place.name != null && place.name!.isNotEmpty) {
                          mainText = place.name!;
                        }
                      }

                      String titleDisplay = mainText;
                      if (subText.isNotEmpty && subText != mainText) {
                        titleDisplay += ", $subText";
                      }

                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.teal,
                        ),
                        title: Text(
                          titleDisplay,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(country),
                        onTap: () {
                          Navigator.pop(context);

                          String cityToSend = "";
                          String? districtToSend;

                          if (place.isoCountryCode == "TR") {
                            cityToSend =
                                place.administrativeArea ??
                                place.locality ??
                                place.name ??
                                "";
                            districtToSend =
                                place.subAdministrativeArea ?? place.locality;
                            if (districtToSend == cityToSend)
                              districtToSend = null;
                          } else {
                            cityToSend =
                                place.locality ??
                                place.administrativeArea ??
                                place.name ??
                                "";
                            districtToSend = null;
                          }

                          if (cityToSend.isEmpty)
                            cityToSend = _searchController.text;

                          context.read<HomeViewModel>().changeCityAndDistrict(
                            cityToSend,
                            districtToSend,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              // Seçildi yazısı da artık dinamik
                              content: Text(loc.locationSelected(titleDisplay)),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
