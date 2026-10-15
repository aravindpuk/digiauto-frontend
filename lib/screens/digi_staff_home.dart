import 'dart:async';

import 'package:digiauto/screens/login.dart';
import 'package:digiauto/services/spare_shop_service.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class DigiStaffHomeScreen extends StatefulWidget {
  const DigiStaffHomeScreen({super.key});

  @override
  State<DigiStaffHomeScreen> createState() => _DigiStaffHomeScreenState();
}

class _DigiStaffHomeScreenState extends State<DigiStaffHomeScreen> {
  static const _blue = Color(0xFF2E7BA6);
  static const _ink = Color(0xFF17384C);
  static const _muted = Color(0xFF71818B);
  final _service = SpareShopService();
  late Future<Map<String, dynamic>> _dataFuture;
  late final StreamSubscription<RemoteMessage> _messageSubscription;
  late final StreamSubscription<RemoteMessage> _openedMessageSubscription;
  bool _forwarding = false;

  @override
  void initState() {
    super.initState();
    _load();
    _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
      if (!mounted) return;
      setState(_load);
      final notification = message.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${notification.title ?? 'Spare order update'}: ${notification.body ?? ''}',
            ),
          ),
        );
      }
    });
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      _,
    ) {
      if (mounted) setState(_load);
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && mounted) setState(_load);
    });
  }

  void _load() => _dataFuture = _service.fetchDigiStaffOrders();

  Future<void> _refresh() async {
    setState(_load);
    await _dataFuture.then((_) {}, onError: (_) {});
  }

  Future<void> _logout() async {
    // Keep the device subscribed so staff receive OS notifications while signed out.
    await clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _openedMessageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7FA),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF3F7FA),
      elevation: 0,
      title: const Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: _blue),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DigiAuto staff',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'SPARE REQUESTS',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  letterSpacing: 1.3,
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
        IconButton(
          tooltip: 'Sign out',
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: _ink),
        ),
      ],
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return _empty(
            'Could not load spare requests',
            'Check your connection and refresh.',
            Icons.wifi_off_outlined,
          );
        final data = snapshot.data ?? const {};
        final orders =
            (data['orders'] as List?)
                ?.whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList() ??
            <Map<String, dynamic>>[];
        final shops =
            (data['shops'] as List?)
                ?.whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList() ??
            <Map<String, dynamic>>[];
        if (orders.isEmpty)
          return _empty(
            'No spare requests yet',
            'Customer and garage requests will arrive here.',
            Icons.inventory_2_outlined,
          );
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _requestCard(orders[index], shops),
          ),
        );
      },
    ),
  );

  Widget _requestCard(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> shops,
  ) {
    final assignments =
        (order['assignments'] as List?)
            ?.whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList() ??
        <Map<String, dynamic>>[];
    final hasActive = assignments.any(
      (item) => item['status'] == 'forwarded' || item['status'] == 'accepted',
    );
    final closed = order['status'] == 'closed';
    final canForward = !hasActive && !closed;
    final images =
        (order['images'] as List?)?.whereType<String>().toList() ?? [];
    final year = (order['vehicle_year'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (order['spare_name'] ?? '').toString().isEmpty
                      ? 'Spare request'
                      : order['spare_name'].toString(),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _status((order['status'] ?? 'submitted').toString()),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${order['vehicle_make']} ${order['vehicle_model']}${year.isEmpty ? '' : ' · $year'}',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 4),
          Text(
            'From ${order['customer_name']} · ${order['customer_mobile']}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 66,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    images[i],
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 66,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (assignments.isNotEmpty) ...[
            const SizedBox(height: 13),
            const Divider(height: 1),
            for (final assignment in assignments)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: _blue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        assignment['shop_name'].toString(),
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _status((assignment['status'] ?? '').toString()),
                  ],
                ),
              ),
          ],
          if (canForward) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _forwarding ? null : () => _chooseShop(order, shops),
                icon: _forwarding
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: const Text('Forward to spare shop'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _chooseShop(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> shops,
  ) async {
    final matchData = order['matching_shops'] ?? order['available_shops'];
    final hasMatchData = matchData is List;
    final matchingShops = hasMatchData
        ? (matchData as List)
              .whereType<Map>()
              .map((shop) => Map<String, dynamic>.from(shop))
              .toList()
        : shops;
    if (matchingShops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasMatchData
                ? 'No shop has listed this spare yet.'
                : 'No spare shops are registered yet.',
          ),
        ),
      );
      return;
    }
    final shop = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose a spare shop',
                style: TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                hasMatchData
                    ? 'Shops that list “${order['spare_name'] ?? 'this spare'}”.'
                    : 'Forward “${order['spare_name'] ?? 'spare request'}” to a shop.',
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: matchingShops.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final entry = matchingShops[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEAF3F8),
                        child: Icon(Icons.storefront_outlined, color: _blue),
                      ),
                      title: Text(
                        entry['name'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        [
                          if ((entry['location'] ?? '').toString().isNotEmpty)
                            entry['location'].toString(),
                          if (hasMatchData)
                            'Has this spare'
                          else
                            '${entry['inventory_count'] ?? 0} listed spares',
                        ].join(' · '),
                      ),
                      onTap: () => Navigator.pop(context, entry),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (shop == null) return;
    setState(() => _forwarding = true);
    try {
      await _service.forwardOrder(
        requestId: order['id'] as int,
        shopId: shop['id'] as int,
      );
      if (!mounted) return;
      await _refresh();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Forwarded to ${shop['name']}.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _forwarding = false);
    }
  }

  Widget _status(String status) {
    final color =
        status == 'accepted' || status == 'delivered' || status == 'available'
        ? const Color(0xFF27805C)
        : status == 'rejected' || status == 'closed'
        ? const Color(0xFFAA5149)
        : const Color(0xFFAA751D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _empty(String title, String subtitle, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: _blue),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}
