import 'package:hive_ce/hive.dart';
import 'task_repository.dart';
import 'dart:developer' as developer;

class TaskLocalDatabase {
  static Box get _box => Hive.box("tasks");

  static List<Task> getTasks() {
    final tasks = _box.values.map((item) {
      return Task.fromMap(Map<String, dynamic>.from(item));
    }).toList();


    developer.log("Odczytano zadania z lokalnej bazy danych. Liczba: ${tasks.length}", name: "DatabaseService");
    return tasks;
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    await _box.clear();
    for (final task in tasks) {
      await _box.put(task.id, task.toMap());
    }
  }

  static Future<void> addTask(Task task) async {
    await _box.put(task.id, task.toMap());

    developer.log("Dodano nowe zadanie o ID: ${task.id}, Tytuł: ${task.title}", name: "DatabaseService");
  }

  static Future<void> updateTask(Task task) async {
    await _box.put(task.id, task.toMap());
    developer.log("Zaktualizowano zadanie o ID: ${task.id} (Status done: ${task.done})", name: "DatabaseService");
  }

  static Future<void> deleteTask(int id) async {
    await _box.delete(id);
    developer.log("Usunięto jedno zadanie o ID: $id", name: "DatabaseService");
  }

  static Future<void> deleteAllTasks() async {
    await _box.clear();
    developer.log("Usunięto wszystkie zadania z lokalnej bazy danych", name: "DatabaseService");
  }

  static bool isEmpty() {
    return _box.isEmpty;
  }
}