import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'my_assignment_page.dart';

class ExchangeWaitingRoom extends StatefulWidget {
  final int exchangeId;

  const ExchangeWaitingRoom({super.key, required this.exchangeId});

  @override
  State<ExchangeWaitingRoom> createState() => _ExchangeWaitingRoomState();
}

class _ExchangeWaitingRoomState extends State<ExchangeWaitingRoom> {
  bool _isLoading = true;
  bool _isDrawing = false;
  Map<String, dynamic>? _eventData;
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

    final result = await ApiService.getExchangeDetails(widget.exchangeId);

    if (!mounted) return;

    setState(() {
      _myPhone = currentPhone;
      _eventData = result['success'] ? result['data'] : null;
      _isLoading = false;
    });
  }

  Future<void> _startDraw() async {
    setState(() => _isDrawing = true);

    final result = await ApiService.drawAssignments(widget.exchangeId);

    if (!mounted) return;

    setState(() => _isDrawing = false);

    if (result['success']) {
      await _loadDetails();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignments successfully drawn!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to draw assignments'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _leaveEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Event?'),
        content: const Text(
          'Are you sure you want to leave this gift exchange?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final result = await ApiService.leaveExchange(widget.exchangeId);

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have left the event.'),
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyInviteCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFA35CFF),
          ),
        ),
      );
    }

    if (_eventData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Event not found'),
        ),
      );
    }

    final organizer = _eventData!['organizer'] ?? {};
    final organizerPhoneRaw = organizer['phone_number']?.toString() ?? '';
    final organizerPhone = organizerPhoneRaw.startsWith('0')
        ? organizerPhoneRaw.substring(1)
        : organizerPhoneRaw;

    final bool isOrganizer =
        _myPhone.isNotEmpty && organizerPhone == _myPhone;

    final bool isPending = _eventData!['status'] == 'PENDING';

    final participants =
        _eventData!['participant_details'] as List<dynamic>? ?? [];

    final acceptedParticipants = participants.where((p) {
      final status = p['status']?.toString().toUpperCase() ?? '';
      return status == 'ACCEPTED';
    }).toList();

    final String organizerName =
        organizer['first_name']?.toString().isNotEmpty == true
            ? organizer['first_name']
            : (organizer['phone_number'] ?? 'Organizer');

    final String budget = _eventData!['budget']?.toString() ?? 'N/A';
    final String inviteCode = _eventData!['invite_code']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _eventData!['title'] ?? 'Secret Exchange',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isOrganizer && isPending)
            IconButton(
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.redAccent,
              ),
              tooltip: 'Leave Event',
              onPressed: _leaveEvent,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFA35CFF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFA35CFF),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Event Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isPending ? 'Waiting for Draw' : 'Active (Drawn)',
                        style: TextStyle(
                          color: isPending ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailItem(
                        'Organizer',
                        organizerName,
                        Icons.person,
                      ),
                      _buildDetailItem(
                        'Budget',
                        '$budget SAR',
                        Icons.monetization_on,
                      ),
                      _buildDetailItem(
                        'Joined',
                        '${acceptedParticipants.length}',
                        Icons.group,
                      ),
                    ],
                  ),
                  if (inviteCode.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => _copyInviteCode(inviteCode),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFA35CFF).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              color: Color(0xFFA35CFF),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Invite Code:',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                inviteCode,
                                style: const TextStyle(
                                  color: Color(0xFFA35CFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.copy,
                              color: Color(0xFFA35CFF),
                              size: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Participants (${participants.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: participants.isEmpty
                  ? const Center(
                      child: Text(
                        'No participants yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        final user = participant['user'] ?? {};
                        final firstName =
                            user['first_name']?.toString() ?? '';
                        final phone =
                            user['phone_number']?.toString() ?? 'User';

                        final displayName =
                            firstName.isNotEmpty ? firstName : phone;

                        final status =
                            participant['status']?.toString().toUpperCase() ??
                                'INVITED';

                        Color statusColor = Colors.grey;
                        if (status == 'ACCEPTED') {
                          statusColor = Colors.green;
                        } else if (status == 'REJECTED') {
                          statusColor = Colors.red;
                        } else if (status == 'LEFT') {
                          statusColor = Colors.orange;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFF5F6FA),
                              child: Text(
                                displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFA35CFF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(25),
        color: Colors.white,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: isPending
                ? isOrganizer
                    ? acceptedParticipants.length >= 3
                        ? ElevatedButton(
                            onPressed: _isDrawing ? null : _startDraw,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA35CFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isDrawing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Draw Assignments',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          )
                        : Center(
                            child: Text(
                              'Need at least 3 participants to draw',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                    : Center(
                        child: Text(
                          'Waiting for organizer to draw...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyAssignmentPage(
                            exchangeId: widget.exchangeId,
                            eventName: _eventData!['title'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF53B175),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Reveal My Secret Gift!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}