
import 'package:flutter/material.dart';
void main() {
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
   const MyApp({super.key});
  @override
  State<MyApp> createState() => HomeScreenState();


}
class HomeScreenState extends State<MyApp>{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
        title: Text("KrakFlow"),
      ),
      body: Center(
        child: Text("Lista zadań"),
      ),
        floatingActionButton: FloatingActionButton(
            onPressed: (){},
            child: Icon(Icons.add),
        ),

      )
    );
  }
}

class AddTaskScreen extends State<MyApp>{

}


