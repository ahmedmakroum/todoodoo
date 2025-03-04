import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event_model.dart';
import '../services/database_service.dart';

final calendarProvider = StateNotifierProvider<CalendarNotifier, List<CalendarEvent>>((ref) {
  return CalendarNotifier();
});

class CalendarNotifier extends StateNotifier<List<CalendarEvent>> {
  CalendarNotifier() : super([]);
  final _db = DatabaseService();

  Future<void> loadEventsForDay(DateTime date) async {
    final events = await _db.getCalendarEventsForDay(date);
    state = events.map((e) => CalendarEvent(
      id: e['id'] as int,
      title: e['title'] as String,
      description: e['description'] as String?,
      startTime: e['start_time'] != null ? DateTime.parse(e['start_time'] as String) : null,
      endTime: e['end_time'] != null ? DateTime.parse(e['end_time'] as String) : null,
    )).toList();
  }

  Future<void> addEvent(CalendarEvent event) async {
    final id = await _db.insertCalendarEvent(event);
    event.id = id;
    await loadEventsForDay(event.startTime ?? DateTime.now());
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _db.updateCalendarEvent(event);
    await loadEventsForDay(event.startTime ?? DateTime.now());
  }

  Future<void> deleteEvent(int id) async {
    await _db.deleteCalendarEvent(id);
    if (state.isNotEmpty) {
      await loadEventsForDay(state.first.startTime ?? DateTime.now());
    }
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return state.where((event) {
      if (event.startTime == null) return false;
      return event.startTime!.year == day.year &&
             event.startTime!.month == day.month &&
             event.startTime!.day == day.day;
    }).toList();
  }
}
