import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List listTodo = [];
  late Map<String, dynamic> lastRemoved;
  late int indexLastRemoved;
  TextEditingController titleController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        listTodo = json.decode(data);
      });
    });
  }

  late var formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Lista de Tarefas",
              style: TextStyle(
                color: Colors.blueAccent,
              )),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Titulo",
                              labelStyle: TextStyle(color: Colors.blueAccent)),
                          validator: (String? value) {
                            if (value.toString().isEmpty || value == null) {
                              return "Titulo não pode ser vazio vazio";
                            }
                            return null;
                          },
                        )),
                  ),
                  Expanded(
                    flex: 1,
                    child: Ink(
                      decoration: const ShapeDecoration(
                          shape: CircleBorder(), color: Colors.green),
                      child: IconButton(
                        onPressed: () => onAddTodo(),
                        icon: const Icon(Icons.add),
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 10.0),
                itemCount: listTodo.length,
                itemBuilder: (context, index) {
                  final todo = listTodo[index];
                  return Dismissible(
                      key: Key(todo["id"]),
                      background: Container(
                        color: Colors.red,
                        child: const Align(
                            alignment: Alignment(-0.9, 0.0),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            )),
                      ),
                      direction: DismissDirection.startToEnd,
                      onDismissed: (direction) {
                        setState(() {
                          lastRemoved = Map.from(listTodo[index]);
                          indexLastRemoved = index;
                          listTodo.removeAt(index);

                          _saveData();
                        });
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text("Tarefa ${lastRemoved["name"]} removida!"),
                          action: SnackBarAction(
                            label: "Desfazer",
                            onPressed: () {
                              setState(() {
                                listTodo.insert(indexLastRemoved, lastRemoved);
                              });
                            },
                          ),
                          duration: const Duration(seconds: 4),
                        ));
                      },
                      child: CheckboxListTile(
                        title: Text(todo["name"]),
                        value: todo["completed"],
                        secondary: todo["completed"]
                            ? const Icon(Icons.check)
                            : const Icon(Icons.error),
                        onChanged: (check) {
                          setState(() {
                            todo["completed"] = check;
                            _saveData();
                          });
                        },
                      ));
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  void onAddTodo() {
    if (formKey.currentState!.validate()) {
      setState(() {
        Map<String, dynamic> newTodo = Map();
        newTodo["id"] = const Uuid().v4().toString();
        newTodo["name"] = titleController.text;
        newTodo["completed"] = false;
        listTodo.add(newTodo);
        titleController.text = "";
        _saveData();
      });
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(listTodo);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return e.toString();
    }
  }

  Future<Null> refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      listTodo.sort((a, b) {
        if (a["completed"] && !b["completed"]) {
          return 1;
        } else if (!a["completed"] && b["completed"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
  }
}
