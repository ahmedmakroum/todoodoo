import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event_model.dart';
import '../services/database_service.dart';

// Define a class to hold all events, organized by date
class CalendarState {
  final Map<DateTime, List<CalendarEvent>> eventsByDate;
  final List<CalendarEvent> allEvents;

  CalendarState({
    required this.eventsByDate,
    required this.allEvents,
  });

  CalendarState copyWith({
    Map<DateTime, List<CalendarEvent>>? eventsByDate,
    List<CalendarEvent>? allEvents,
  }) {
    return CalendarState(
      eventsByDate: eventsByDate ?? this.eventsByDate,
      allEvents: allEvents ?? this.allEvents,
    );
  }
}

final calendarProvider =
    StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  return CalendarNotifier();
});

class CalendarNotifier extends StateNotifier<CalendarState> {
  CalendarNotifier() : super(CalendarState(eventsByDate: {}, allEvents: [])) {
    // We'll explicitly call loadAllEvents from the UI instead of here
    // to ensure the UI can properly react to the loaded events
  }

  final _db = DatabaseService();

  // Helper function to normalize date (remove time portion)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Load all events from the database
  Future<void> loadAllEvents() async {
    final allEventsFromDb = await _db.getAllCalendarEvents();
    final events = allEventsFromDb
        .map((e) => CalendarEvent(
              id: e['id'] as int,
              title: e['title'] as String,
              description: e['description'] as String?,
              startTime: e['start_time'] != null
                  ? DateTime.parse(e['start_time'] as String)
                  : null,
              endTime: e['end_time'] != null
                  ? DateTime.parse(e['end_time'] as String)
                  : null,
              date: DateTime.parse(e['date'] as String),
            ))
        .toList();

    // Group events by date
    final eventsByDate = <DateTime, List<CalendarEvent>>{};
    for (final event in events) {
      final normalizedDate = _normalizeDate(event.date);
      if (!eventsByDate.containsKey(normalizedDate)) {
        eventsByDate[normalizedDate] = [];
      }
      eventsByDate[normalizedDate]!.add(event);
    }

    // Update state with all events
    state = CalendarState(
      eventsByDate: eventsByDate,
      allEvents: events,
    );
  }

  // Ensure events for a specific day are loaded
  Future<void> ensureEventsLoadedForDay(DateTime date) async {
    final normalizedDate = _normalizeDate(date);

    // If we already have events for this day, return
    if (state.eventsByDate.containsKey(normalizedDate)) {
      return;
    }

    // Otherwise, load events for this day
    await loadEventsForDay(normalizedDate);
  }

  Future<void> loadEventsForDay(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    // Check if we already have events for this day
    if (state.eventsByDate.containsKey(normalizedDate)) {
      return; // Already loaded
    }

    final events = await _db.getCalendarEventsForDay(normalizedDate);
    final loadedEvents = events
        .map((e) => CalendarEvent(
              id: e['id'] as int,
              title: e['title'] as String,
              description: e['description'] as String?,
              startTime: e['start_time'] != null
                  ? DateTime.parse(e['start_time'] as String)
                  : null,
              endTime: e['end_time'] != null
                  ? DateTime.parse(e['end_time'] as String)
                  : null,
              date: DateTime.parse(e['date'] as String),
            ))
        .toList();

    // Update state with new events
    final updatedEventsByDate =
        Map<DateTime, List<CalendarEvent>>.from(state.eventsByDate);
    updatedEventsByDate[normalizedDate] = loadedEvents;

    final allEvents = List<CalendarEvent>.from(state.allEvents);
    allEvents.addAll(loadedEvents);

    state = state.copyWith(
      eventsByDate: updatedEventsByDate,
      allEvents: allEvents,
    );
  }

  Future<void> addEvent(CalendarEvent event) async {
    final id = await _db.insertCalendarEvent(event);
    event.id = id;

    final normalizedDate = _normalizeDate(event.date);

    // Update state with new event
    final updatedEventsByDate =
        Map<DateTime, List<CalendarEvent>>.from(state.eventsByDate);
    if (updatedEventsByDate.containsKey(normalizedDate)) {
      updatedEventsByDate[normalizedDate]!.add(event);
    } else {
      updatedEventsByDate[normalizedDate] = [event];
    }

    final allEvents = List<CalendarEvent>.from(state.allEvents)..add(event);

    state = state.copyWith(
      eventsByDate: updatedEventsByDate,
      allEvents: allEvents,
    );
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _db.updateCalendarEvent(event);

    final allEvents =
        state.allEvents.map((e) => e.id == event.id ? event : e).toList();

    // Create a new map to update events by date
    final updatedEventsByDate =
        Map<DateTime, List<CalendarEvent>>.from(state.eventsByDate);

    // Find the event in the map and update it
    for (final entry in updatedEventsByDate.entries) {
      final index = entry.value.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        final dateEvents = List<CalendarEvent>.from(entry.value);
        dateEvents[index] = event;
        updatedEventsByDate[entry.key] = dateEvents;
      }
    }

    state = state.copyWith(
      eventsByDate: updatedEventsByDate,
      allEvents: allEvents,
    );
  }

  Future<void> deleteEvent(int id) async {
    await _db.deleteCalendarEvent(id);

    // Remove event from all events list
    final allEvents = state.allEvents.where((event) => event.id != id).toList();

    // Remove event from events by date map
    final updatedEventsByDate =
        Map<DateTime, List<CalendarEvent>>.from(state.eventsByDate);
    for (final date in updatedEventsByDate.keys) {
      updatedEventsByDate[date] =
          updatedEventsByDate[date]!.where((event) => event.id != id).toList();
    }

    state = state.copyWith(
      eventsByDate: updatedEventsByDate,
      allEvents: allEvents,
    );
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    final normalizedDate = _normalizeDate(day);
    return state.eventsByDate[normalizedDate] ?? [];
  }
}
