import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/board_task_model.dart';
import '../services/database_service.dart';

final boardProvider = StateNotifierProvider<BoardNotifier, List<BoardTask>>((ref) {
  return BoardNotifier();
});

class BoardNotifier extends StateNotifier<List<BoardTask>> {
  BoardNotifier() : super([]);
  final _db = DatabaseService();

  Future<void> loadTasks() async {
    final tasks = await _db.getBoardTasks();
    state = tasks;
  }

  Future<void> addTask(BoardTask task) async {
    final maxPosition = state.fold<int>(0, (max, task) => task.position > max ? task.position : max);
    task.position = maxPosition + 1;
    final id = await _db.insertBoardTask(task);
    task.id = id;
    state = [...state, task];
  }

  Future<void> updateTask(BoardTask task) async {
    await _db.updateBoardTask(task);
    state = [
      for (final t in state)
        if (t.id == task.id) task else t
    ];
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteBoardTask(id);
    state = state.where((task) => task.id != id).toList();
  }

  Future<void> moveTask(BoardTask task, String newStatus) async {
    final oldStatus = task.status;
    if (oldStatus == newStatus) return;

    task.status = newStatus;
    await updateTask(task);
  }

  List<BoardTask> getTasksByStatus(String status) {
    return state.where((task) => task.status == status).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }
}
