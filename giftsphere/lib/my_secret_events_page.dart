import 'package:flutter/material.dart';
import 'api_service.dart';
import 'exchange_waiting_room.dart';

class MySecretEventsPage extends StatefulWidget {
  const MySecretEventsPage({super.key});

  @override
  State<MySecretEventsPage> createState() => _MySecretEventsPageState();
}

class _MySecretEventsPageState extends State<MySecretEventsPage> {
  bool _isLoading = true;
  List<dynamic> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
  }

  Future<void> _fetchMyEvents() async {
    final result = await ApiService.getMyExchanges();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _events = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Secret Events', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(child: Text('You haven\'t joined any events yet.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final isDrawn = event['status'] == 'ACTIVE';

                    return InkWell(
                      onTap: () {
                        // عند الضغط على الحدث، يفتح غرفة الانتظار/التفاصيل الخاصة به
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => ExchangeWaitingRoom(exchangeId: event['id']),
                        ));
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFE2E2E2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['title'],
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                // إذا تمت القرعة نعرض اسم الشخص، وإذا لا نقول "انتظار"
                                Text(
                                  isDrawn && event['my_receiver'] != null 
                                    ? 'You are gifting: ${event['my_receiver']}' 
                                    : 'Status: Waiting for Draw',
                                  style: TextStyle(
                                    color: isDrawn ? const Color(0xFF53B175) : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}