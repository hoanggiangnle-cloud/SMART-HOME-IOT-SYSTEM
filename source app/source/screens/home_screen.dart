import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/room.dart';
import '../models/history_entry.dart';
import 'room_screen.dart';
import '../widgets/power_chart.dart';
import '../widgets/room_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  Map<String, dynamic>? statusData;
  List<HistoryEntry> history = [];
  Timer? _statusTimer;
  Timer? _historyTimer;
  
  final Duration historyRefreshInterval = const Duration(seconds: 10);
  final Duration uiRefreshInterval = const Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _fetchAll();
  _statusTimer = Timer.periodic(uiRefreshInterval, (_) => _fetchStatus());
  _historyTimer = Timer.periodic(historyRefreshInterval, (_) => _fetchHistory());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _historyTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    await _fetchStatus();
    await _fetchHistory();
  }

  Future<void> _fetchStatus() async {
    final res = await ApiService.fetchStatus();
    if (res != null) {
      if (!mounted) return;
      setState(() {
        statusData = res;
      });
    }
  }

  Future<void> _fetchHistory() async {
    final res = await ApiService.fetchHistory();
    if (!mounted) return;
    setState(() => history = res);
  }

  void openRoom(String name) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => RoomScreen(roomName: name, statusData: statusData, history: history)));
  }

  Future<void> _addRoomDialog() async {
    // if (widget.role != 'admin') {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ admin mới được thêm phòng!')));
    //   return;
    // }

    final nameCtrl = TextEditingController();
    final tempPinCtrl = TextEditingController();
    final lightPinCtrl = TextEditingController();
    final fanPinCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thêm phòng'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên phòng'),),
            TextField(controller: tempPinCtrl, decoration: const InputDecoration(labelText: 'tempPin'), keyboardType: TextInputType.number),
            TextField(controller: lightPinCtrl, decoration: const InputDecoration(labelText: 'lightPin'), keyboardType: TextInputType.number),
            TextField(controller: fanPinCtrl, decoration: const InputDecoration(labelText: 'fanPin'), keyboardType: TextInputType.number),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Thêm')),
        ],
      ),
    );

    if (ok == true) {
      final room = {
        'name': nameCtrl.text.trim(),
        'tempPin': int.tryParse(tempPinCtrl.text) ?? -1,
        'lightPin': int.tryParse(lightPinCtrl.text) ?? -1,
        'fanPin': int.tryParse(fanPinCtrl.text) ?? -1,
      };
      final ok2 = await ApiService.addRoom(room);
      if (!mounted) return;
      if (ok2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lệnh thêm phòng')));
        _fetchStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi gửi lệnh thêm phòng')));
      }
    }
  }

  Future<void> _removeRoomDialog() async {
    if (widget.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ admin mới được xóa phòng!')));
      return;
    }
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa phòng'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên phòng')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) {
      final ok2 = await ApiService.removeRoom(nameCtrl.text.trim());
      if (!mounted) return;
      if (ok2) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi lệnh xóa phòng')));
        _fetchStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi gửi lệnh xóa phòng')));
      }
    }
  }

  // ========================= PAGE UI =============================

  Widget _buildHomePage() {
    final voltage = statusData?['voltage'] ?? 0.0;
    final current = statusData?['current'] ?? 0.0;
    final power = statusData?['power'] ?? 0.0;

    List<Room> rooms = [];
    if (statusData?['rooms'] != null) {
      final arr = statusData!['rooms'] as List<dynamic>;
      rooms = arr.map((e) => Room.fromJson(e)).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _StatCard(title: 'Điện áp', value: '${(voltage as num).toStringAsFixed(1)} V', textcolor: Colors.amber,),
          _StatCard(title: 'Dòng điện', value: '${(current as num).toStringAsFixed(1)} mA', textcolor: Colors.red ),
          _StatCard(title: 'Công suất', value: '${(power as num).toStringAsFixed(1)} mW',textcolor: Colors.purple),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(children: [
              const Text('Điện áp, Dòng điện & Công suất', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(height: 200, child: PowerChart(history: history)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        if (widget.role == 'admin')
          Card(
            child: Padding(

              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                const Text('Quản lý phòng (Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize:24 )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _addRoomDialog,
                      child: const Text('Thêm Phòng',style: TextStyle(fontSize:20)),
                    ),
                    const SizedBox(width: 18),
                    ElevatedButton(
                      onPressed: _removeRoomDialog,
                      child: const Text('Xóa Phòng',style: TextStyle(fontSize:20)),
                    ),
                  ],
                )

              ]),
            ),
          ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(spacing: 16, runSpacing: 16, children: rooms.map((r) => RoomCard(name: r.name, onTap: () => openRoom(r.name))).toList()),
        ),
      ]),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Hồ sơ", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _InfoRow(icon: Icons.person, title: "Quyền truy cập", value: widget.role),
        Divider(),
        if (widget.role == "admin") ...[
          const _InfoRow(icon: Icons.email, title: "Email", value: "admin@gmail.com"),
          Divider(),
          const _InfoRow(icon: Icons.phone, title: "Số điện thoại", value: "0123 456 789"),
          Divider(),
          const _InfoRow(icon: Icons.home, title: "Địa chỉ", value: "123 Đường ABC, TP.HCM"),
          Divider(),
        ] else if (widget.role == "user") ...[
          const _InfoRow(icon: Icons.email, title: "Email", value: "user@gmail.com"),
          Divider(),
          const _InfoRow(icon: Icons.phone, title: "Số điện thoại", value: "0123 456 789"),
          Divider(),
          const _InfoRow(icon: Icons.home, title: "Địa chỉ", value: "123 Đường ABC, TP.HCM"),
          Divider(),
        ],

        const SizedBox(height: 60),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
            child: const Text("Đăng xuất", style: TextStyle(fontSize: 20, color: Colors.white,fontWeight: FontWeight.bold),),
          ),
        ),
      ]),
    );
  }

  Widget _buildSettingPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text("Cài đặt", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        _SettingRow(icon: Icons.language, title: "Ngôn ngữ", value: "Tiếng Việt"),
        Divider(),
        _SettingRow(icon: Icons.brightness_6, title: "Chủ đề", value: "Sáng"),
        Divider(),
        _SettingRow(icon: Icons.notifications, title: "Thông báo", value: "Bật"),
        Divider(),
        _SettingRow(icon: Icons.info, title: "Phiên bản", value: "1.0.0"),
      ]),
    );
  }

  // ========================= MAIN BUILD =============================

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      _buildProfilePage(),
      _buildSettingPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("SMART HOME"),
        backgroundColor: Colors.amber[200],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Hồ sơ"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Cài đặt"),
        ],
      ),
    );
  }
}

// ========================= UI COMPONENTS =============================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color textcolor;
  const _StatCard({required this.title, required this.value, this.textcolor = Colors.blue,});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Icon(Icons.bolt, color: Colors.amber[700]),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textcolor,))
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _SettingRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
