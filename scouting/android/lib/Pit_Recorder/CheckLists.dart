import 'dart:convert';

class Checklist {
  String title;
  List<String> tasks;

  Checklist({required this.title, required this.tasks});

  // Convert Checklist to JSON
  String toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'tasks': tasks,
    };
    return json.encode(data);
  }

  // Convert JSON to Checklist
  factory Checklist.fromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    return Checklist(
      title: data['title'],
      tasks: List<String>.from(data['tasks']),
    );
  }
}

class TaskState {
  String task;
  bool isCompleted;

  TaskState({required this.task, this.isCompleted = false});

  factory TaskState.fromJson(Map<String, dynamic> json) {
    return TaskState(
      task: json['task'],
      isCompleted: json['isCompleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'isCompleted': isCompleted,
    };
  }
}
