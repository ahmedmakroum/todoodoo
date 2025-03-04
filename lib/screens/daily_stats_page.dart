import 'package:flutter/material.dart';
import '../models/daily_stats_model.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class DailyStatsPage extends StatefulWidget {
  const DailyStatsPage({Key? key}) : super(key: key);

  @override
  _DailyStatsPageState createState() => _DailyStatsPageState();
}

class _DailyStatsPageState extends State<DailyStatsPage> {
  List<DailyStats> _stats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await DatabaseService().getDailyStats(limit: 7);
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayStats(DailyStats stats) {
    final dateStr = DateFormat('MMM d, y').format(stats.date);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            dateStr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildStatCard(
              'Tasks Done',
              stats.tasksDone.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatCard(
              'Focus Time',
              '${stats.focusMinutes} min',
              Icons.timer,
              Colors.blue,
            ),
            _buildStatCard(
              'Workouts',
              stats.workoutsCompleted.toString(),
              Icons.fitness_center,
              Colors.orange,
            ),
            _buildStatCard(
              'Net Calories',
              '${stats.caloriesConsumed - stats.caloriesBurned}',
              Icons.restaurant,
              Colors.red,
            ),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? const Center(
                  child: Text(
                    'No statistics available yet.\nComplete some tasks to see your progress!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: ListView.builder(
                    itemCount: _stats.length,
                    itemBuilder: (context, index) => _buildDayStats(_stats[index]),
                  ),
                ),
    );
  }
}
