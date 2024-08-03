import 'package:flutter/material.dart';
import 'package:simple_todo/utils/todo_list.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _editController = TextEditingController();
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  List toDoList = [];
  int? _editIndex;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/todos'));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          toDoList = data.take(10).map((item) => [item['title'], item['completed']]).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load todos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void checkBoxChanged(int index) {
    setState(() {
      toDoList[index][1] = !toDoList[index][1];
    });
  }

  void saveNewTask() {
    setState(() {
      toDoList.add([_controller.text, false]);
      _controller.clear();
    });
  }

  void deleteTask(int index) {
    setState(() {
      toDoList.removeAt(index);
    });
  }

  void editTask(int index) {
    _editController.text = toDoList[index][0];
    _editIndex = index;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Todo'),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(hintText: 'Edit todo item'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_editController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a todo item')),
                  );
                } else {
                  setState(() {
                    toDoList[_editIndex!][0] = _editController.text;
                    _editController.clear();
                    _editIndex = null;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade300,
      appBar: AppBar(
        title: const Text('Todo List'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Visibility(
                      visible: !_isLoading,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Add New Todo'),
                                content: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(hintText: 'Enter todo item'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (_controller.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Please enter a todo item')),
                                        );
                                      } else {
                                        saveNewTask();
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Todo item added successfully')),
                                        );
                                      }
                                    },
                                    child: Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text('Add Todo'),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: toDoList.length,
                        itemBuilder: (BuildContext context, index) {
                          return TodoList(
                            taskName: toDoList[index][0],
                            taskCompleted: toDoList[index][1],
                            onChanged: (value) => checkBoxChanged(index),
                            deleteFunction: (context) => deleteTask(index),
                            editFunction: () => editTask(index),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

