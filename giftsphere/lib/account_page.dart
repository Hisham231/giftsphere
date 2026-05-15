import 'package:flutter/material.dart';
import 'api_service.dart';
import 'edit_profile_page.dart';
import 'my_wishlist_page.dart';
import 'group_gift_page.dart';
import 'my_secret_events_page.dart';
import 'reminders_page.dart';
import 'notifications_page.dart';
import 'my_contributions_page.dart';
import 'sign_in_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getCurrentUserProfile();
    final localData = await ApiService.getUserData();

    if (!mounted) return;

    setState(() {
      _isLoading = false;

      if (result['success'] == true && result['data'] != null) {
        _user = Map<String, dynamic>.from(result['data']);
      } else {
        _user = localData;
      }
    });
  }

  String _getDisplayName() {
    final firstName = _user?['first_name']?.toString() ?? '';
    final lastName = _user?['last_name']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    return fullName.isNotEmpty ? fullName : 'GiftSphere User';
  }

  String _getInitials() {
    final firstName = _user?['first_name']?.toString() ?? '';
    final lastName = _user?['last_name']?.toString() ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    }

    if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }

    return 'U';
  }

  String _getPhone() {
    final rawPhone = _user?['phone_number']?.toString().trim().isNotEmpty == true
        ? _user!['phone_number'].toString().trim()
        : _user?['phone']?.toString().trim() ?? '';

    if (rawPhone.isEmpty) return '';

    if (rawPhone.startsWith('+')) {
      return rawPhone;
    }

    if (rawPhone.startsWith('966')) {
      return '+$rawPhone';
    }

    if (rawPhone.startsWith('0')) {
      return '+966 ${rawPhone.substring(1)}';
    }

    return '+966 $rawPhone';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const SignInPage(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _openPage(Widget page) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    if (!mounted) return;

    if (updated == true || page is EditProfilePage) {
      await _loadProfile();
    } else {
      await _loadProfile();
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
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFA35CFF),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 18),
                  _buildSectionTitle('My Gifts'),
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(
                        icon: Icons.favorite_border,
                        title: 'My Wishlist',
                        subtitle: 'View saved gift ideas',
                        color: Colors.redAccent,
                        onTap: () => _openPage(const MyWishlistPage()),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.group_outlined,
                        title: 'My Group Gifts',
                        subtitle: 'View your active Qattahs',
                        color: const Color(0xFFA35CFF),
                        onTap: () => _openPage(const GroupGiftPage()),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'My Contributions',
                        subtitle: 'See the Qattahs you contributed to',
                        color: const Color(0xFF53B175),
                        onTap: () => _openPage(MyContributionsPage()),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.card_giftcard,
                        title: 'My Secret Events',
                        subtitle: 'View secret gift exchanges',
                        color: const Color(0xFF648DDB),
                        onTap: () => _openPage(const MySecretEventsPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Activity'),
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(
                        icon: Icons.calendar_month_outlined,
                        title: 'Reminders',
                        subtitle: 'Upcoming gift reminders',
                        color: const Color(0xFF648DDB),
                        onTap: () => _openPage(const RemindersPage()),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        subtitle: 'See recent updates',
                        color: const Color(0xFFA35CFF),
                        onTap: () => _openPage(const NotificationsPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionTitle('Account Settings'),
                  _buildMenuCard(
                    children: [
                      _buildMenuItem(
                        icon: Icons.edit_outlined,
                        title: 'Edit Profile',
                        subtitle: 'Update your name and banking information',
                        color: Colors.black87,
                        onTap: () => _openPage(const EditProfilePage()),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out from your account',
                        color: Colors.redAccent,
                        onTap: _logout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final avatar = _user?['avatar'];
    final phone = _getPhone();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFA35CFF).withOpacity(0.12),
            backgroundImage: avatar != null && avatar.toString().isNotEmpty
                ? NetworkImage(avatar)
                : null,
            child: avatar == null || avatar.toString().isEmpty
                ? Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Color(0xFFA35CFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone.isNotEmpty ? phone : 'No phone number',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openPage(const EditProfilePage()),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Color(0xFFA35CFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 15,
        color: Colors.grey,
      ),
    );
  }
}