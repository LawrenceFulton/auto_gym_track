import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/workout_repository.dart';
import '../../data/services/exercise_library.dart';
import '../../domain/models/set_entry.dart';

class ExerciseAnalyticsScreen extends StatefulWidget {
  const ExerciseAnalyticsScreen({super.key});

  @override
  State<ExerciseAnalyticsScreen> createState() => _ExerciseAnalyticsScreenState();
}

class _ExerciseAnalyticsScreenState extends State<ExerciseAnalyticsScreen> {
  String _selectedExercise = ExerciseLibrary.exerciseNames.first;
  List<SetEntry> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final repository = context.read<WorkoutRepository>();
    final history = await repository.getExerciseHistory(_selectedExercise);
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Progress')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: _selectedExercise),
              optionsBuilder: (textEditingValue) {
                return ExerciseLibrary.search(textEditingValue.text);
              },
              onSelected: (selection) {
                setState(() => _selectedExercise = selection);
                _loadHistory();
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Select Exercise',
                    suffixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(child: Text('No data for this exercise yet.'))
                    : _buildAnalytics(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    // Group sets by date and find max weight per session
    final dataPoints = <DateTime, double>{};
    for (final set in _history) {
      final date = DateTime(set.createdAt.year, set.createdAt.month, set.createdAt.day);
      if (!dataPoints.containsKey(date) || set.weight > dataPoints[date]!) {
        dataPoints[date] = set.weight;
      }
    }

    final sortedDates = dataPoints.keys.toList()..sort();
    final chartData = sortedDates.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), dataPoints[entry.value]!);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Max Weight over Time',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= sortedDates.length) return const SizedBox.shrink();
                        // Only show labels for first, middle, last to avoid crowding
                        if (sortedDates.length > 3) {
                          if (value.toInt() != 0 && 
                              value.toInt() != sortedDates.length - 1 && 
                              value.toInt() != (sortedDates.length / 2).floor()) {
                            return const SizedBox.shrink();
                          }
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MM/dd').format(sortedDates[value.toInt()]),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Session History',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[sortedDates.length - 1 - index];
                final maxWeight = dataPoints[date];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_note_rounded, size: 20),
                  title: Text(DateFormat('MMMM dd, yyyy').format(date)),
                  trailing: Text(
                    'Max: ${maxWeight?.toStringAsFixed(1)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
