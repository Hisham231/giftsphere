import 'package:flutter/material.dart';
import 'api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getNotifications();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _notifications = result['data']['notifications'] ?? [];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Failed to load notifications')),
          );
        }
      });
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    if (_notifications[index]['is_read'] == true) return;

    final result = await ApiService.markNotificationAsRead(notificationId);
    if (result['success'] && mounted) {
      setState(() {
        _notifications[index]['is_read'] = true;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No new notifications', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final bool isRead = notification['is_read'] ?? false;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isRead ? 0 : 2,
                        color: isRead ? Colors.white70 : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isRead ? Colors.transparent : const Color(0xFF53B175).withOpacity(0.3)),
                        ),
                        child: ListTile(
                          onTap: () => _markAsRead(notification['id'], index),
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey[200] : const Color(0xFF53B175).withOpacity(0.2),
                            child: Icon(
                              Icons.notifications_active, 
                              color: isRead ? Colors.grey : const Color(0xFF53B175)
                            ),
                          ),
                          title: Text(
                            notification['title'] ?? 'New Notification',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              notification['message'] ?? '',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          trailing: !isRead 
                            ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                            : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}