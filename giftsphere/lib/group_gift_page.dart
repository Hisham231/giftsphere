import 'package:flutter/material.dart';
import 'api_service.dart';
import 'qattah_detail_page.dart';
import 'notifications_page.dart';
import 'contact_selection_page.dart';

class GroupGiftPage extends StatefulWidget {
  const GroupGiftPage({super.key});

  @override
  State<GroupGiftPage> createState() => _GroupGiftPageState();
}

class _GroupGiftPageState extends State<GroupGiftPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> _qattahs = [];
  bool _isLoadingQattahs = true;

  List<dynamic> _products = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // ✅ ضفنا await عشان ما يستعجل ويحملهم صح
    await _loadQattahs();
    await _loadProducts();
  }

  Future<void> _loadQattahs() async {
    setState(() => _isLoadingQattahs = true);

    final userData = await ApiService.getUserData();
    final String rawPhone = userData?['phone']?.toString() ?? '';
    final String myPhone =
        rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;

    final myResult = await ApiService.getQattahs(mine: true);
    final allResult = await ApiService.getQattahs();

    if (!mounted) return;

    final Map<int, dynamic> merged = {};

    // 1. القطات التي أنشأتها أنت
    if (myResult['success'] && myResult['data'] is List) {
      for (final q in myResult['data']) {
        merged[q['id']] = q;
      }
    }

    // 2. القطات التي أنت مشارك فيها فقط
    if (allResult['success'] && allResult['data'] is List) {
      for (final q in allResult['data']) {
        final participants = q['participant_details'] as List<dynamic>? ?? [];

        final bool isMeParticipant = participants.any((p) {
          final user = p['user'] ?? {};
          final String participantPhoneRaw =
              user['phone_number']?.toString() ?? '';
          final String participantPhone = participantPhoneRaw.startsWith('0')
              ? participantPhoneRaw.substring(1)
              : participantPhoneRaw;

          final String status = p['status']?.toString().toUpperCase() ?? '';

          return participantPhone == myPhone &&
              (status == 'ACCEPTED' || status == 'INVITED');
        });

        if (isMeParticipant) {
          merged[q['id']] = q;
        }
      }
    }

    setState(() {
      _isLoadingQattahs = false;
      _qattahs = merged.values.toList();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    final result = await ApiService.getProducts();
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = false;
      if (result['success']) _products = result['products'];
    });
  }

  // ✅ الحل: حفظ pageContext قبل دخول الـ builder
  void _createQattah(int productId, String productName) {
  final pageContext = context;

  showDialog(
    context: pageContext,
    builder: (dialogContext) {
      final titleController = TextEditingController();
      final bankNameController = TextEditingController();
      final ibanController = TextEditingController();
      final accountHolderController = TextEditingController();

      bool isCreating = false;

      String cleanIban(String value) {
        return value.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
      }

      bool isValidSaudiIban(String value) {
        final cleaned = cleanIban(value);
        return RegExp(r'^SA\d{22}$').hasMatch(cleaned);
      }

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Create Qattah',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starting a Qattah for: $productName'),
                  const SizedBox(height: 16),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Qattah Title (Optional)',
                      hintText: 'e.g., Birthday Gift for Ali',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Banking Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Required so participants know where to transfer.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'e.g., Al Rajhi',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: ibanController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'IBAN',
                      hintText: 'SA3915000999103143430001',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: accountHolderController,
                    decoration: InputDecoration(
                      labelText: 'Account Holder Name',
                      hintText: 'e.g., Hisham Khalid',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA35CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isCreating
                    ? null
                    : () async {
                        final bankName = bankNameController.text.trim();
                        final iban = cleanIban(ibanController.text.trim());
                        final accountHolder =
                            accountHolderController.text.trim();

                        if (bankName.isEmpty ||
                            iban.isEmpty ||
                            accountHolder.isEmpty) {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete your banking information.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        if (!isValidSaudiIban(iban)) {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Invalid Saudi IBAN. It must start with SA and contain 24 characters.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        final qattahTitle =
                            titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : 'Qattah for $productName';

                        setDialogState(() => isCreating = true);

                        final bankResult = await ApiService.updateBankingInfo(
                          bankName: bankName,
                          iban: iban,
                          accountHolderName: accountHolder,
                        );

                        if (!mounted) return;

                        if (bankResult['success'] != true) {
                          setDialogState(() => isCreating = false);

                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                bankResult['message'] ??
                                    'Failed to update banking information',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final result = await ApiService.createQattah(
                          qattahTitle,
                          productId,
                        );

                        if (!mounted) return;

                        setDialogState(() => isCreating = false);
                        Navigator.pop(dialogContext);

                        if (result['success']) {
                          final newQattah = result['data'];
                          final String code =
                              newQattah['invite_code'].toString();

                          _loadQattahs();
                          _tabController.animateTo(0);

                          showDialog(
                            context: pageContext,
                            builder: (inviteDialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              title: const Text(
                                'Qattah Created! 🎉',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA35CFF)
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFA35CFF)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.confirmation_number,
                                          color: Color(0xFFA35CFF),
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Code: $code',
                                          style: const TextStyle(
                                            color: Color(0xFFA35CFF),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Would you like to invite friends from your contacts?',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(inviteDialogContext),
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
                                    Navigator.pop(inviteDialogContext);

                                    Navigator.push(
                                      pageContext,
                                      MaterialPageRoute(
                                        builder: (_) => ContactSelectionPage(
                                          inviteCode: code,
                                          qattahTitle: qattahTitle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        } else {
                          setState(() => _isLoadingQattahs = false);

                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ?? 'Failed to create Qattah',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

  void _showJoinDialog() {
    final pageContext = context;
    showDialog(
      context: pageContext,
      builder: (dialogContext) {
        final codeController = TextEditingController();
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Join Qattah 🤝',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: codeController,
            decoration: InputDecoration(
              labelText: 'Invite Code',
              hintText: 'Enter 8-digit code',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA35CFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.isEmpty) return;

                Navigator.pop(dialogContext);
                setState(() => _isLoadingQattahs = true);

                final result = await ApiService.joinQattah(code);
                if (!mounted) return;

                if (result['success']) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                        content: Text('Qattah found! Redirecting... ⏳'),
                        backgroundColor: Colors.blue),
                  );
                  _tabController.animateTo(0);
                  _loadQattahs();

                  int? qattahId;

                  if (result['data'] != null && result['data'] is Map) {
                    final data = result['data'];

                    if (data['qattah'] != null && data['qattah'] is Map) {
                      qattahId = data['qattah']['id'];
                    } else {
                      qattahId = data['id'];
                    }
                  }

                  if (qattahId != null) {
                    Navigator.push(
                      pageContext,
                      MaterialPageRoute(
                          builder: (_) =>
                              QattahDetailPage(qattahId: qattahId!)),
                    ).then((_) => _loadQattahs());
                  }
                } else {
                  setState(() => _isLoadingQattahs = false);
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                        content:
                            Text(result['message'] ?? 'Failed to find Qattah'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Find Qattah',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Group Gifts',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none,
                color: Colors.black, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ).then((_) => _loadQattahs());
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF53B175),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF53B175),
          tabs: const [
            Tab(text: 'Active Qattahs'),
            Tab(text: 'Start New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveQattahsTab(),
          _buildStartNewQattahTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showJoinDialog,
              backgroundColor: const Color(0xFFA35CFF),
              icon: const Icon(Icons.group_add),
              label: const Text('Join with Code'),
            )
          : null,
    );
  }

  Widget _buildActiveQattahsTab() {
    if (_isLoadingQattahs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_qattahs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.money_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active Qattahs found',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadQattahs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _qattahs.length,
        itemBuilder: (context, index) {
          final qattah = _qattahs[index];
          final product = qattah['product'];
          final target =
              double.tryParse(qattah['target_amount'].toString()) ?? 1.0;
          final collected =
              double.tryParse(qattah['collected_amount'].toString()) ?? 0.0;
          final progress = (collected / target).clamp(0.0, 1.0);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => QattahDetailPage(qattahId: qattah['id'])),
                ).then((_) => _loadQattahs());
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product['image_url'] ??
                                'https://via.placeholder.com/80',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(qattah['title'] ?? 'Qattah',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Code: ${qattah['invite_code']}',
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: qattah['status'] == 'ACTIVE'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            qattah['status'],
                            style: TextStyle(
                              color: qattah['status'] == 'ACTIVE'
                                  ? Colors.green
                                  : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xFF53B175),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$collected SAR collected',
                            style: const TextStyle(
                                color: Color(0xFF53B175),
                                fontWeight: FontWeight.bold)),
                        Text('Goal: $target SAR',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartNewQattahTab() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_products.isEmpty) {
      return const Center(child: Text('No products available.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product['image_url'] ?? 'https://via.placeholder.com/150',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${product['price']} SAR',
                        style: const TextStyle(
                            color: Color(0xFFA35CFF),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            _createQattah(product['id'], product['name']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF53B175),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Start Qattah',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
