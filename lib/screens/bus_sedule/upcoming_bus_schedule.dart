import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/theme_config.dart';
import '../../core/di/injection_container.dart';
import '../../utils/error_handler.dart';
import '../../widgets/staff_bottom_nav_bar.dart';

class BusScheduleScreen extends StatefulWidget {
  const BusScheduleScreen({super.key});

  @override
  State<BusScheduleScreen> createState() => _BusScheduleScreenState();
}

class _BusScheduleScreenState extends State<BusScheduleScreen> {
  final TextEditingController _fromController =
      TextEditingController(text: 'Colombo Fort');
  final TextEditingController _toController =
      TextEditingController(text: 'Kandy');

  DateTime? _selectedDateTime;
  bool _isLoading = false;
  String? _errorMessage;
  List<BusTripView> _trips = [];
  bool _showAllSchedules = false;

  @override
  void initState() {
    super.initState();
    _searchTrips();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFFFFBF5);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
        ),
        title: const Text(
          'Upcoming Bus Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: const StaffBottomNavBar(currentIndex: 3),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Today\'s Bus Schedule',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Next arrivals and departures',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildSearchPanel(context),
              const SizedBox(height: 24),
              Text(
                _showAllSchedules
                    ? 'All Upcoming Departures'
                    : 'Upcoming Departures',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildResultsSection(context),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Trips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fromController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    hintText: 'Origin stop',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _toController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    hintText: 'Destination stop',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: _showAllSchedules,
                activeColor: AppColors.primary,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _showAllSchedules = value;
                        });
                        _searchTrips();
                      },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Show all schedules',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickDateTime(context),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Departure time (optional)',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedDateTime == null
                    ? 'Use current time'
                    : _formatDateTime(_selectedDateTime!, context),
                style: TextStyle(
                  color: _selectedDateTime == null
                      ? Colors.grey.shade600
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _searchTrips,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _searchTrips,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_trips.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.event_busy, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              _showAllSchedules
                  ? 'No schedules available in this range'
                  : 'No trips found for the selected route',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _trips
          .map(
            (trip) => BusCard(
              busNumber: trip.busNumber,
              route: trip.route,
              time: _formatTime(trip.departureTime, context),
              status: trip.status,
              platform: trip.platform,
              availableSeats: trip.availableSeats,
              features: trip.features,
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 90)),
    );

    if (selectedDate == null) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _searchTrips() async {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();

    if (!_showAllSchedules && (from.isEmpty || to.isEmpty)) {
      setState(() {
        _errorMessage = 'Please enter both origin and destination stops.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = InjectionContainer().apiClient;
      final response = _showAllSchedules
          ? await _fetchAllSchedules(apiClient, from, to)
          : await _searchByRoute(apiClient, from, to);

      final trips = _extractTrips(response.data);

      setState(() {
        _trips = trips.map(_mapTripToView).toList();
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      ErrorHandler.logError('Bus schedule search failed', error, stackTrace);
      setState(() {
        _errorMessage = ErrorHandler.handleError(error);
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _searchByRoute(
    dynamic apiClient,
    String from,
    String to,
  ) async {
    final payload = <String, dynamic>{
      'from': from,
      'to': to,
    };

    if (_selectedDateTime != null) {
      payload['datetime'] = _selectedDateTime!.toUtc().toIso8601String();
    }

    return apiClient.post(
      ApiConfig.searchTripsEndpoint,
      data: payload,
    );
  }

  Future<dynamic> _fetchAllSchedules(
    dynamic apiClient,
    String from,
    String to,
  ) async {
    final baseDate = (_selectedDateTime ?? DateTime.now()).toUtc();
    final startDate = DateTime.utc(baseDate.year, baseDate.month, baseDate.day);
    final endDate = startDate.add(const Duration(days: 7));

    final queryParameters = <String, dynamic>{
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
    };

    if (from.isNotEmpty) {
      queryParameters['origin'] = from;
    }

    if (to.isNotEmpty) {
      queryParameters['destination'] = to;
    }

    return apiClient.getPublic(
      ApiConfig.bookableTripsEndpoint,
      queryParameters: queryParameters,
    );
  }

  List<dynamic> _extractTrips(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      final candidates = [
        'trips',
        'results',
        'data',
        'search_results',
      ];

      for (final key in candidates) {
        final value = responseData[key];
        if (value is List) {
          return value;
        }
      }
    }

    return [];
  }

  BusTripView _mapTripToView(dynamic raw) {
    final trip = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    final busInfo = _readMap(trip, ['bus', 'vehicle', 'coach']);
    final routeInfo = _readMap(trip, ['route', 'route_info']);

    final from = _readString(trip, [
          'from',
          'origin',
          'origin_stop',
          'originStop',
          'from_stop',
          'fromStop',
          'start_stop',
          'startStop'
        ]) ??
        _readString(routeInfo, ['from', 'origin', 'start']);

    final to = _readString(trip, [
          'to',
          'destination',
          'destination_stop',
          'destinationStop',
          'to_stop',
          'toStop',
          'end_stop',
          'endStop'
        ]) ??
        _readString(routeInfo, ['to', 'destination', 'end']);

    final route = _readString(trip, ['route', 'route_name', 'routeName']) ??
        _readString(routeInfo, ['name', 'route_name', 'routeName']) ??
        _buildRouteLabel(from, to);

    final busNumber = _readString(trip, [
          'bus_number',
          'busNumber',
          'vehicle_number',
          'vehicleNumber',
          'bus_no'
        ]) ??
        _readString(busInfo,
            ['number', 'bus_number', 'registration', 'registration_number']) ??
        'Bus';

    final departureTimeString = _readString(trip, [
          'departure_time',
          'departureTime',
          'scheduled_time',
          'scheduledTime',
          'datetime',
          'departure_datetime',
          'departureDateTime'
        ]) ??
        _readString(routeInfo, ['departure_time', 'departureTime']);

    final availableSeats = _readInt(trip, [
          'available_seats',
          'availableSeats',
          'seats_available',
          'seatsAvailable'
        ]) ??
        _readInt(busInfo, ['available_seats', 'availableSeats']);

    final status = _readString(trip, ['status', 'availability_status']) ??
        _statusFromSeats(availableSeats) ??
        'On Time';

    final platform =
        _readString(trip, ['platform', 'bay', 'stand', 'gate']) ?? 'TBD';

    final features = _readStringList(trip, ['features', 'amenities']) ??
        _readStringList(busInfo, ['features', 'amenities']) ??
        [];

    return BusTripView(
      busNumber: busNumber,
      route: route,
      departureTime: _tryParseDateTime(departureTimeString),
      status: status,
      platform: platform,
      availableSeats: availableSeats,
      features: features,
    );
  }

  Map<String, dynamic> _readMap(
    Map<String, dynamic> source,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return {};
  }

  String? _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Map<String, dynamic>) {
        final nestedValue = _readNestedName(value);
        if (nestedValue != null) {
          return nestedValue;
        }
      }
    }
    return null;
  }

  String? _readNestedName(Map<String, dynamic> source) {
    final nameKeys = [
      'name',
      'stop_name',
      'stopName',
      'location_name',
      'locationName',
      'display_name',
      'displayName',
    ];

    for (final key in nameKeys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    for (final value in source.values) {
      if (value is Map<String, dynamic>) {
        final nestedValue = _readNestedName(value);
        if (nestedValue != null) {
          return nestedValue;
        }
      }
    }

    return null;
  }

  int? _readInt(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  List<String>? _readStringList(
      Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is List) {
        return value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }
    return null;
  }

  DateTime? _tryParseDateTime(String? value) {
    if (value == null) {
      return null;
    }
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _buildRouteLabel(String? from, String? to) {
    final origin = from ?? 'Origin';
    final destination = to ?? 'Destination';
    return '$origin - $destination';
  }

  String? _statusFromSeats(int? availableSeats) {
    if (availableSeats == null) {
      return null;
    }
    return availableSeats > 0 ? 'Available' : 'Full';
  }

  String _formatTime(DateTime? dateTime, BuildContext context) {
    if (dateTime == null) {
      return 'TBD';
    }
    return TimeOfDay.fromDateTime(dateTime).format(context);
  }

  String _formatDateTime(DateTime dateTime, BuildContext context) {
    final date = MaterialLocalizations.of(context).formatShortDate(dateTime);
    final time = TimeOfDay.fromDateTime(dateTime).format(context);
    return '$date $time';
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class BusCard extends StatelessWidget {
  final String busNumber;
  final String route;
  final String time;
  final String status;
  final String platform;
  final int? availableSeats;
  final List<String> features;

  const BusCard({
    super.key,
    required this.busNumber,
    required this.route,
    required this.time,
    required this.status,
    required this.platform,
    this.availableSeats,
    this.features = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDelayed = status == 'Delayed';
    final statusColor =
        isDelayed ? Colors.orange.shade700 : Colors.green.shade700;
    final statusBgColor =
        isDelayed ? Colors.orange.shade50 : Colors.green.shade50;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        busNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.access_time,
                  'Departure',
                  time,
                  AppColors.primary,
                ),
                _buildDivider(),
                _buildInfoItem(
                  Icons.confirmation_number_outlined,
                  'Platform',
                  platform,
                  Colors.blue.shade600,
                ),
                if (availableSeats != null) ...[
                  _buildDivider(),
                  _buildInfoItem(
                    Icons.event_seat,
                    'Seats',
                    availableSeats.toString(),
                    Colors.green.shade700,
                  ),
                ],
              ],
            ),
          ),
          if (features.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: features
                    .map(
                      (feature) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade300);
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class BusTripView {
  final String busNumber;
  final String route;
  final DateTime? departureTime;
  final String status;
  final String platform;
  final int? availableSeats;
  final List<String> features;

  const BusTripView({
    required this.busNumber,
    required this.route,
    required this.departureTime,
    required this.status,
    required this.platform,
    required this.availableSeats,
    required this.features,
  });
}
