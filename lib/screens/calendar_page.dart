import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event_model.dart';
import '../providers/calendar_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarEvent? _selectedEvent;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calendarProvider.notifier).loadEventsForDay(_focusedDay);
    });
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
                          if (time != null && _selectedDay != null) {
                            setState(() {
                              _startTime = DateTime(
                                _selectedDay!.year,
                                _selectedDay!.month,
                                _selectedDay!.day,
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
                          if (time != null && _selectedDay != null) {
                            setState(() {
                              _endTime = DateTime(
                                _selectedDay!.year,
                                _selectedDay!.month,
                                _selectedDay!.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_endTime == null
                            ? 'End Time'
                            : TimeOfDay.fromDateTime(_endTime!).format(context)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                ref.read(calendarProvider.notifier).deleteEvent(_selectedEvent!.id);
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
                // If no time is selected, create event without time
                DateTime? effectiveStartTime = _startTime;
                DateTime? effectiveEndTime = _endTime;

                final event = CalendarEvent(
                  id: _selectedEvent?.id ?? 0,
                  title: _titleController.text,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  startTime: effectiveStartTime,
                  endTime: effectiveEndTime,
                  isCompleted: _selectedEvent?.isCompleted ?? false,
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

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(calendarProvider);
    final selectedDayEvents = _selectedDay == null
        ? []
        : ref.read(calendarProvider.notifier).getEventsForDay(_selectedDay!);

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
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) =>
                ref.read(calendarProvider.notifier).getEventsForDay(day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markersAlignment: Alignment.bottomCenter,
            ),
          ),
          if (_selectedDay != null) ...[  
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Events for ${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}',
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
                                ref.read(calendarProvider.notifier).updateEvent(event);
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
                                if (event.startTime != null && event.endTime != null)
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
}