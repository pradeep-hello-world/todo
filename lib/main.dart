import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(TodoApp());
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TodoScreen(),
    );
  }
}

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController taskController = TextEditingController();
  List<Map<String, dynamic>> tasks = [];
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedTasks = prefs.getString('tasks');
    if (storedTasks != null) {
      setState(() {
        tasks = List<Map<String, dynamic>>.from(jsonDecode(storedTasks));
      });
    }
  }

  Future<void> saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tasks', jsonEncode(tasks));
  }

  Future<void> selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void addTask() {
    String task = taskController.text.trim();
    if (task.isEmpty) {
      showErrorDialog("Task cannot be empty");
      return;
    }
    if (selectedDate == null) {
      selectedDate = DateTime.now();
    }
    setState(() {
      tasks.add({
        "task": task,
        "date": "${selectedDate!.toLocal()}".split(' ')[0],
        "time": selectedTime != null ? selectedTime!.format(context) : "No time set",
        "completed": false,
      });
    });
    taskController.clear();
    selectedDate = null;
    selectedTime = null;
    saveTasks();
  }

  void toggleTaskCompletion(int index) {
    setState(() {
      tasks[index]["completed"] = !tasks[index]["completed"];
    });
    saveTasks();
  }

  void deleteTask(int index) {
    if (!tasks[index]["completed"]) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete this task?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tasks.removeAt(index);
                });
                saveTasks();
                Navigator.pop(context);
              },
              child: Text("Delete"),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        tasks.removeAt(index);
      });
      saveTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To-Do List"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                labelText: "Enter task",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectDate,
                    child: Text(selectedDate == null ? "Select Date" : "${selectedDate!.toLocal()}".split(' ')[0]),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectTime,
                    child: Text(selectedTime == null ? "Select Time" : selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: addTask,
              child: Text("Add Task"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        tasks[index]["task"],
                        style: TextStyle(
                          decoration: tasks[index]["completed"] ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text("${tasks[index]["date"]} at ${tasks[index]["time"]}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              tasks[index]["completed"] ? Icons.check_box : Icons.check_box_outline_blank,
                              color: Colors.green,
                            ),
                            onPressed: () => toggleTaskCompletion(index),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () => deleteTask(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}