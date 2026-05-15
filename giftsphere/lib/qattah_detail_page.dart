import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class QattahDetailPage extends StatefulWidget {
  final int qattahId;

  const QattahDetailPage({super.key, required this.qattahId});

  @override
  State<QattahDetailPage> createState() => _QattahDetailPageState();
}

class _QattahDetailPageState extends State<QattahDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _qattahData;
  bool _isProcessingAction = false;
  String _myPhone = '';
  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);

    final userData = await ApiService.getUserData();
    final rawPhone = userData?['phone']?.toString() ?? '';
    final currentPhone =
        rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;

    final result = await ApiService.getQattahDetail(widget.qattahId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _myPhone = currentPhone;

        if (result['success']) {
          _qattahData = result['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to load details'),
            ),
          );
        }
      });
    }
  }

  // ✅ قبول الدعوة
  Future<void> _acceptInvite() async {
    setState(() => _isProcessingAction = true);
    final result = await ApiService.acceptQattahInvite(widget.qattahId);

    if (!mounted) return;

    setState(() => _isProcessingAction = false);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Joined Qattah successfully! ✅'),
            backgroundColor: Colors.green),
      );
      _loadDetails();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message'] ?? 'Failed to join'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ❌ رفض الدعوة
  Future<void> _rejectInvite() async {
    setState(() => _isProcessingAction = true);
    final result = await ApiService.rejectQattahInvite(widget.qattahId);

    if (!mounted) return;

    setState(() => _isProcessingAction = false);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invitation Rejected ❌'),
            backgroundColor: Colors.orange),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result['message'] ?? 'Failed to reject'),
            backgroundColor: Colors.red),
      );
    }
  }

  // 🚪 الانسحاب (للموافقين مسبقاً)
  Future<void> _handleLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Qattah?'),
        content: const Text('Are you sure you want to leave this Qattah?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessingAction = true);
      final result = await ApiService.leaveQattah(widget.qattahId);

      if (!mounted) return;
      setState(() => _isProcessingAction = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Successfully left the Qattah.'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to leave'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // 💸 نافذة الدفع
  void _showPledgeDialog(double remainingAmount) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (bottomSheetContext) {
          return StatefulBuilder(builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contribute to Qattah 💸',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Remaining Amount: $remainingAmount SAR',
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (SAR)',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      labelText: 'Message (Optional)',
                      hintText: 'e.g., Happy Graduation!',
                      filled: true,
                      fillColor: const Color(0xFFF5F6FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amountText = amountController.text.trim();
                              if (amountText.isEmpty) return;

                              final amount = double.tryParse(amountText);
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please enter a valid amount')));
                                return;
                              }
                              if (amount > remainingAmount) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Amount exceeds remaining balance!')));
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final result = await ApiService.makePledge(
                                  widget.qattahId, amount,
                                  message: messageController.text.trim());

                              if (!mounted) return;
                              Navigator.pop(context);

                              if (result['success']) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Contribution added successfully! 🎉'),
                                      backgroundColor: Colors.green),
                                );
                                _loadDetails();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(result['message'] ??
                                          'Failed to add contribution'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF53B175),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Pay Now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_qattahData == null)
      return const Scaffold(body: Center(child: Text('Failed to load data.')));

    final product = _qattahData!['product'];
    final pledges = _qattahData!['pledges'] as List<dynamic>? ?? [];
    final paymentInfo =
        _qattahData!['payment_info'] as Map<String, dynamic>? ?? {};
    final paymentMethodNote =
        _qattahData!['payment_method_note']?.toString() ?? '';

    // 👥 استخراج قائمة المشاركين وحالاتهم
    final participants =
        _qattahData!['participant_details'] as List<dynamic>? ?? [];

    // استخراج حالة المستخدم الحالي
    final organizer = _qattahData!['organizer'] ?? {};

    final organizerPhoneRaw = organizer['phone_number']?.toString() ?? '';
    final organizerPhone = organizerPhoneRaw.startsWith('0')
        ? organizerPhoneRaw.substring(1)
        : organizerPhoneRaw;

    final bool isOrganizer = _myPhone.isNotEmpty && organizerPhone == _myPhone;

    String myStatus = '';

    for (final participant in participants) {
      final user = participant['user'] ?? {};
      final participantPhoneRaw = user['phone_number']?.toString() ?? '';
      final participantPhone = participantPhoneRaw.startsWith('0')
          ? participantPhoneRaw.substring(1)
          : participantPhoneRaw;

      if (participantPhone == _myPhone) {
        myStatus = participant['status']?.toString().toUpperCase() ?? '';
        break;
      }
    }

    // استخراج ذكي لاسم المنظم واسم المستلم
    final orgName = organizer['first_name']?.toString().isNotEmpty == true
        ? organizer['first_name']
        : (organizer['phone_number'] ?? 'Organizer');

    final recipient = _qattahData!['recipient'];
    String? recipientName;
    if (recipient != null) {
      recipientName = recipient['first_name']?.toString().isNotEmpty == true
          ? recipient['first_name']
          : recipient['phone_number'];
    }

    // عنوان البطاقة العلوية
    final String giftTitle = recipientName != null
        ? "🎁 Gift for $recipientName"
        : "🎁 ${_qattahData!['title'] ?? 'Surprise Gift'}";

    final target =
        double.tryParse(_qattahData!['target_amount'].toString()) ?? 1.0;
    final collected =
        double.tryParse(_qattahData!['collected_amount'].toString()) ?? 0.0;
    final remaining = target - collected;
    final progress = (collected / target).clamp(0.0, 1.0);
    final isCompleted = _qattahData!['status'] == 'COMPLETED';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Qattah Preview',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!isOrganizer && myStatus == 'ACCEPTED')
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              tooltip: 'Leave Qattah',
              onPressed: _isProcessingAction ? null : _handleLeave,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA35CFF).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: const Color(0xFFA35CFF).withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              giftTitle,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFA35CFF)),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Organized by: $orgName',
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          product['image_url'] ??
                              'https://via.placeholder.com/200',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 50)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product['name'] ?? 'Product',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 4),
                      Text(
                        'Price: ${product['price']} SAR',
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),
                      // 📋 زر نسخ الكود (الجديد)
                      GestureDetector(
                        onTap: () async {
                          final code = _qattahData!['invite_code'].toString();
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Code $code copied! 📋'),
                                  backgroundColor: Colors.green),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.copy,
                                  size: 18, color: Colors.black54),
                              const SizedBox(width: 8),
                              Text(
                                'Code: ${_qattahData!['invite_code']}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        color: isCompleted
                            ? Colors.green
                            : const Color(0xFF53B175),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$collected SAR collected',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF53B175))),
                          Text('$target SAR Goal',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOrganizer || myStatus == 'ACCEPTED')
                  _buildPaymentInfoSection(
                    paymentInfo: paymentInfo,
                    paymentMethodNote: paymentMethodNote,
                  ),

                // 👥 قائمة المشاركين وحالاتهم (الجديدة)
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Participants (${participants.length})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                if (participants.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('No participants yet.',
                            style: TextStyle(color: Colors.grey))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final part = participants[index];
                      final user = part['user'] ?? {};
                      final firstName = user['first_name']?.toString() ?? '';
                      final phone = user['phone_number']?.toString() ?? 'User';
                      final displayName =
                          firstName.isNotEmpty ? firstName : phone;

                      // تحديد لون الحالة
                      final statusStr =
                          part['status']?.toString().toUpperCase() ?? 'INVITED';
                      Color statusColor = Colors.grey;
                      if (statusStr == 'ACCEPTED') statusColor = Colors.green;
                      if (statusStr == 'REJECTED') statusColor = Colors.red;
                      if (statusStr == 'LEFT') statusColor = Colors.orange;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFF5F6FA),
                            child: Text(displayName[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Color(0xFFA35CFF),
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusStr,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // 💸 قائمة المساهمات (المدفوعات)
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Contributions (${pledges.length})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                if (pledges.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('No contributions yet.',
                            style: TextStyle(color: Colors.grey))),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pledges.length,
                    itemBuilder: (context, index) {
                      final pledge = pledges[index];
                      final user = pledge['user'];
                      final firstName = user['first_name']?.toString() ?? '';
                      final phone = user['phone_number']?.toString() ?? 'User';
                      final displayName =
                          firstName.isNotEmpty ? firstName : phone;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFF5F6FA),
                            child: Text(displayName[0].toUpperCase(),
                                style: const TextStyle(
                                    color: Color(0xFFA35CFF),
                                    fontWeight: FontWeight.bold)),
                          ),
                          title: Text(displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: pledge['message'] != null &&
                                  pledge['message'].toString().isNotEmpty
                              ? Text(pledge['message'])
                              : null,
                          trailing: Text('${pledge['amount']} SAR',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF53B175),
                                  fontSize: 16)),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isProcessingAction)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          _buildBottomAction(isCompleted, remaining, myStatus, isOrganizer),
    );
  }

  Widget _buildBottomAction(
    bool isCompleted,
    double remaining,
    String myStatus,
    bool isOrganizer,
  ) {
    if (isCompleted) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Qattah Completed! 🎉',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // المنظم أو المشارك المقبول يشوف زر Contribute
    if (isOrganizer || myStatus == 'ACCEPTED') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed:
                _isProcessingAction ? null : () => _showPledgeDialog(remaining),
            icon: const Icon(Icons.payment, color: Colors.white),
            label: const Text(
              'Contribute',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF53B175),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      );
    }

    // فقط المدعو فعلًا يشوف قبول / رفض
    if (myStatus == 'INVITED') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessingAction ? null : _rejectInvite,
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text(
                  'Decline',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessingAction ? null : _acceptInvite,
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'Join Qattah',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF53B175),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPaymentInfoSection({
    required Map<String, dynamic> paymentInfo,
    required String paymentMethodNote,
  }) {
    final bankName = paymentInfo['bank_name']?.toString() ?? '';
    final iban = paymentInfo['iban']?.toString() ?? '';
    final accountHolderName =
        paymentInfo['account_holder_name']?.toString() ?? '';

    if (bankName.isEmpty && iban.isEmpty && accountHolderName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE7E7E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                color: Color(0xFFA35CFF),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPaymentInfoRow(
            label: 'Bank',
            value: bankName,
          ),
          const SizedBox(height: 10),
          _buildPaymentInfoRow(
            label: 'Account Holder',
            value: accountHolderName,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 110,
                child: Text(
                  'IBAN',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  iban,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Color(0xFFA35CFF),
                ),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: iban),
                  );

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('IBAN copied!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
          if (paymentMethodNote.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                paymentMethodNote,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
