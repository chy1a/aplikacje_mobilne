import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'task_repository.dart';
import 'task_api_service.dart';
import 'task_local_database.dart';
import 'task_sync_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";
  late Future<List<Task>> _tasksFuture;

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
  }

  Future<List<Task>> _loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    final tasks = TaskLocalDatabase.getTasks();
    _updateCounters(tasks);
    return tasks;
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = Future.value(TaskLocalDatabase.getTasks());
    });
  }

  void _updateCounters(List<Task> tasks) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          allTasksCount = tasks.length;
          doneTasksCount = tasks.where((task) => task.done).length;
          todoTasksCount = tasks.where((task) => !task.done).length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow ($todoTasksCount/$allTasksCount)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Wymuś synchronizację z API",
            onPressed: () async {
              await TaskLocalDatabase.deleteAllTasks();
              setState(() {
                _tasksFuture = _loadTasks();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Usuń wszystkie lokalne",
            onPressed: () => _showDeleteAllDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Błąd: ${snapshot.error}"));
          }

          final allTasks = snapshot.data ?? [];
          _updateCounters(allTasks);

          List<Task> filteredTasks = allTasks.where((task) {
            if (selectedFilter == "wykonane") return task.done;
            if (selectedFilter == "do zrobienia") return !task.done;
            return true;
          }).toList();

          if (filteredTasks.isEmpty) {
            return Column(
              children: [
                _buildFilterBar(),
                const Expanded(child: Center(child: Text("Brak zadań w tej kategorii"))),
              ],
            );
          }

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Dismissible(
                      key: Key(task.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        await TaskLocalDatabase.deleteTask(task.id);
                        _refreshTasks();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Usunięto zadanie")),
                        );
                      },
                      child: TaskCard(
                        task: task,
                        onChanged: (val) async {
                          final updatedTask = Task(
                            id: task.id,
                            title: task.title,
                            deadline: task.deadline,
                            priority: task.priority,
                            done: val ?? false,
                          );
                          await TaskLocalDatabase.updateTask(updatedTask);
                          _refreshTasks();
                        },
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditTaskScreen(task: task))
                          );
                          _refreshTasks();
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTaskScreen())
          );
          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            _refreshTasks();
          }
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
          child: Text(
            f.toUpperCase(),
            style: TextStyle(
              color: selectedFilter == f ? Colors.blue : Colors.grey,
              fontWeight: selectedFilter == f ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń wszystko?"),
        content: const Text("Czy na pewno chcesz wyczyścić lokalną listę zadań?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULUJ")),
          TextButton(
            onPressed: () async {
              await TaskLocalDatabase.deleteAllTasks();
              Navigator.pop(ctx);
              _refreshTasks();
            },
            child: const Text("USUŃ", style: TextStyle(color: Colors.red)),
          ),
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
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: task.done, onChanged: onChanged),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.done ? TextDecoration.lineThrough : null,
            color: task.done ? Colors.grey : Colors.black,
          ),
        ),
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
                onPressed: () async {
                  task.title = titleController.text;
                  task.deadline = deadlineController.text;
                  task.priority = priorityController.text;

                  await TaskLocalDatabase.updateTask(task);
                  if (context.mounted) Navigator.pop(context);
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
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final deadlineController = TextEditingController(text: "2026-06-15");
    final priorityController = TextEditingController(text: "średni");

    return Scaffold(
      appBar: AppBar(title: const Text("Dodaj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tytuł"),
            ),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(labelText: "Termin"),
            ),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(labelText: "Priorytet"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  final task = Task(
                    id: DateTime.now().millisecondsSinceEpoch,
                    title: titleController.text,
                    deadline: deadlineController.text,
                    priority: priorityController.text,
                    done: false,
                  );
                  Navigator.pop(context, task);
                }
              },
              child: const Text("DODAJ ZADANIE"),
            ),
          ],
        ),
      ),
    );
  }
}

