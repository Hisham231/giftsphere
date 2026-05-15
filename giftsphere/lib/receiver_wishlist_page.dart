import 'package:flutter/material.dart';
import 'api_service.dart';

class ReceiverWishlistPage extends StatefulWidget {
  final int receiverId;
  final String receiverName;

  const ReceiverWishlistPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ReceiverWishlistPage> createState() => _ReceiverWishlistPageState();
}

class _ReceiverWishlistPageState extends State<ReceiverWishlistPage> {
  bool _isLoading = true;
  List<dynamic> _receiverProducts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReceiverWishlist();
  }

  Future<void> _fetchReceiverWishlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _receiverProducts = [];
    });

    final result = await ApiService.getWishlists();

    if (!mounted) return;

    if (result['success'] && result['data'] != null) {
      final List<dynamic> allWishlists = result['data'];

      final List<dynamic> receiverWishlists = allWishlists.where((wishlist) {
        final userObj = wishlist['user'];
        if (userObj == null) return false;

        final userId = int.tryParse(userObj['id'].toString());
        return userId == widget.receiverId;
      }).toList();

      final Map<int, dynamic> uniqueProducts = {};

      for (final wishlist in receiverWishlists) {
        final products = wishlist['products'] as List<dynamic>? ?? [];

        for (final product in products) {
          final productId = int.tryParse(product['id'].toString());

          if (productId != null) {
            uniqueProducts[productId] = product;
          }
        }
      }

      setState(() {
        _receiverProducts = uniqueProducts.values.toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load wishlist';
        _isLoading = false;
      });
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
        title: Text(
          "${widget.receiverName}'s Wishlist",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _fetchReceiverWishlist,
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFFA35CFF),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF648DDB),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchReceiverWishlist,
                    color: const Color(0xFFA35CFF),
                    child: _receiverProducts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.65,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        size: 80,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No items yet!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                        ),
                                        child: Text(
                                          '${widget.receiverName} has no shared wishlist items yet.\nPull down or tap refresh to check again.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _receiverProducts.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final product = _receiverProducts[index];

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
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        product['image_url'] ??
                                            'https://via.placeholder.com/150',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['name'] ??
                                                'Unknown Product',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
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