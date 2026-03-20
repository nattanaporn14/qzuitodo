import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const PremiumTodoApp());

class PremiumTodoApp extends StatelessWidget {
  const PremiumTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.light),
        fontFamily: 'sans-serif',
      ),
      home: const TodoHomeScreen(),
    );
  }
}

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key});

  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); // โหลดข้อมูลทันทีที่เปิดแอป
  }

  // --- ส่วนจัดการข้อมูล (Persistence) ---

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // แปลง List เป็น JSON String แล้วบันทึกลงเครื่อง
    prefs.setString('todo_data_v3', json.encode(_todoList));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('todo_data_v3');
    if (savedData != null) {
      setState(() {
        _todoList = List<Map<String, dynamic>>.from(json.decode(savedData));
      });
    }
  }

  // --- ส่วนฟังก์ชันการทำงาน ---

  void _addOrEditTodo({int? index}) {
    if (_controller.text.isEmpty) return;

    setState(() {
      if (index != null) {
        // กรณีแก้ไข
        _todoList[index]['title'] = _controller.text;
      } else {
        // กรณีเพิ่มใหม่
        _todoList.insert(0, {'title': _controller.text, 'isDone': false});
      }
    });
    
    _controller.clear();
    _saveData(); // บันทึกข้อมูลลงเครื่อง
    Navigator.pop(context);
  }

  void _toggleDone(int originalIndex) {
    setState(() {
      _todoList[originalIndex]['isDone'] = !_todoList[originalIndex]['isDone'];
    });
    _saveData();
  }

  void _deleteTodo(int originalIndex) {
    setState(() {
      _todoList.removeAt(originalIndex);
    });
    _saveData();
  }

  // --- ส่วนการสร้างหน้าจอ ---

  @override
  Widget build(BuildContext context) {
    // กรองข้อมูลแยกตามสถานะ
    final pendingTasks = _todoList.asMap().entries.where((e) => !e.value['isDone']).toList();
    final completedTasks = _todoList.asMap().entries.where((e) => e.value['isDone']).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildProgressCard(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (pendingTasks.isNotEmpty) ...[
                      _buildSectionHeader("📌 งานที่ต้องทำ (${pendingTasks.length})"),
                      ...pendingTasks.map((e) => _buildTodoItem(e.value, e.key)),
                    ],
                    if (completedTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionHeader("✅ งานที่เสร็จแล้ว (${completedTasks.length})"),
                      ...completedTasks.map((e) => _buildTodoItem(e.value, e.key)),
                    ],
                    if (_todoList.isEmpty) _buildEmptyState(),
                    const SizedBox(height: 100), // เผื่อระยะให้ FloatingButton
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        backgroundColor: Colors.indigo,
        label: const Text("เพิ่มงานใหม่", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return const Padding(
      padding: EdgeInsets.all(25.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("สวัสดีตอนเช้า,", style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text("วันนี้มีแผนทำอะไรบ้าง? ✨", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    int total = _todoList.length;
    int done = _todoList.where((t) => t['isDone']).length;
    double rate = total == 0 ? 0 : done / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ความสำเร็จวันนี้", style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 5),
          Text("$done/$total งานเสร็จสิ้น", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: rate,
            backgroundColor: Colors.white24,
            color: Colors.white,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildTodoItem(Map<String, dynamic> item, int originalIndex) {
    bool isDone = item['isDone'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          onChanged: (_) => _toggleDone(originalIndex),
          activeColor: Colors.indigo,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item['title'],
          style: TextStyle(
            fontSize: 16,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () => _showTaskDialog(index: originalIndex, initialText: item['title']),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteTodo(originalIndex),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(Icons.task_alt, size: 80, color: Colors.indigo.withOpacity(0.1)),
          const Text("ยังไม่มีรายการงาน", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showTaskDialog({int? index, String initialText = ""}) {
    _controller.text = initialText;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(index == null ? "เพิ่มงานใหม่" : "แก้ไขงาน", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "คุณต้องการทำอะไร...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _addOrEditTodo(index: index),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("บันทึกข้อมูล", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}