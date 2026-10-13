import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aconita_mart_pos/core/theme/app_theme.dart';
import 'package:aconita_mart_pos/data/database/database_helper.dart';
import 'package:aconita_mart_pos/data/models/product.dart';
import 'package:aconita_mart_pos/data/models/member.dart';
import 'package:aconita_mart_pos/data/models/cart_item.dart';
import 'package:aconita_mart_pos/data/models/order.dart';
import 'package:aconita_mart_pos/data/models/order_item.dart';
import 'package:aconita_mart_pos/core/services/printer_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _curr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  List<Product> _products = [];
  Map<int, CartItem> _cart = {};
  Member? _selectedMember;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts({String? search}) async {
    setState(() => _isLoading = true);
    final products = await _db.getProducts(search: search);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok produk habis!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final isMember = _selectedMember != null;
      final price = product.getEffectivePrice(isMember);

      if (_cart.containsKey(product.id)) {
        final current = _cart[product.id]!;
        if (current.quantity < product.stock) {
          _cart[product.id!] = current.copyWith(quantity: current.quantity + 1);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak bisa melebihi stok yang tersedia!')),
          );
        }
      } else {
        _cart[product.id!] = CartItem(product: product, quantity: 1, unitPrice: price);
      }
    });
  }

  // ignore: unused_element
  void _updateQuantity(int productId, int delta) {
    setState(() {
      if (!_cart.containsKey(productId)) return;
      final item = _cart[productId]!;
      final newQty = item.quantity + delta;
      if (newQty <= 0) {
        _cart.remove(productId);
      } else if (newQty <= item.product.stock) {
        _cart[productId] = item.copyWith(quantity: newQty);
      }
    });
  }

  void _updateMemberPrices() {
    final isMember = _selectedMember != null;
    setState(() {
      _cart = _cart.map((key, item) {
        final newPrice = item.product.getEffectivePrice(isMember);
        return MapEntry(key, item.copyWith(unitPrice: newPrice));
      });
    });
  }

  double get _totalAmount => _cart.values.fold(0, (sum, i) => sum + i.subtotal);
  int get _totalItems => _cart.values.fold(0, (sum, i) => sum + i.quantity);

  void _showMemberSelector() async {
    final members = await _db.getMembers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pilih Anggota Koperasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_selectedMember != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedMember = null);
                        _updateMemberPrices();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset (Umum)', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.memberNo} ? Saldo: ${_curr.format(m.savingsBalance)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        setState(() => _selectedMember = m);
                        _updateMemberPrices();
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCheckoutDialog() {
    if (_cart.isEmpty) return;

    String paymentMethod = 'cash';
    final total = _totalAmount;
    final paidController = TextEditingController(text: total.toInt().toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final paid = double.tryParse(paidController.text) ?? 0;
            final change = paid - total;

            return AlertDialog(
              title: const Text('Pembayaran Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Belanja:'),
                          Text(_curr.format(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedMember != null) ...[
                      Text('Anggota: ${_selectedMember!.name} (${_selectedMember!.memberNo})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('Saldo Simpanan: ${_curr.format(_selectedMember!.savingsBalance)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                    ],
                    const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: paymentMethod,
                      items: [
                        const DropdownMenuItem(value: 'cash', child: Text('?? Tunai (Cash)')),
                        const DropdownMenuItem(value: 'qris', child: Text('?? QRIS')),
                        const DropdownMenuItem(value: 'transfer', child: Text('?? Transfer Bank')),
                        if (_selectedMember != null)
                          const DropdownMenuItem(value: 'potong_simpanan', child: Text('?? Potong Saldo Simpanan')),
                      ],
                      onChanged: (v) {
                        setModalState(() {
                          paymentMethod = v!;
                          if (paymentMethod == 'potong_simpanan') {
                            paidController.text = total.toInt().toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: paidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Uang Diterima (Rp)', border: OutlineInputBorder()),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),
                    if (paymentMethod == 'cash')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian:'),
                          Text(_curr.format(change < 0 ? 0 : change), style: TextStyle(fontWeight: FontWeight.bold, color: change < 0 ? Colors.red : Colors.green)),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppThemeColors.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (paymentMethod == 'potong_simpanan' && _selectedMember != null && _selectedMember!.savingsBalance < total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saldo simpanan tidak mencukupi!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    if (paid < total && paymentMethod == 'cash') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uang yang dibayarkan kurang!'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    await _completeTransaction(paymentMethod, paid, change < 0 ? 0 : change);
                  },
                  child: const Text('Selesai Bayar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeTransaction(String paymentMethod, double paidAmount, double changeAmount) async {
    final orderNo = 'TRX-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}';
    double totalProfit = 0;
    List<OrderItem> orderItems = [];

    for (final item in _cart.values) {
      totalProfit += item.profit;
      orderItems.add(OrderItem(
        productId: item.product.id!,
        productName: item.product.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        costPrice: item.product.costPrice,
        subtotal: item.subtotal,
        profit: item.profit,
      ));
    }

    final order = Order(
      orderNo: orderNo,
      memberId: _selectedMember?.id,
      memberName: _selectedMember?.name,
      orderDate: DateTime.now(),
      totalAmount: _totalAmount,
      finalAmount: _totalAmount,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      paymentStatus: 'paid',
      totalProfit: totalProfit,
      isSynced: false,
      items: orderItems,
    );

    await _db.createOrder(order, orderItems);

    setState(() {
      _cart.clear();
      _selectedMember = null;
    });
    _loadProducts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Transaksi $orderNo berhasil disimpan!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Cetak Struk',
          textColor: Colors.white,
          onPressed: () async {
            try {
              await PrinterService().printReceipt(order);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir POS Aconita Mart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppThemeColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_selectedMember != null ? Icons.verified_user : Icons.person_add_outlined),
            tooltip: 'Pilih Anggota Koperasi',
            onPressed: _showMemberSelector,
          ),
        ],
      ),
      body: Column(
        children: [
          // Member indicator banner
          if (_selectedMember != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Harga Khusus Anggota: ${_selectedMember!.name} (${_selectedMember!.memberNo})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () {
                      setState(() => _selectedMember = null);
                      _updateMemberPrices();
                    },
                  )
                ],
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama barang, SKU, atau scan barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadProducts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (val) => _loadProducts(search: val),
            ),
          ),

          // Product Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Tidak ada produk'))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          final isMember = _selectedMember != null;
                          final price = p.getEffectivePrice(isMember);
                          final inCartQty = _cart[p.id]?.quantity ?? 0;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _addToCart(p),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 75,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                          ? Image.network(
                                              p.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const Icon(Icons.inventory_2_outlined, size: 36, color: Colors.blueGrey),
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null) return child;
                                                return Center(
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      value: loadingProgress.expectedTotalBytes != null
                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                              loadingProgress.expectedTotalBytes!
                                                          : null,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : const Icon(Icons.shopping_bag_outlined, size: 38, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_curr.format(price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                                        Text('Stok: ${p.stock}', style: TextStyle(fontSize: 11, color: p.isLowStock ? Colors.red : Colors.grey)),
                                      ],
                                    ),
                                    if (inCartQty > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 6),
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        width: double.infinity,
                                        decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(6)),
                                        child: Text('Di Keranjang: $inCartQty', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Cart Summary Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total ($_totalItems item):', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(_curr.format(_totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _cart.isEmpty ? null : _showCheckoutDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
