import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calendar_event_model.dart';
import '../providers/calendar_provider.dart';

// Create a provider to manage the selected day
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  CalendarEvent? _selectedEvent;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isEditing = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _focusedDay = ref.read(selectedDayProvider);

    // Initialize and load events
    _initializeCalendar();
  }

  Future<void> _initializeCalendar() async {
    // Load saved date from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedDateStr = prefs.getString('selected_calendar_date');

    if (savedDateStr != null) {
      final savedDate = DateTime.parse(savedDateStr);
      // Update both the focused day and the selected day provider
      setState(() {
        _focusedDay = savedDate;
      });
      ref.read(selectedDayProvider.notifier).state = savedDate;
    }

    // Load all calendar events
    await ref.read(calendarProvider.notifier).loadAllEvents();

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _startTime = null;
    _endTime = null;
    _selectedEvent = null;
    _isEditing = false;
  }

  Future<void> _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    // Update the UI
    setState(() {
      _focusedDay = focusedDay;
    });

    // Update the provider state
    ref.read(selectedDayProvider.notifier).state = selectedDay;

    // Save to SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'selected_calendar_date', selectedDay.toIso8601String());

    // Ensure events are loaded for this day
    ref.read(calendarProvider.notifier).ensureEventsLoadedForDay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show a loading indicator
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calendar'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Watch both calendar provider and selected day provider
    final calendarState = ref.watch(calendarProvider);
    final selectedDay = ref.watch(selectedDayProvider);

    // Get events for the selected day
    final selectedDayEvents =
        ref.read(calendarProvider.notifier).getEventsForDay(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            eventLoader: (day) =>
                ref.read(calendarProvider.notifier).getEventsForDay(day),
            onDaySelected: _onDaySelected,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markersAlignment: Alignment.bottomCenter,
            ),
          ),
          if (selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Events for ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  FilledButton.icon(
                    onPressed: () => _showEventForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Event'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedDayEvents.isEmpty
                  ? Center(
                      child: Text(
                        'No events for this day',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      itemCount: selectedDayEvents.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (context, index) {
                        final event = selectedDayEvents[index];
                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: event.isCompleted,
                              onChanged: (bool? value) {
                                event.isCompleted = value ?? false;
                                ref
                                    .read(calendarProvider.notifier)
                                    .updateEvent(event);
                              },
                            ),
                            title: Text(
                              event.title,
                              style: TextStyle(
                                decoration: event.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (event.description != null)
                                  Text(
                                    event.description!,
                                    style: TextStyle(
                                      decoration: event.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                if (event.startTime != null &&
                                    event.endTime != null)
                                  Text(
                                    '${TimeOfDay.fromDateTime(event.startTime!).format(context)} - '
                                    '${TimeOfDay.fromDateTime(event.endTime!).format(context)}',
                                  ),
                              ],
                            ),
                            onTap: () => _showEventForm(event: event),
                          ),
                        );
                      },
                    ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Text(
                  'Select a day to view or add events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Make sure to update the _showEventForm method to use the selectedDayProvider
  void _showEventForm({CalendarEvent? event}) {
    if (event != null) {
      _isEditing = true;
      _selectedEvent = event;
      _titleController.text = event.title;
      _descriptionController.text = event.description ?? '';
      _startTime = event.startTime;
      _endTime = event.endTime;
    } else {
      _resetForm();
    }

    // Use the selectedDayProvider instead of _selectedDay
    final selectedDay = ref.read(selectedDayProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Edit Event' : 'Add Event'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_startTime != null) {
                            // If time is already set, clicking again will clear it
                            setState(() {
                              _startTime = null;
                            });
                            return;
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null && selectedDay != null) {
                            setState(() {
                              _startTime = DateTime(
                                selectedDay.year,
                                selectedDay.month,
                                selectedDay.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_startTime == null
                            ? 'Start Time'
                            : TimeOfDay.fromDateTime(_startTime!)
                                .format(context)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_endTime != null) {
                            // If time is already set, clicking again will clear it
                            setState(() {
                              _endTime = null;
                            });
                            return;
                          }
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null && selectedDay != null) {
                            setState(() {
                              _endTime = DateTime(
                                selectedDay.year,
                                selectedDay.month,
                                selectedDay.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_endTime == null
                            ? 'End Time'
                            : TimeOfDay.fromDateTime(_endTime!)
                                .format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Add a text showing the selected date
                Text(
                  'Event will be added to: ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                ref
                    .read(calendarProvider.notifier)
                    .deleteEvent(_selectedEvent!.id);
                Navigator.pop(context);
                _resetForm();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                // Get the selected day from the provider
                final selectedDay = ref.read(selectedDayProvider);

                // Create a normalized date (without time) for the event's date
                final eventDate = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );

                final event = CalendarEvent(
                  id: _selectedEvent?.id ?? 0,
                  title: _titleController.text,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  startTime: _startTime,
                  endTime: _endTime,
                  isCompleted: _selectedEvent?.isCompleted ?? false,
                  date: eventDate, // Always use the normalized date from the selected day
                );

                if (_isEditing) {
                  event.id = _selectedEvent!.id;
                  ref.read(calendarProvider.notifier).updateEvent(event);
                } else {
                  ref.read(calendarProvider.notifier).addEvent(event);
                }

                Navigator.pop(context);
                _resetForm();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
