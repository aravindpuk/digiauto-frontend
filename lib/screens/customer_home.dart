import 'dart:typed_data';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:digiauto/models/job_card.dart';
import 'package:digiauto/screens/login.dart';
import 'package:digiauto/services/jobcard_service.dart';
import 'package:digiauto/services/used_spare_service.dart';
import 'package:digiauto/services/vehicle_catalog_service.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const _primary = Color(0xFF2E7BA6);
  static const _ink = Color(0xFF17384C);
  static const _muted = Color(0xFF71818B);
  static const _canvas = Color(0xFFF3F7FA);
  final _jobService = JobcardService();
  final _spareService = UsedSpareService();

  int _selectedTab = 0;
  late Future<JobCard?> _jobFuture;
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _jobFuture = _jobService.fetchMyLatestCustomerJob();
    _ordersFuture = _spareService.fetchMyRequests();
  }

  Future<void> _refresh() async {
    setState(_loadData);
    await Future.wait(
      [
        _jobFuture,
        _ordersFuture,
      ].map((future) => future.then((_) {}, onError: (_) {})),
    );
  }

  void _openTab(int index) => setState(() => _selectedTab = index);

  @override
  Widget build(BuildContext context) {
    final pages = [_homeTab(), _requestTab(), _ordersTab(), _settingsTab()];
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.directions_car_filled_outlined,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DigiAuto',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'CUSTOMER',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded, color: _ink),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: 4,
        activeIndex: _selectedTab,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.softEdge,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.secondary.withValues(alpha: 0.95),
        onTap: _openTab,
        tabBuilder: (index, isActive) {
          const icons = [
            Icons.home_rounded,
            Icons.search_rounded,
            Icons.receipt_long_rounded,
            Icons.settings_rounded,
          ];
          const labels = ['Home', 'Order spare', 'Orders', 'Settings'];
          final color = isActive ? Colors.white : Colors.white70;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icons[index], size: 23, color: color),
              const SizedBox(height: 3),
              Text(
                labels[index],
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _homeTab() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Your vehicle, taken care of.',
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Track service updates and find the parts you need.',
            style: TextStyle(color: _muted, fontSize: 14),
          ),
          const SizedBox(height: 22),
          FutureBuilder<JobCard?>(
            future: _jobFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _card(
                  child: const SizedBox(
                    height: 90,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _card(
                  child: _emptyService(onRetry: _refresh, error: true),
                );
              }
              final job = snapshot.data;
              if (job != null && _isInService(job.status))
                return _activeJobCard(job);
              return _emptyService(job: job);
            },
          ),
          const SizedBox(height: 18),
          _usedSparePromo(),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Recent spare request',
                  style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openTab(2),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _ordersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _card(child: const LinearProgressIndicator());
              }
              final orders = snapshot.data ?? const <Map<String, dynamic>>[];
              if (snapshot.hasError || orders.isEmpty) {
                return _card(
                  child: Row(
                    children: [
                      const Icon(Icons.inbox_outlined, color: _muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          snapshot.hasError
                              ? 'Could not load your requests.'
                              : 'Your spare requests will appear here.',
                          style: const TextStyle(color: _muted),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _orderCard(orders.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyService({
    JobCard? job,
    bool error = false,
    Future<void> Function()? onRetry,
  }) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(
            Icons.build_circle_outlined,
            const Color(0xFFEAF3F8),
            _primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error
                      ? 'Service update unavailable'
                      : 'No vehicle in service right now',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  error
                      ? 'Check your connection and refresh to try again.'
                      : job == null
                      ? 'When a garage creates a job card for your mobile number, it will show here.'
                      : 'Your latest service is ${_prettyStatus(job.status).toLowerCase()}. Track your next spare request below.',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (error && onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Try again'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeJobCard(JobCard job) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF236D97), Color(0xFF174B6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.19),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your vehicle is in service',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              _statusPill(job.status, dark: true),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.vehicleMake} ${job.vehicleModel}'.trim().isEmpty
                          ? 'Your vehicle'
                          : '${job.vehicleMake} ${job.vehicleModel}'.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      job.vehicleNumber.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                'Job card DIGI-J${job.id.padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                job.formattedCreatedAt.split(' ').first,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          if (job.services.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              job.services.take(2).map((item) => item.text).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _usedSparePromo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.settings_suggest_outlined,
                const Color(0xFFFFF1E9),
                const Color(0xFFF17745),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Find a used spare',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: _primary),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Looking for a spare part for your vehicle? Tell us what you need and we’ll help you find it.',
            style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openTab(1),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Find used spare'),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestTab() => _UsedSpareRequestForm(
    service: _spareService,
    onSubmitted: () {
      setState(() {
        _ordersFuture = _spareService.fetchMyRequests();
        _selectedTab = 2;
      });
    },
  );

  Widget _ordersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return _emptyTab(
            'Could not load orders',
            'Please refresh and try again.',
            Icons.cloud_off_outlined,
          );
        }
        final orders = snapshot.data ?? const <Map<String, dynamic>>[];
        if (orders.isEmpty)
          return _emptyTab(
            'No orders yet',
            'Your used spare requests and their status will appear here.',
            Icons.receipt_long_outlined,
          );
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          itemCount: orders.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Your spare requests',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }
            return _orderCard(orders[index - 1]);
          },
        );
      },
    );
  }

  Widget _settingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _card(
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFEAF3F8),
                child: Icon(Icons.person_outline, color: _primary),
              ),
              SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer account',
                    style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Signed in with mobile and PIN',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFBA4A45)),
            title: const Text(
              'Log out',
              style: TextStyle(
                color: Color(0xFFBA4A45),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: _logout,
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final name = (order['spare_name'] ?? '').toString();
    final title = name.isNotEmpty ? name : 'Spare from image';
    final vehicle =
        '${order['vehicle_make'] ?? ''} ${order['vehicle_model'] ?? ''}'.trim();
    final year = (order['vehicle_year'] ?? '').toString();
    final images = (order['images'] as List?) ?? const [];
    final assignments =
        (order['assignments'] as List?)?.whereType<Map>().toList() ?? const [];
    final canManage = order['status'] == 'submitted';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.settings_outlined,
                const Color(0xFFEAF3F8),
                _primary,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      year.isEmpty ? vehicle : '$vehicle · $year',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    if (images.isNotEmpty)
                      Text(
                        '${images.length} photo${images.length == 1 ? '' : 's'} attached',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(order['created_at']?.toString()),
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    for (final assignment in assignments)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${assignment['shop_name'] ?? 'Spare shop'} · ${assignment['status'] ?? 'forwarded'}',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusPill((order['status'] ?? 'submitted').toString()),
            ],
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index].toString(),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 72,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (canManage) ...[
            const Divider(height: 20),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _editSpareRequest(order),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit request'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _cancelSpareRequest(order),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _editSpareRequest(Map<String, dynamic> order) async {
    final spare = TextEditingController(
      text: order['spare_name']?.toString() ?? '',
    );
    final year = TextEditingController(
      text: order['vehicle_year']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit spare request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: spare,
              decoration: const InputDecoration(labelText: 'Spare name'),
            ),
            TextFormField(
              controller: year,
              decoration: const InputDecoration(labelText: 'Vehicle year'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _spareService.updateRequest(order['id'] as int, {
        'spare_name': spare.text,
        'vehicle_year': year.text,
      });
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _cancelSpareRequest(Map<String, dynamic> order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('This will remove the request from your orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _spareService.cancelRequest(order['id'] as int);
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _emptyTab(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBox(icon, const Color(0xFFEAF3F8), _primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.4),
            ),
            if (title == 'No orders yet') ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _openTab(1),
                child: const Text('Find a used spare'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5EDF2)),
    ),
    child: child,
  );

  Widget _iconBox(IconData icon, Color background, Color foreground) =>
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: foreground, size: 23),
      );

  Widget _statusPill(String status, {bool dark = false}) {
    final label = _prettyStatus(status);
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.17)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? Colors.white : color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  bool _isInService(String status) =>
      !{'completed', 'delivered', 'closed'}.contains(status.toLowerCase());
  String _prettyStatus(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'delivered':
      case 'completed':
        return const Color(0xFF27805C);
      case 'reviewing':
      case 'active':
        return const Color(0xFFB87918);
      case 'closed':
        return const Color(0xFF71818B);
      default:
        return _primary;
    }
  }

  String _formatDate(String? value) {
    final date = DateTime.tryParse(value ?? '')?.toLocal();
    if (date == null) return 'Recently submitted';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _UsedSpareRequestForm extends StatefulWidget {
  const _UsedSpareRequestForm({
    required this.service,
    required this.onSubmitted,
  });

  final UsedSpareService service;
  final VoidCallback onSubmitted;

  @override
  State<_UsedSpareRequestForm> createState() => _UsedSpareRequestFormState();
}

class _UsedSpareRequestFormState extends State<_UsedSpareRequestForm> {
  static const _primary = Color(0xFF2E7BA6);
  final _formKey = GlobalKey<FormState>();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _spare = TextEditingController();
  final _picker = ImagePicker();
  final _catalogService = VehicleCatalogService();
  List<Map<String, dynamic>> _makes = [];
  Map<String, dynamic>? _selectedMake;
  Map<String, dynamic>? _selectedModel;
  List<XFile> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = [];
  List<Map<String, dynamic>> _makeSuggestions = [];
  List<Map<String, dynamic>> _modelSuggestions = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _restoreLostImage();
    _loadVehicleCatalog();
  }

  Future<void> _loadVehicleCatalog() async {
    try {
      final makes = await _catalogService.fetchMakes();
      if (mounted) setState(() => _makes = makes);
    } catch (_) {}
  }

  Future<void> _restoreLostImage() async {
    try {
      final response = await _picker.retrieveLostData();
      final files = response.files;
      if (files == null || files.isEmpty) return;
      final accepted = <XFile>[];
      final previews = <Uint8List>[];
      for (final file in files.take(6)) {
        final bytes = await file.readAsBytes();
        if (bytes.length <= 5 * 1024 * 1024) {
          accepted.add(file);
          previews.add(bytes);
        }
      }
      if (!mounted || accepted.isEmpty) return;
      setState(() {
        _selectedImages = accepted;
        _selectedImageBytes = previews;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _spare.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedMake == null || _selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a make and model from the list.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final created = await widget.service.createRequest(
        vehicleMake: _make.text,
        vehicleModel: _model.text,
        vehicleYear: _year.text,
        spareName: _spare.text,
        images: _selectedImages,
      );
      if (!mounted) return;
      final request = created['order'] is Map
          ? Map<String, dynamic>.from(created['order'] as Map)
          : created;
      final requestId = request['id']?.toString();
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: _primary,
            size: 34,
          ),
          title: const Text('Request placed'),
          content: Text(
            'Thanks! DigiAuto has received your spare request'
            '${requestId == null ? '' : ' #$requestId'}. '
            'Our team will check availability and get back to you soon. '
            'You can follow the status in Orders.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('View order status'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      widget.onSubmitted();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _chooseImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E0E6),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add a part photo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17384C),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: _primary,
                ),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: _primary,
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;
    try {
      List<XFile> images;
      if (source == ImageSource.gallery) {
        images = await _picker.pickMultiImage(
          imageQuality: 82,
          maxWidth: 1600,
          maxHeight: 1600,
        );
      } else {
        final image = await _picker.pickImage(
          source: source,
          imageQuality: 82,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        images = image == null ? <XFile>[] : <XFile>[image];
      }
      if (images.isEmpty) return;
      final accepted = <XFile>[];
      final previews = <Uint8List>[];
      for (final image in images) {
        if (_selectedImages.length + accepted.length >= 6) break;
        final bytes = await image.readAsBytes();
        if (bytes.length <= 5 * 1024 * 1024) {
          accepted.add(image);
          previews.add(bytes);
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedImages = [..._selectedImages, ...accepted];
        _selectedImageBytes = [..._selectedImageBytes, ...previews];
      });
      if (accepted.length < images.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Up to 6 photos are allowed, each up to 5 MB.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera or gallery.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const Text(
          'Find a used spare',
          style: TextStyle(
            color: Color(0xFF17384C),
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Share a few details and we’ll look for a matching part.',
          style: TextStyle(color: Color(0xFF71818B), height: 1.4),
        ),
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                title: 'Vehicle details',
                icon: Icons.directions_car_outlined,
                children: [
                  _catalogField(
                    controller: _make,
                    label: 'Vehicle make',
                    icon: Icons.factory_outlined,
                    suggestions: _makeSuggestions,
                    onChanged: (value) {
                      final match = _makes.where(
                        (make) =>
                            (make['name'] as String).toLowerCase() ==
                            value.trim().toLowerCase(),
                      );
                      _selectedMake = match.isEmpty ? null : match.first;
                      _selectedModel = null;
                      _model.clear();
                      _modelSuggestions = [];
                      _makeSuggestions = _suggest(_makes, value);
                    },
                    onSelected: (make) => setState(() {
                      _selectedMake = make;
                      _selectedModel = null;
                      _make.text = make['name'] as String;
                      _model.clear();
                      _makeSuggestions = [];
                      _modelSuggestions = [];
                    }),
                  ),
                  const SizedBox(height: 13),
                  _catalogField(
                    controller: _model,
                    label: 'Vehicle model',
                    icon: Icons.directions_car_filled_outlined,
                    suggestions: _modelSuggestions,
                    enabled: _selectedMake != null,
                    onChanged: (value) {
                      final models =
                          (_selectedMake?['models'] as List?)
                              ?.whereType<Map>()
                              .map((model) => Map<String, dynamic>.from(model))
                              .toList() ??
                          <Map<String, dynamic>>[];
                      final match = models.where(
                        (model) =>
                            (model['name'] as String).toLowerCase() ==
                            value.trim().toLowerCase(),
                      );
                      _selectedModel = match.isEmpty ? null : match.first;
                      _modelSuggestions = _suggest(models, value);
                    },
                    onSelected: (model) => setState(() {
                      _selectedModel = model;
                      _model.text = model['name'] as String;
                      _modelSuggestions = [];
                    }),
                  ),
                  const SizedBox(height: 13),
                  _field(
                    _year,
                    'Year (optional)',
                    'e.g. 2020',
                    Icons.calendar_today_outlined,
                    keyboard: TextInputType.number,
                    formatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) =>
                        (value ?? '').isEmpty ||
                            (value!.length == 4 && int.tryParse(value) != null)
                        ? null
                        : 'Enter a 4-digit year or leave it empty',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: 'Part you need',
                icon: Icons.settings_outlined,
                subtitle:
                    'Add a part name or attach a photo. Either one is required.',
                children: [
                  _field(
                    _spare,
                    'Spare part name',
                    'e.g. Left headlamp',
                    Icons.build_outlined,
                    validator: (value) =>
                        (value ?? '').trim().isEmpty && _selectedImages.isEmpty
                        ? 'Add a part name or at least one photo.'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  _imageAttachment(),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting ? 'Submitting…' : 'Request this spare',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageAttachment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImageBytes.isNotEmpty)
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImageBytes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes[index],
                      width: 94,
                      height: 94,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: IconButton.filled(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _selectedImages.removeAt(index);
                        _selectedImageBytes.removeAt(index);
                      }),
                      icon: const Icon(Icons.close, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _chooseImage,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 94,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              border: Border.all(color: const Color(0xFFD9E5EC)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: _primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedImages.isEmpty
                            ? 'Add part photos'
                            : 'Add another angle',
                        style: const TextStyle(
                          color: Color(0xFF17384C),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Choose multiple gallery photos or take a photo · up to 6',
                        style: TextStyle(
                          color: Color(0xFF71818B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF71818B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _suggest(
    List<Map<String, dynamic>> items,
    String query,
  ) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return [];
    return items
        .where((item) => (item['name'] as String).toLowerCase().contains(value))
        .take(7)
        .toList();
  }

  Widget _catalogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> suggestions,
    required ValueChanged<String> onChanged,
    required ValueChanged<Map<String, dynamic>> onSelected,
    bool enabled = true,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _field(
        controller,
        label,
        enabled ? 'Type to search' : 'Select make first',
        icon,
        enabled: enabled,
        onChanged: (value) {
          onChanged(value);
          setState(() {});
        },
        validator: (value) =>
            (value ?? '').trim().isEmpty ? 'This field is required.' : null,
      ),
      if (suggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          constraints: const BoxConstraints(maxHeight: 190),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE1E8ED)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final item = suggestions[index];
              return ListTile(
                dense: true,
                title: Text(item['name'] as String),
                onTap: () => onSelected(item),
              );
            },
          ),
        ),
    ],
  );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5EDF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _primary, size: 20),
            const SizedBox(width: 9),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF17384C),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF71818B),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter> formatters = const [],
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    inputFormatters: formatters,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    ),
    validator: validator,
    onChanged: onChanged,
    enabled: enabled,
  );

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'This field is required.' : null;
}

class UsedSpareOrderScreen extends StatelessWidget {
  const UsedSpareOrderScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order used spare')),
    body: _UsedSpareRequestForm(
      service: UsedSpareService(),
      onSubmitted: () => Navigator.of(context).pop(),
    ),
  );
}
