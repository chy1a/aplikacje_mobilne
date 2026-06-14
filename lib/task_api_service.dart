import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'task_repository.dart';
import 'dart:developer' as developer;

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {

    developer.log("Adres zapytania: $baseUrl/todos", name: "TaskApiService");

    final response = await http.get(Uri.parse("$baseUrl/todos"));


    developer.log("Kod odpowiedzi HTTP: ${response.statusCode}", name: "TaskApiService");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];


      developer.log("Liczba zadań: ${todos.length}", name: "TaskApiService");

      final random = Random();
      final priorities = ["niski", "średni", "wysoki"];

      return todos.map((todo) {
        return Task(
          id: todo["id"],
          title: todo["todo"],
          deadline: "2024-05-${random.nextInt(28) + 1}",
          done: todo["completed"],
          priority: priorities[random.nextInt(priorities.length)],
        );
      }).toList();
    } else {
      developer.log(
        "Błąd pobierania danych! Serwer zwrócił status inny niż 200.",
        name: "TaskApiService",
        error: "Status code: ${response.statusCode}",
      );
      throw Exception("Błąd pobierania danych z serwera");
    }
  }
}