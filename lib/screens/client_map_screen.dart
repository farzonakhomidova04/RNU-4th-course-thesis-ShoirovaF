import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import '../models/tourist_object.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';
import '../services/tts_service.dart';
import '../core/theme/app_theme.dart';
import 'border_guide_screen.dart';

class ClientMapScreen extends StatefulWidget {
  const ClientMapScreen({super.key});

  @override
  State<ClientMapScreen> createState() => _ClientMapScreenState();
}

class _ClientMapScreenState extends State<ClientMapScreen> {
  final LocalDbService _localDbService = LocalDbService();
  final SyncService _syncService = SyncService();
  final TtsService _ttsService = TtsService();
  final MapController _mapController = MapController();
  
  List<TouristObject> _places = [];
  bool _isLoading = true;
  
  LatLng? _userLocation;
  List<LatLng> _routePoints = [];

  // New States
  String _selectedCategoryKey = 'categories_all';
  String _searchQuery = '';
  String _currentMapLayer = 'map_standard';
  Map<String, dynamic>? _weatherData;
  bool _isSearching = false;

  final Map<String, String> _categoryKeyToDb = {
    'categories_all': 'Barchasi',
    'category_nature': 'Tabiat',
    'category_history': 'Tarix',
    'category_shrine': 'Ziyoratgoh',
    'category_recreation': 'Dam olish',
    'category_hotel': 'Mehmonxona',
    'category_food': 'Ovqatlanish',
  };

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadData();
    _getUserLocation();
    _fetchWeather();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _syncService.syncData();
    _places = await _localDbService.getAllTouristObjects();
    setState(() => _isLoading = false);
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _fetchWeather() async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=39.9833&longitude=71.8000&current_weather=true');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body)['current_weather'];
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch weather: $e');
    }
  }

  Future<void> _fetchRoute(LatLng destination) async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('location_not_found'.tr())));
      return;
    }

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${_userLocation!.longitude},${_userLocation!.latitude};${destination.longitude},${destination.latitude}?geometries=geojson'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry']['coordinates'] as List;
          setState(() {
            _routePoints = geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch route: $e');
    }
  }

  String _getMapUrlTemplate() {
    switch (_currentMapLayer) {
      case 'map_satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'map_terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'map_standard':
      default:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
  }

  void _showLayerPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('map_type'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.map),
                title: Text('map_standard'.tr()),
                trailing: _currentMapLayer == 'map_standard' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _currentMapLayer = 'map_standard');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.satellite),
                title: Text('map_satellite'.tr()),
                trailing: _currentMapLayer == 'map_satellite' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _currentMapLayer = 'map_satellite');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.terrain),
                title: Text('map_terrain'.tr()),
                trailing: _currentMapLayer == 'map_terrain' ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
                onTap: () {
                  setState(() => _currentMapLayer = 'map_terrain');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showRateDialog(TouristObject place) {
    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('${'rate_place'.tr()}: ${place.getLocalizedName(context.locale.languageCode)}', style: const TextStyle(fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'write_review'.tr(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr()),
                ),
                isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          setStateDialog(() => isSubmitting = true);
                          try {
                            await _syncService.submitReview(place.id, selectedRating, commentController.text.trim());
                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadData(); // Reload to get new average rating
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('review_submitted'.tr())));
                          } catch (e) {
                            setStateDialog(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('error_occurred'.tr())));
                          }
                        },
                        child: Text('submit_review'.tr()),
                      ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = const LatLng(39.9833, 71.8000);
    
    // Filter places
    final filteredPlaces = _places.where((p) {
      String dbCategory = _categoryKeyToDb[_selectedCategoryKey]!;
      bool matchesCategory = dbCategory == 'Barchasi' || p.category.toLowerCase() == dbCategory.toLowerCase();
      bool matchesSearch = _searchQuery.isEmpty || 
          p.nameUz.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          p.nameRu.toLowerCase().contains(_searchQuery.toLowerCase()) || 
          p.nameEn.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final recommendedPlaces = filteredPlaces.where((p) => p.isRecommended).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isLoading
              ? Container(
                  decoration: AppTheme.backgroundGradient,
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 11.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _getMapUrlTemplate(),
                      userAgentPackageName: 'com.example.tourtravel',
                      subdomains: const ['a', 'b', 'c', 'd'],
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4.0,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                          ),
                        ...filteredPlaces.map((place) {
                          final placeName = place.getLocalizedName(context.locale.languageCode);
                          return Marker(
                            point: LatLng(place.lat, place.lng),
                            width: 140,
                            height: 90,
                            child: GestureDetector(
                              onTap: () => _showPlaceDetails(context, place),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    place.isRecommended ? Icons.star : Icons.location_on,
                                    color: place.isRecommended ? Colors.amber : AppTheme.primaryColor,
                                    size: 32.0,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  SizedBox(
                                    width: 140,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          placeName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            foreground: Paint()
                                              ..style = PaintingStyle.stroke
                                              ..strokeWidth = 3.0
                                              ..color = Colors.white.withOpacity(0.9),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          placeName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
          
          // Floating Top Bar with Search & Weather
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: FadeInDown(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.textPrimary.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!_isSearching) ...[
                              Text(
                                'app_title'.tr(),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                              ),
                              Row(
                                children: [
                                  if (_weatherData != null) ...[
                                    const Icon(Icons.thermostat, color: AppTheme.textPrimary, size: 20),
                                    Text('${_weatherData!['temperature']}°C', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                                    const SizedBox(width: 15),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.search, color: AppTheme.textPrimary),
                                    onPressed: () => setState(() => _isSearching = true),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const BorderGuideScreen()),
                                      );
                                    },
                                  )
                                ],
                              )
                            ] else ...[
                              Expanded(
                                child: TextField(
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'search_hint'.tr(),
                                    border: InputBorder.none,
                                    icon: const Icon(Icons.search),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchQuery = '';
                                        });
                                      },
                                    ),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Categories Row
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categoryKeyToDb.length,
                      itemBuilder: (context, index) {
                        final catKey = _categoryKeyToDb.keys.elementAt(index);
                        final isSelected = _selectedCategoryKey == catKey;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(catKey.tr()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryKey = catKey;
                              });
                            },
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Layer Switcher Button
          Positioned(
            top: 170,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.surfaceColor.withOpacity(0.9),
              onPressed: _showLayerPicker,
              child: const Icon(Icons.layers, color: AppTheme.primaryColor),
            ),
          ),

          // Recommendations Slider
          if (recommendedPlaces.isNotEmpty)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              height: 120,
              child: FadeInUp(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: recommendedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = recommendedPlaces[index];
                    return GestureDetector(
                      onTap: () {
                        _mapController.move(LatLng(place.lat, place.lng), 15.0);
                        _showPlaceDetails(context, place);
                      },
                      child: Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    place.getLocalizedName(context.locale.languageCode),
                                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              place.category,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Location Button
            Positioned(
              bottom: recommendedPlaces.isNotEmpty ? 170 : 30,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: AppTheme.surfaceColor,
                onPressed: () {
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 15.0);
                  } else {
                    _getUserLocation();
                  }
                },
                child: const Icon(Icons.my_location, color: AppTheme.primaryColor),
              ),
            )
        ],
      ),
    );
  }

  void _showPlaceDetails(BuildContext context, TouristObject place) {
    final lang = context.locale.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return FadeInUp(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withOpacity(0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(top: BorderSide(color: AppTheme.textPrimary.withOpacity(0.1))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            place.getLocalizedName(lang),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26, color: AppTheme.primaryColor),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: AppTheme.textPrimary),
                          onPressed: () {
                            _ttsService.speak(place.getLocalizedDescription(lang), lang);
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          place.category,
                          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.8), fontStyle: FontStyle.italic),
                        ),
                        const Spacer(),
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${place.rating.toStringAsFixed(1)} (${place.reviewCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          place.getLocalizedDescription(lang),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _fetchRoute(LatLng(place.lat, place.lng));
                            },
                            icon: const Icon(Icons.directions),
                            label: Text('directions'.tr()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryColor)),
                            onPressed: () {
                              Navigator.pop(context);
                              _showRateDialog(place);
                            },
                            icon: const Icon(Icons.rate_review, color: AppTheme.primaryColor),
                            label: Text('rate_place'.tr(), style: const TextStyle(color: AppTheme.primaryColor)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.textSecondary)),
                            onPressed: () {
                              _ttsService.stop();
                              Navigator.pop(context);
                            },
                            child: Text('close'.tr(), style: const TextStyle(color: AppTheme.textPrimary)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
