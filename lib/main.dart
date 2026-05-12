import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  final List<Task> tasks = [
    Task(title: "pójść na zajęcia", deadline: "dzisiaj", done: true, priority: "wysoki"),
    Task(title: "zrobić zakupy", deadline: "jutro", done: false, priority: "średni"),
    Task(title: "Pójść na siłownię", deadline: "środa", done: false, priority: "niski"),
    Task(title: "zrobić grilla", deadline: "weekend", done: false, priority: "wysoki"),
  ];

  @override
  Widget build(BuildContext context) {

    int completedTasks = tasks.where((t) => t.done).length;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("KrakFlow"),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "Masz dziś ${tasks.length} zadania, wykonano: $completedTasks",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),

              Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: tasks.map((task) => TaskCard(task: task)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(

          task.done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.done ? Colors.green : Colors.grey,
        ),
        title: Text(
          task.title,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),

        subtitle: Text("termin: ${task.deadline} | priorytet: ${task.priority}"),
      ),
    );
  }
}


class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}
