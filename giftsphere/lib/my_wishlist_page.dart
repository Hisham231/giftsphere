import 'package:flutter/material.dart';
import 'api_service.dart';

class MyWishlistPage extends StatefulWidget {
  const MyWishlistPage({super.key});

  @override
  State<MyWishlistPage> createState() => _MyWishlistPageState();
}

class _MyWishlistPageState extends State<MyWishlistPage> {
  bool _isLoading = true;
  List<dynamic> _myProducts = [];
  int? _wishlistId;

  @override
  void initState() {
    super.initState();
    _fetchMyWishlist();
  }

  // 1. جلب الأمنيات من الباكند
  Future<void> _fetchMyWishlist() async {
    setState(() => _isLoading = true);
    
    final result = await ApiService.getWishlists();
    
    if (result['success'] && result['data'].isNotEmpty) {
      // نأخذ أول قائمة أمنيات للمستخدم
      final wishlist = result['data'][0];
      _wishlistId = wishlist['id'];
      
      setState(() {
        _myProducts = wishlist['products'] ?? [];
      });
    }
    
    setState(() => _isLoading = false);
  }

  // 2. حذف منتج من الأمنيات
  Future<void> _removeProduct(int productId, int index) async {
    if (_wishlistId == null) return;

    // حفظ المنتج مؤقتاً في حال فشل الحذف
    final removedProduct = _myProducts[index];
    
    // تحديث الواجهة فوراً (تجربة مستخدم سريعة)
    setState(() {
      _myProducts.removeAt(index);
    });

    // إرسال الطلب للباكند
    final result = await ApiService.removeFromWishlist(productId, _wishlistId!);

    if (!result['success']) {
      // إذا فشل الحذف، نرجع المنتج للقائمة ونطلع إيرور
      setState(() {
        _myProducts.insert(index, removedProduct);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to remove product'), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from wishlist'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'My Wishlist',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF648DDB)))
            : _myProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Your wishlist is empty!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Go to the Market and add some gifts ❤️',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.separated(
                      itemCount: _myProducts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = _myProducts[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // صورة المنتج
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(product['image_url'] ?? 'https://via.placeholder.com/150'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // تفاصيل المنتج
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? 'Unknown Product',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'SAR ${product['price']}',
                                      style: const TextStyle(
                                        color: Color(0xFF648DDB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // زر الحذف
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _removeProduct(product['id'], index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}