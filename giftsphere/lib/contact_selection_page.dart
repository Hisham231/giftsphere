import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'contact_service.dart';

class ContactSelectionPage extends StatefulWidget {
  final String inviteCode;

  // للقطة
  final String? qattahTitle;

  // للـ Secret Exchange
  final String? exchangeTitle;

  // false = Qattah / true = Secret Exchange
  final bool isSecretExchange;

  const ContactSelectionPage({
    super.key,
    required this.inviteCode,
    this.qattahTitle,
    this.exchangeTitle,
    this.isSecretExchange = false,
  });

  @override
  State<ContactSelectionPage> createState() => _ContactSelectionPageState();
}

class _ContactSelectionPageState extends State<ContactSelectionPage> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final Map<String, String> _selectedContacts = {};
  bool _isLoading = true;
  bool _isSending = false;

  String get _eventTitle {
    if (widget.isSecretExchange) {
      return widget.exchangeTitle ?? 'Secret Exchange';
    }
    return widget.qattahTitle ?? 'Qattah';
  }

  String get _eventTypeLabel {
    return widget.isSecretExchange ? 'Secret Exchange' : 'Qattah';
  }

  @override
  void initState() {
    super.initState();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    final status = await Permission.contacts.request();

    if (status.isGranted) {
      try {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );

        if (!mounted) return;

        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Permission Required',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Please allow Contacts permission from Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text(
                'Open Settings',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact permission denied'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _filteredContacts = _contacts.where((c) {
        return c.displayName.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _toggleSelection(String phone, String name) {
    setState(() {
      if (_selectedContacts.containsKey(phone)) {
        _selectedContacts.remove(phone);
      } else {
        _selectedContacts[phone] = name;
      }
    });
  }

  Future<void> _sendInvites() async {
    if (_selectedContacts.isEmpty) return;

    setState(() => _isSending = true);

    int successCount = 0;

    for (final entry in _selectedContacts.entries) {
      bool sent;

      if (widget.isSecretExchange) {
        sent = await ContactService.sendExchangeInviteSMS(
          phoneNumber: entry.key,
          inviteCode: widget.inviteCode,
          exchangeTitle: widget.exchangeTitle ?? 'Secret Exchange',
          contactName: entry.value,
        );
      } else {
        sent = await ContactService.sendQattahInviteSMS(
          phoneNumber: entry.key,
          inviteCode: widget.inviteCode,
          qattahTitle: widget.qattahTitle ?? 'Qattah',
          contactName: entry.value,
        );
      }

      if (sent) successCount++;

      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (!mounted) return;

    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount > 0
              ? '✅ Invites sent to $successCount friends!'
              : '❌ Could not open messaging app',
        ),
        backgroundColor:
            successCount > 0 ? const Color(0xFF53B175) : Colors.red,
      ),
    );

    if (successCount > 0) {
      Navigator.pop(context);
    }
  }

  bool _isAllSelected() {
    final withPhone =
        _filteredContacts.where((c) => c.phones.isNotEmpty).toList();

    if (withPhone.isEmpty) return false;

    return withPhone.every(
      (c) => _selectedContacts.containsKey(
        c.phones.first.number.replaceAll(' ', ''),
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected()) {
        for (final c in _filteredContacts) {
          if (c.phones.isNotEmpty) {
            _selectedContacts.remove(
              c.phones.first.number.replaceAll(' ', ''),
            );
          }
        }
      } else {
        for (final c in _filteredContacts) {
          if (c.phones.isNotEmpty) {
            final phone = c.phones.first.number.replaceAll(' ', '');
            _selectedContacts[phone] = c.displayName;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite Friends',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            if (_selectedContacts.isNotEmpty)
              Text(
                '${_selectedContacts.length} selected',
                style: const TextStyle(
                  color: Color(0xFFA35CFF),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                _isAllSelected() ? 'Deselect All' : 'Select All',
                style: const TextStyle(
                  color: Color(0xFFA35CFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFA35CFF),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA35CFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFA35CFF).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFFA35CFF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_eventTypeLabel invite code for "$_eventTitle": ${widget.inviteCode}',
                          style: const TextStyle(
                            color: Color(0xFFA35CFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: _filterContacts,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredContacts.isEmpty
                      ? const Center(
                          child: Text('No contacts found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _filteredContacts[index];

                            final String phone = contact.phones.isNotEmpty
                                ? contact.phones.first.number.replaceAll(
                                    ' ',
                                    '',
                                  )
                                : '';

                            final bool hasPhone = phone.isNotEmpty;
                            final bool isSelected =
                                _selectedContacts.containsKey(phone);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected
                                    ? const BorderSide(
                                        color: Color(0xFFA35CFF),
                                        width: 1.5,
                                      )
                                    : BorderSide.none,
                              ),
                              color: isSelected
                                  ? const Color(0xFFF3EBFF)
                                  : Colors.white,
                              child: ListTile(
                                onTap: hasPhone
                                    ? () => _toggleSelection(
                                          phone,
                                          contact.displayName,
                                        )
                                    : null,
                                leading: CircleAvatar(
                                  backgroundColor: isSelected
                                      ? const Color(0xFFA35CFF)
                                      : const Color(0xFFF5F6FA),
                                  child: Text(
                                    contact.displayName.isNotEmpty
                                        ? contact.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFA35CFF),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  contact.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  hasPhone ? phone : 'No number',
                                  style: TextStyle(
                                    color: hasPhone
                                        ? Colors.grey
                                        : Colors.red[300],
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  activeColor: const Color(0xFFA35CFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: hasPhone
                                      ? (_) => _toggleSelection(
                                            phone,
                                            contact.displayName,
                                          )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_selectedContacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendInvites,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isSending
                              ? 'Sending...'
                              : 'Invite ${_selectedContacts.length} Friends',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA35CFF),
                          disabledBackgroundColor:
                              const Color(0xFFA35CFF).withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}