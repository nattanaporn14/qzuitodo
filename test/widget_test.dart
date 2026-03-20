import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const TodoApp());

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('todo_data', json.encode(_todoList));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('todo_data');
    if (savedData != null) {
      setState(() {
        _todoList = List<Map<String, dynamic>>.from(json.decode(savedData));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _todoList.where((t) => !t['isDone']).toList();
    final completed = _todoList.where((t) => t['isDone']).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List ✅'), backgroundColor: Colors.blue.shade100),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'เพิ่มงานใหม่...'))),
                IconButton(icon: const Icon(Icons.add_circle, size: 40, color: Colors.blue), 
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() => _todoList.add({'title': _controller.text, 'isDone': false}));
                      _controller.clear();
                      _saveData();
                    }
                  }),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _header("งานที่ยังค้างอยู่", Colors.orange),
                ...pending.map((item) => _item(item)),
                _header("งานที่เสร็จแล้ว", Colors.green),
                ...completed.map((item) => _item(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String t, Color c) => Container(padding: const EdgeInsets.all(8), color: c.withOpacity(0.1), child: Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold)));

  Widget _item(Map<String, dynamic> item) {
    int idx = _todoList.indexOf(item);
    return ListTile(
      leading: Checkbox(value: item['isDone'], onChanged: (v) {
        setState(() => _todoList[idx]['isDone'] = v);
        _saveData();
      }),
      title: Text(item['title'], style: TextStyle(decoration: item['isDone'] ? TextDecoration.lineThrough : null)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit, color: Colors.amber), onPressed: () => _edit(idx)),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
            setState(() => _todoList.removeAt(idx));
            _saveData();
          }),
        ],
      ),
    );
  }

  void _edit(int idx) {
    TextEditingController e = TextEditingController(text: _todoList[idx]['title']);
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("แก้ไขงาน"),
      content: TextField(controller: e),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text("ยกเลิก")),
        ElevatedButton(onPressed: () {
          setState(() => _todoList[idx]['title'] = e.text);
          _saveData();
          Navigator.pop(c);
        }, child: const Text("บันทึก"))
      ],
    ));
  }
}