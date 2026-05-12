import 'package:flutter/material.dart';
import 'task_repository.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(primarySwatch: Colors.blue), home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  @override
  Widget build(BuildContext context) {

    List<Task> filteredTasks = TaskRepository.tasks.where((task) {
      if (selectedFilter == "wykonane") return task.done;
      if (selectedFilter == "do zrobienia") return !task.done;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [

          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: TaskRepository.tasks.isEmpty ? null : () => _showDeleteAllDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];

                return Dismissible(
                  key: ObjectKey(task),
                  direction: DismissDirection.endToStart,
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (direction) {
                    setState(() => TaskRepository.tasks.remove(task));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usunięto: ${task.title}")));
                  },
                  child: TaskCard(
                    task: task,
                    onChanged: (val) => setState(() => task.done = val!),
                    onTap: () async {

                      await Navigator.push(context, MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)));
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddTaskScreen()));
          if (newTask != null) setState(() => TaskRepository.tasks.add(newTask));
        },
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildFilterBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["wszystkie", "do zrobienia", "wykonane"].map((f) {
        return TextButton(
          onPressed: () => setState(() => selectedFilter = f),
          child: Text(f.toUpperCase(), style: TextStyle(color: selectedFilter == f ? Colors.blue : Colors.grey, fontWeight: selectedFilter == f ? FontWeight.bold : FontWeight.normal)),
        );
      }).toList(),
    );
  }


  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń wszystko?"),
        content: const Text("Czy na pewno chcesz wyczyścić listę zadań?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
          TextButton(onPressed: () {
            setState(() => TaskRepository.tasks.clear());
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lista wyczyszczona")));
          }, child: const Text("USUŃ", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}


class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTap;

  const TaskCard({super.key, required this.task, required this.onChanged, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: task.done, onChanged: onChanged),
        title: Text(task.title, style: TextStyle(decoration: task.done ? TextDecoration.lineThrough : null, color: task.done ? Colors.grey : Colors.black)),
        subtitle: Text("Termin: ${task.deadline} | Priorytet: ${task.priority}"),
        trailing: const Icon(Icons.edit, size: 20),
      ),
    );
  }
}


class EditTaskScreen extends StatelessWidget {
  final Task task;
  EditTaskScreen({super.key, required this.task});

  late final titleController = TextEditingController(text: task.title);
  late final deadlineController = TextEditingController(text: task.deadline);
  late final priorityController = TextEditingController(text: task.priority);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                task.title = titleController.text;
                task.deadline = deadlineController.text;
                task.priority = priorityController.text;
                Navigator.pop(context);
              },
              child: const Text("ZAPISZ ZMIANY"),
            ),
          ],
        ),
      ),
    );
  }
}


class AddTaskScreen extends StatelessWidget {
  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();
  AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet")),
            ElevatedButton(onPressed: () => Navigator.pop(context, Task(title: titleController.text, deadline: deadlineController.text, priority: priorityController.text, done: false)), child: const Text("DODAJ")),
          ],
        ),
      ),
    );
  }
}

