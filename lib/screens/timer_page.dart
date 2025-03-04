import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import '../services/focus_mode_service.dart';
import '../providers/theme_provider.dart';
import '../providers/focus_mode_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;

class TimerPage extends ConsumerStatefulWidget {
  final Function(int duration) onSessionComplete;

  const TimerPage({
    Key? key,
    required this.onSessionComplete,
  }) : super(key: key);

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> {
  // Timer Logic
  int totalWorkTime = 1500; // 25 minutes default
  int remainingTime = 1500;
  double progress = 0.0;
  bool isRunning = false;
  Timer? _timer;
  
  // Session tracking
  DateTime? sessionStartTime;
  int totalSessionTime = 0;
  
  // For tracking completed sessions
  List<Map<String, dynamic>> sessions = [];

  // Notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    loadSessionHistory();
  }

  Future<void> initializeNotifications() async {
    if (Platform.isLinux) {
      // Linux specific initialization
      const LinuxInitializationSettings linuxInitializationSettings =
          LinuxInitializationSettings(
        defaultActionName: 'Open notification',
        defaultIcon: null,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        linux: linuxInitializationSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
    } else if (Platform.isAndroid) {
      // Android specific initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
    }
    // Add other platform specific initializations as needed
  }
  
  Future<void> loadSessionHistory() async {
    try {
      final db = await FocusSessionService().database;
      final List<Map<String, dynamic>> results = await db.query(
        'FocusSessions',
        orderBy: 'start_time DESC',
        where: 'start_time >= ?',
        whereArgs: [DateTime.now().subtract(const Duration(hours: 24)).toIso8601String()],
      );
      
      setState(() {
        sessions = results;
      });
    } catch (e) {
      debugPrint('Error loading focus sessions: $e');
    }
  }

  void _startTimer() {
    if (_timer == null || !_timer!.isActive) {
      setState(() {
        if (!isRunning) {
          sessionStartTime = DateTime.now();
        }
      });
      
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (remainingTime > 0 && isRunning) {
          setState(() {
            remainingTime--;
            progress = 1 - (remainingTime / totalWorkTime);
          });
        } else if (remainingTime <= 0) {
          _completeSession();
        }
      });
    }
    setState(() {
      isRunning = true;
    });
  }

  void _stopTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    
    if (isRunning) {
      // Calculate and store the session time so far
      if (sessionStartTime != null) {
        final now = DateTime.now();
        final sessionDuration = now.difference(sessionStartTime!).inSeconds;
        totalSessionTime += sessionDuration;
        // Update the start time to now (in case we resume)
        sessionStartTime = now;
      }
    }
    
    setState(() {
      isRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      remainingTime = totalWorkTime;
      progress = 0.0;
      totalSessionTime = 0;
      sessionStartTime = null;
    });
  }
  
  void _completeSession() async {
    _stopTimer();
    
    final sessionDuration = totalWorkTime - remainingTime + totalSessionTime;
    
    try {
      // Save session to database
      final db = await FocusSessionService().database;
      await db.insert('FocusSessions', {
        'start_time': sessionStartTime?.toIso8601String(),
        'end_time': DateTime.now().toIso8601String(),
        'duration_seconds': sessionDuration,
      });
      
      // Reload sessions to show the new one
      await loadSessionHistory();
      
      // Call the callback to update stats on HomePage
      widget.onSessionComplete(sessionDuration);
      
      _showTimeUpDialog(context as BuildContext);
      _resetTimer();
    } catch (e) {
      debugPrint('Error saving focus session: $e');
    }
  }

  void _showTimeUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time\'s Up!'),
          content: const Text('Your focus session is complete.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showTimerSettingsDialog(BuildContext context) {
    int selectedHours = totalWorkTime ~/ 3600;
    int selectedMinutes = (totalWorkTime % 3600) ~/ 60;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Set Timer'),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Hours'),
                      IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () {
                          setState(() {
                            if (selectedHours < 23) selectedHours++;
                          });
                        },
                      ),
                      Text('$selectedHours'),
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          setState(() {
                            if (selectedHours > 0) selectedHours--;
                          });
                        },
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Minutes'),
                      IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes < 59) selectedMinutes++;
                          });
                        },
                      ),
                      Text('$selectedMinutes'),
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes > 0) selectedMinutes--;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final newTotalTime = (selectedHours * 3600) + (selectedMinutes * 60);
                    if (newTotalTime > 0) {
                      // Update in the parent widget too
                      this.setState(() {
                        totalWorkTime = newTotalTime;
                        remainingTime = totalWorkTime;
                        progress = 0.0;
                      });
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text('Set'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return "$hours h ${minutes > 0 ? '$minutes min' : ''}";
    } else {
      return "$minutes min";
    }
  }

  @override
  Widget build(BuildContext context) {
    final int hours = remainingTime ~/ 3600;
    final int minutes = (remainingTime % 3600) ~/ 60;
    final int seconds = remainingTime % 60;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Timer Display
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'Focus Timer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 24),
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (totalSessionTime > 0)
                                  Text(
                                    "Session: ${_formatDuration(totalSessionTime + (totalWorkTime - remainingTime))}",
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isRunning ? _stopTimer : _startTimer,
                            icon: Icon(isRunning ? Icons.pause : Icons.play_arrow),
                            label: Text(isRunning ? 'Pause' : 'Start'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _resetTimer,
                            icon: Icon(Icons.refresh),
                            label: Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showTimerSettingsDialog(context),
                        icon: Icon(Icons.settings),
                        label: Text('Timer Settings'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Session History
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Focus Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: sessions.isEmpty
                              ? Center(
                                  child: Text(
                                    'No focus sessions yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: sessions.length,
                                  itemBuilder: (context, index) {
                                    final session = sessions[index];
                                    final startTime = DateTime.parse(session['start_time'] as String);
                                    final duration = session['duration_seconds'] as int;
                                    return ListTile(
                                      leading: Icon(Icons.timer),
                                      title: Text(DateFormat('MMM d, h:mm a').format(startTime)),
                                      subtitle: Text('Duration: ${_formatDuration(duration)}'),
                                      trailing: Icon(Icons.check_circle, color: Colors.green),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}