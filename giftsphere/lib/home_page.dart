import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giftsphere/cart_page.dart';
import 'package:giftsphere/group_gift_page.dart';

import 'join_exchange_page.dart';
import 'my_secret_events_page.dart';
import 'market_page.dart';
import 'my_wishlist_page.dart';
import 'api_service.dart';
import 'notifications_page.dart';
import 'reminders_page.dart';
import 'account_page.dart';
import 'contact_selection_page.dart';
import 'gift_quiz_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _unreadNotificationsCount = 0;

  bool _isLoadingFeatured = true;
  List<dynamic> _featuredProducts = [];
  String _firstName = '';

  final PageController _bannerController =
      PageController(viewportFraction: 0.92);
  int _activeBannerIndex = 0;

  final List<Map<String, String>> firstRowRecipients = [
    {
      'name': 'Father',
      'image': 'assets/images/father.jpeg',
      'gender': 'male',
      'age': '45',
      'interests': 'practical',
    },
    {
      'name': 'Husband',
      'image': 'assets/images/husband.png',
      'gender': 'male',
      'age': '30',
      'interests': 'tech',
    },
    {
      'name': 'Friends',
      'image': 'assets/images/friends.png',
      'gender': 'any',
      'age': '25',
      'interests': 'friends',
    },
    {
      'name': 'Grandfather',
      'image': 'assets/images/grandfather.png',
      'gender': 'male',
      'age': '65',
      'interests': 'home',
    },
    {
      'name': 'Uncle',
      'image': 'assets/images/uncle.png',
      'gender': 'male',
      'age': '45',
      'interests': 'practical',
    },
    {
      'name': 'Children',
      'image': 'assets/images/children.png',
      'gender': 'any',
      'age': '12',
      'interests': 'games',
    },
  ];

  final List<Map<String, String>> secondRowRecipients = [
    {
      'name': 'Mother',
      'image': 'assets/images/mother.png',
      'gender': 'female',
      'age': '45',
      'interests': 'beauty',
    },
    {
      'name': 'Wife',
      'image': 'assets/images/wife.png',
      'gender': 'female',
      'age': '30',
      'interests': 'beauty',
    },
    {
      'name': 'Colleague',
      'image': 'assets/images/colleague.png',
      'gender': 'any',
      'age': '30',
      'interests': 'office',
    },
    {
      'name': 'Grandmother',
      'image': 'assets/images/grandmother.png',
      'gender': 'female',
      'age': '65',
      'interests': 'home',
    },
    {
      'name': 'Aunt',
      'image': 'assets/images/aunt.png',
      'gender': 'female',
      'age': '45',
      'interests': 'beauty',
    },
  ];

  final List<Map<String, dynamic>> _occasions = [
    {
      'title': 'Birthday',
      'apiValue': 'birthday',
      'icon': Icons.cake_outlined,
      'color': const Color(0xFFA35CFF),
    },
    {
      'title': 'Graduation',
      'apiValue': 'graduation',
      'icon': Icons.school_outlined,
      'color': const Color(0xFF648DDB),
    },
    {
      'title': 'Eid',
      'apiValue': 'eid',
      'icon': Icons.nightlight_outlined,
      'color': const Color(0xFF53B175),
    },
    {
      'title': 'Wedding',
      'apiValue': 'wedding',
      'icon': Icons.favorite_border,
      'color': Colors.pinkAccent,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    await Future.wait([
      _loadUnreadNotificationsCount(),
      _loadFeaturedProducts(),
      _loadUserName(),
    ]);
  }

  Future<void> _loadUserName() async {
    final profileResult = await ApiService.getCurrentUserProfile();

    if (!mounted) return;

    if (profileResult['success']) {
      final data = profileResult['data'];

      setState(() {
        _firstName = data['first_name']?.toString() ?? '';
      });
    } else {
      final userData = await ApiService.getUserData();

      if (!mounted) return;

      setState(() {
        _firstName = userData?['first_name']?.toString() ?? '';
      });
    }
  }

  Future<void> _loadFeaturedProducts() async {
    setState(() => _isLoadingFeatured = true);

    final result = await ApiService.getProducts();

    if (!mounted) return;

    if (result['success']) {
      final allProducts = result['products'] as List<dynamic>? ?? [];

      setState(() {
        _featuredProducts = allProducts
            .where((product) => product['is_featured'] == true)
            .toList();
        _isLoadingFeatured = false;
      });
    } else {
      setState(() {
        _featuredProducts = [];
        _isLoadingFeatured = false;
      });
    }
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final result = await ApiService.getNotifications();

    if (!mounted) return;

    if (result['success']) {
      final notifications = result['data'] as List<dynamic>? ?? [];

      final unreadCount = notifications.where((notification) {
        return notification['is_read'] == false;
      }).length;

      setState(() {
        _unreadNotificationsCount = unreadCount;
      });
    }
  }

  void _openMarketWithFilters({
    String? occasion,
    String? targetGender,
    String? recipientAge,
    String? interests,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketPage(
          initialOccasion: occasion,
          initialTargetGender: targetGender,
          initialRecipientAge: recipientAge,
          initialInterests: interests,
          initialTitle: title,
        ),
      ),
    );
  }

  void _showCreateExchangeDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController budgetController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Secret Exchange 🎁',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set a name and a budget limit for this gift exchange.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'Event Name (e.g., Office Party)',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Budget limit',
                  suffixText: 'SAR',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final String title = titleController.text.trim();
                    final String budgetText = budgetController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter an event name'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    if (budgetText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a budget'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    final double? budget = double.tryParse(budgetText);
                    if (budget == null) return;

                    showDialog(
                      context: bottomSheetContext,
                      barrierDismissible: false,
                      builder: (BuildContext dialogContext) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFA35CFF),
                          ),
                        );
                      },
                    );

                    final result = await ApiService.createExchange(
                      title,
                      budget,
                      <int>[],
                    );

                    if (bottomSheetContext.mounted) {
                      Navigator.of(
                        bottomSheetContext,
                        rootNavigator: true,
                      ).pop();
                    }

                    if (result['success']) {
                      if (bottomSheetContext.mounted) {
                        Navigator.pop(bottomSheetContext);
                      }

                      String inviteCode = '';
                      final respData = result['data'];

                      if (respData != null) {
                        if (respData['data'] != null &&
                            respData['data']['invite_code'] != null) {
                          inviteCode =
                              respData['data']['invite_code'].toString();
                        } else if (respData['invite_code'] != null) {
                          inviteCode = respData['invite_code'].toString();
                        }
                      }

                      if (inviteCode.isNotEmpty) {
                        _showSuccessCodeDialog(inviteCode, title);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Created but invite code missing!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'Error creating event',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA35CFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create & Get Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessCodeDialog(String eventCode, String eventTitle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Center(
            child: Text(
              'Event Created! 🎊',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share this code with your friends so they can join the exchange:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFA35CFF),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      eventCode,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Color(0xFFA35CFF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: eventCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA35CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                Icons.people,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'Invite Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactSelectionPage(
                      inviteCode: eventCode,
                      exchangeTitle: eventTitle,
                      isSecretExchange: true,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showSecretExchangeOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Secret Exchange',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'What would you like to do?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showCreateExchangeDialog(context);
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFFA35CFF),
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Be the organizer and invite friends',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const JoinExchangePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF53B175),
                        child: Icon(Icons.group_add, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Existing Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Enter an invite code from a friend',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MySecretEventsPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF648DDB),
                        child: Icon(Icons.history, color: Colors.white),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Secret Events',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'View events and your assigned person',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getServices() {
    return [
      {
        'title': 'Group Gift',
        'icon': Icons.card_giftcard,
        'color': const Color(0xFFA35CFF),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GroupGiftPage(),
            ),
          );
        },
      },
      {
        'title': 'Gift Quiz',
        'icon': Icons.quiz_outlined,
        'color': const Color(0xFF648DDB),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GiftQuizPage(),
            ),
          );
        },
      },
      {
        'title': 'Secret Exchange',
        'icon': Icons.shuffle,
        'color': const Color(0xFF53B175),
        'onTap': () {
          _showSecretExchangeOptions(context);
        },
      },
    ];
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CartPage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MarketPage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountPage()),
      ).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildWelcomeSection(),
                const SizedBox(height: 20),
                _buildAdBanner(),
                const SizedBox(height: 24),
                _buildFeaturedGiftsSection(),
                const SizedBox(height: 24),
                _buildServicesSection(),
                const SizedBox(height: 24),
                _buildOccasionsSection(),
                const SizedBox(height: 24),
                _buildRecipientsSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RemindersPage()),
              );
            },
            child: _buildHeaderIcon(
              icon: Icons.calendar_month_outlined,
              iconColor: const Color(0xFF648DDB),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyWishlistPage()),
              );
            },
            child: _buildHeaderIcon(
              icon: Icons.favorite_border,
              iconColor: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
              );
              _loadUnreadNotificationsCount();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildHeaderIcon(
                  icon: Icons.notifications_outlined,
                  iconColor: Colors.black54,
                ),
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadNotificationsCount > 9
                            ? '9+'
                            : '$_unreadNotificationsCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  Widget _buildWelcomeSection() {
    final displayName = _firstName.trim().isNotEmpty ? _firstName : 'there';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $displayName 👋',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Find the perfect gift today',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

 Widget _buildAdBanner() {
  final List<Map<String, dynamic>> banners = [
    {
      'image': 'assets/images/qattah_banner.png',
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GroupGiftPage(),
          ),
        );
      },
    },
    {
      'image': 'assets/images/gift_quiz_banner.png',
      'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GiftQuizPage(),
          ),
        );
      },
    },
    {
      'image': 'assets/images/gift_exchange_banner.png',
      'onTap': () {
        _showSecretExchangeOptions(context);
      },
    },
  ];

  return Column(
    children: [
      SizedBox(
        height: 205, // مهم: لأن الصور 16:9
        child: PageView.builder(
          controller: _bannerController,
          itemCount: banners.length,
          onPageChanged: (index) {
            setState(() {
              _activeBannerIndex = index;
            });
          },
          itemBuilder: (context, index) {
            final banner = banners[index];

            return GestureDetector(
              onTap: banner['onTap'] as VoidCallback,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  banner['image'] as String,
                  fit: BoxFit.cover, // بدل fill عشان ما تنضغط
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFEDE9FF),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFFA35CFF),
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      _buildBannerDots(banners.length),
    ],
  );
}

  Widget _buildBannerDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == _activeBannerIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFA35CFF)
                : const Color(0xFFD8D8E8),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturedGiftsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Featured Gifts',
          showSeeAll: true,
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MarketPage()),
            );
          },
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 235,
          child: _isLoadingFeatured
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFA35CFF),
                  ),
                )
              : _featuredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No featured gifts yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _featuredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final product = _featuredProducts[index];
                        return _buildFeaturedProductCard(product);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductCard(dynamic product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarketPage()),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                width: double.infinity,
                height: 125,
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  product['image_url'] ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_outlined),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'SAR ${product['price']}',
                    style: const TextStyle(
                      color: Color(0xFF648DDB),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 30,
                    child: ElevatedButton(
                      onPressed: () async {
                        await ApiService.addToCart(
                          product as Map<String, dynamic>,
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} added to cart!'),
                            backgroundColor: const Color(0xFF53B175),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648DDB),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: 'Services'),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _getServices()
                .map(
                  (service) => _buildServiceCard(
                    service['title'] as String,
                    service['icon'] as IconData,
                    service['color'] as Color,
                    service['onTap'] as VoidCallback,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccasionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: 'Shop by Occasion'),
        const SizedBox(height: 14),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _occasions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final occasion = _occasions[index];

              return GestureDetector(
                onTap: () {
                  _openMarketWithFilters(
                    occasion: occasion['apiValue'],
                    title: '${occasion['title']} Gifts',
                  );
                },
                child: Container(
                  width: 125,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        occasion['icon'] as IconData,
                        color: occasion['color'] as Color,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        occasion['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title: 'Who is the gift for?'),
        const SizedBox(height: 14),
        _buildHorizontalRecipientsList(firstRowRecipients),
        const SizedBox(height: 15),
        _buildHorizontalRecipientsList(secondRowRecipients),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    bool showSeeAll = false,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFFA35CFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRecipientsList(List<Map<String, String>> items) {
    return SizedBox(
      height: 115,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 18),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          return _buildRecipientCard(
            item['name']!,
            item['image']!,
            onTap: () {
              _openMarketWithFilters(
                targetGender: item['gender'],
                recipientAge: item['age'],
                interests: item['interests'],
                title: 'Gifts for ${item['name']}',
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecipientCard(
    String name,
    String imagePath, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6FA),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.person,
                    size: 34,
                    color: Color(0xFF648DDB),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1D1E20),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.shopping_cart_rounded, 'Cart'),
            _buildNavItem(2, Icons.storefront_rounded, 'Market'),
            _buildNavItem(3, Icons.person_rounded, 'Account'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFA35CFF).withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFFA35CFF)
                  : const Color(0xFF7C7C7C),
              size: 23,
            ),
            if (isSelected) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFA35CFF),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}