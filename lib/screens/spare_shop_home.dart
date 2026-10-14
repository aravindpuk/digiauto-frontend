import 'dart:async';

import 'package:digiauto/screens/login.dart';
import 'package:digiauto/screens/spare_shop_inventory_form.dart';
import 'package:digiauto/services/spare_shop_service.dart';
import 'package:digiauto/utils/auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class SpareShopHomeScreen extends StatefulWidget {
  const SpareShopHomeScreen({super.key});

  @override
  State<SpareShopHomeScreen> createState() => _SpareShopHomeScreenState();
}

class _SpareShopHomeScreenState extends State<SpareShopHomeScreen> {
  static const _blue = Color(0xFF2E7BA6);
  static const _ink = Color(0xFF17384C);
  static const _muted = Color(0xFF71818B);
  static const _canvas = Color(0xFFF3F7FA);
  final _service = SpareShopService();
  final _search = TextEditingController();
  Timer? _searchDebounce;
  int _tab = 0;
  int? _editingId;
  int _formVersion = 0;
  Map<String, dynamic>? _editing;
  late Future<List<Map<String, dynamic>>> _inventoryFuture;
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  late final StreamSubscription<RemoteMessage> _messageSubscription;
  late final StreamSubscription<RemoteMessage> _openedMessageSubscription;

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
              '${notification.title ?? 'New spare order'}: ${notification.body ?? ''}',
            ),
            action: SnackBarAction(
              label: 'View orders',
              onPressed: () => setState(() => _tab = 2),
            ),
          ),
        );
      }
    });
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      _,
    ) {
      if (mounted)
        setState(() {
          _tab = 2;
          _load();
        });
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && mounted)
        setState(() {
          _tab = 2;
          _load();
        });
    });
  }

  void _load() {
    _inventoryFuture = _service.fetchInventory(query: _search.text);
    _ordersFuture = _service.fetchOrders();
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([
      _inventoryFuture.then((_) {}, onError: (_) {}),
      _ordersFuture.then((_) {}, onError: (_) {}),
    ]);
  }

  void _openAdd() => setState(() {
    _editing = null;
    _editingId = null;
    _formVersion++;
    _tab = 1;
  });

  void _openEdit(Map<String, dynamic> item) => setState(() {
    _editing = item;
    _editingId = item['id'] as int;
    _formVersion++;
    _tab = 1;
  });

  void _searchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(_load);
    });
  }

  void _saved() {
    setState(() {
      _editing = null;
      _editingId = null;
      _tab = 0;
      _load();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventory saved successfully.')),
    );
  }

  Future<void> _logout() async {
    final shopId = await getSpareShopId();
    if (shopId != null) {
      try {
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          'digi-spare-shop-$shopId',
        );
      } catch (_) {}
    }
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
    _searchDebounce?.cancel();
    _search.dispose();
    _messageSubscription.cancel();
    _openedMessageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: _blue),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spare Shop',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'INVENTORY & ORDERS',
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
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: _ink),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _inventoryTab(),
          SpareShopInventoryForm(
            key: ValueKey(_formVersion),
            service: _service,
            item: _editing,
            onSaved: _saved,
          ),
          _ordersTab(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _openAdd,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add spare'),
            )
          : null,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : Colors.white70,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: const Color(0xFFFF5733),
          indicatorColor: Colors.white.withValues(alpha: 0.18),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _tab == 1 ? 0 : (_tab == 2 ? 1 : 0),
          onDestinationSelected: (index) => setState(() {
            if (index == 0) {
              _tab = 0;
              _editing = null;
              _editingId = null;
            } else {
              _tab = 2;
            }
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryTab() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: TextField(
          controller: _search,
          textInputAction: TextInputAction.search,
          onChanged: _searchChanged,
          onSubmitted: (_) => setState(_load),
          decoration: InputDecoration(
            hintText: 'Search parts, make or model',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: () => setState(_load),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _inventoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return _message(
                'Could not load inventory',
                'Check your connection and try again.',
                Icons.wifi_off_rounded,
                onRetry: _refresh,
              );
            final items = snapshot.data ?? const [];
            if (items.isEmpty)
              return _message(
                'Your inventory starts here',
                'Add used spares with vehicle fitment, photos and MRP.',
                Icons.inventory_2_outlined,
                onRetry: _openAdd,
                actionLabel: 'Add a spare',
              );
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 11),
                itemBuilder: (context, index) => _inventoryCard(items[index]),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _inventoryCard(Map<String, dynamic> item) {
    final images = (item['images'] as List?) ?? const [];
    final imageUrl = images.isEmpty
        ? ''
        : images.first is Map
        ? (images.first as Map)['url']?.toString() ?? ''
        : images.first.toString();
    final year = (item['vehicle_year'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5ECF1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isEmpty
                ? Container(
                    width: 76,
                    height: 76,
                    color: const Color(0xFFEAF2F8),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: _blue,
                      size: 28,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 76,
                      height: 76,
                      color: const Color(0xFFEAF2F8),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: _muted,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['spare_name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['vehicle_make']} ${item['vehicle_model']}${year.isEmpty ? '' : ' · $year'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Text(
                  '₹ ${item['mrp']}',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) =>
                value == 'edit' ? _openEdit(item) : _remove(item),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Edit spare'),
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _remove(Map<String, dynamic> item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove spare?'),
        content: Text(
          '“${item['spare_name']}” will be removed from your inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _service.removeInventoryItem(item['id'] as int);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Spare removed.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    }
  }

  Widget _ordersTab() => _ShopOrdersView(
    service: _service,
    ordersFuture: _ordersFuture,
    onRefresh: _refresh,
  );

  Widget _message(
    String title,
    String subtitle,
    IconData icon, {
    required VoidCallback onRetry,
    String actionLabel = 'Try again',
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: _blue),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _ShopOrdersView extends StatefulWidget {
  const _ShopOrdersView({
    required this.service,
    required this.ordersFuture,
    required this.onRefresh,
  });
  final SpareShopService service;
  final Future<List<Map<String, dynamic>>> ordersFuture;
  final Future<void> Function() onRefresh;

  @override
  State<_ShopOrdersView> createState() => _ShopOrdersViewState();
}

class _ShopOrdersViewState extends State<_ShopOrdersView> {
  static const _blue = Color(0xFF1769AA);
  static const _ink = Color(0xFF17384C);
  static const _muted = Color(0xFF71818B);
  bool _updating = false;

  Future<void> _action(Map<String, dynamic> order, String action) async {
    setState(() => _updating = true);
    try {
      await widget.service.updateOrder(
        orderId: order['id'] as int,
        action: action,
      );
      if (!mounted) return;
      await widget.onRefresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept'
                ? 'Order accepted.'
                : action == 'reject'
                ? 'Order declined.'
                : 'Marked as delivered.',
          ),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: widget.ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const Center(
              child: Text('Could not load orders. Pull to refresh.'),
            );
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty)
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'Orders forwarded to your shop will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted),
                ),
              ),
            );
          return RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _orderCard(orders[index]),
            ),
          );
        },
      );

  Widget _orderCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString();
    final images =
        (order['images'] as List?)?.whereType<String>().toList() ?? [];
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
                  '${order['spare_name']?.toString().isNotEmpty == true ? order['spare_name'] : 'Spare request'}',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _status(status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${order['vehicle_make']} ${order['vehicle_model']}${(order['vehicle_year'] ?? '').toString().isEmpty ? '' : ' · ${order['vehicle_year']}'}',
            style: const TextStyle(color: _muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Customer: ${order['customer_name'] ?? 'DigiAuto customer'}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          if ((order['customer_mobile'] ?? '').toString().isNotEmpty)
            Text(
              'Contact: ${order['customer_mobile']}',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    images[i],
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 68,
                      child: Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if ((order['shop_note'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Your note: ${order['shop_note']}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          if (status == 'forwarded') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _updating
                        ? null
                        : () => _action(order, 'reject'),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _updating
                        ? null
                        : () => _action(order, 'accept'),
                    child: _updating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Accept order'),
                  ),
                ),
              ],
            ),
          ] else if (status == 'accepted') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _updating ? null : () => _action(order, 'delivered'),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Mark as delivered'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _status(String status) {
    final accepted = status == 'accepted' || status == 'delivered';
    final rejected = status == 'rejected';
    final color = rejected
        ? const Color(0xFFAA5149)
        : accepted
        ? const Color(0xFF27805C)
        : _blue;
    final label = status.isEmpty
        ? 'NEW'
        : status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
