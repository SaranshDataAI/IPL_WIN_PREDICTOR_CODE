// lib/screens/enhanced_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ipl_win_predictor/theme/app_theme.dart';

class EnhancedHistoryScreen extends StatelessWidget {
  const EnhancedHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match History'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history), text: 'Records'),
              Tab(icon: Icon(Icons.show_chart), text: 'Analytics'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryList(),
            _buildAnalyticsDashboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('predictions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final predictions = snapshot.data?.docs ?? [];

        if (predictions.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final data = predictions[index].data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final winProb = (data['predicted_probability'] as num).toDouble();
            final isWin = data['actual_result'] == 1;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  onTap: () => _showPredictionDetails(context, data),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    winProb > 0.5
                                        ? AppTheme.successColor
                                        : AppTheme.errorColor,
                                    winProb > 0.5
                                        ? AppTheme.successColor.withOpacity(0.7)
                                        : AppTheme.errorColor.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${(winProb * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['total_runs']}/${data['wickets_fallen']} vs ${data['target_runs']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp != null
                                        ? DateFormat('MMM dd, yyyy • hh:mm a')
                                            .format(timestamp)
                                        : 'Date unknown',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (data['actual_result'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isWin
                                      ? AppTheme.successColor.withOpacity(0.1)
                                      : AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isWin ? Icons.check : Icons.close,
                                      color: isWin
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isWin ? 'Won' : 'Lost',
                                      style: TextStyle(
                                        color: isWin
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: winProb,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            winProb > 0.5
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsDashboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('predictions').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final predictions = snapshot.data!.docs;
        final totalPredictions = predictions.length;
        final correctPredictions = predictions.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['actual_result'] == null) return false;
          final predicted = (data['predicted_probability'] as num).toDouble();
          final actual = data['actual_result'] as int;
          return (predicted > 0.5 && actual == 1) ||
              (predicted <= 0.5 && actual == 0);
        }).length;

        final accuracy = totalPredictions > 0
            ? (correctPredictions / totalPredictions * 100)
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatsCards(totalPredictions, correctPredictions, accuracy),
              const SizedBox(height: 24),
              _buildAccuracyChart(predictions),
              const SizedBox(height: 24),
              _buildPredictionDistribution(predictions),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCards(int total, int correct, double accuracy) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Predictions',
            total.toString(),
            Icons.analytics,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Correct',
            correct.toString(),
            Icons.check_circle,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Accuracy',
            '${accuracy.toStringAsFixed(1)}%',
            Icons.trending_up,
            AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyChart(List<QueryDocumentSnapshot> predictions) {
    final List<double> accuracies = [];
    for (int i = 0; i < predictions.length && i < 10; i++) {
      final data = predictions[i].data() as Map<String, dynamic>;
      if (data['actual_result'] != null) {
        final predicted = (data['predicted_probability'] as num).toDouble();
        final actual = data['actual_result'] as int;
        final isCorrect = (predicted > 0.5 && actual == 1) ||
            (predicted <= 0.5 && actual == 0);
        accuracies.add(isCorrect ? 100.0 : 0.0);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Predictions Accuracy',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt() + 1}');
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(accuracies.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: accuracies[i],
                          color: accuracies[i] == 100
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionDistribution(List<QueryDocumentSnapshot> predictions) {
    int high = 0, medium = 0, low = 0;

    for (var doc in predictions) {
      final data = doc.data() as Map<String, dynamic>;
      final prob = (data['predicted_probability'] as num).toDouble();
      if (prob > 0.66) {
        high++;
      } else if (prob > 0.33)
        medium++;
      else
        low++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prediction Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: high.toDouble(),
                      title: 'High',
                      color: AppTheme.successColor,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: medium.toDouble(),
                      title: 'Medium',
                      color: AppTheme.warningColor,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: low.toDouble(),
                      title: 'Low',
                      color: AppTheme.errorColor,
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: [
                _buildLegend('High Chance (>66%)', AppTheme.successColor),
                _buildLegend('Medium Chance (33-66%)', AppTheme.warningColor),
                _buildLegend('Low Chance (<33%)', AppTheme.errorColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No predictions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make your first prediction to see history',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPredictionDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Match Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Total Runs', '${data['total_runs']}'),
              _buildDetailRow('Wickets Fallen', '${data['wickets_fallen']}'),
              _buildDetailRow('Target Runs', '${data['target_runs']}'),
              _buildDetailRow('Balls Remaining', '${data['balls_remaining']}'),
              _buildDetailRow('Current Run Rate',
                  (data['current_run_rate'] as num).toStringAsFixed(2)),
              _buildDetailRow('Required Run Rate',
                  (data['required_run_rate'] as num).toStringAsFixed(2)),
              const Divider(),
              _buildDetailRow('Predicted Chance',
                  '${((data['predicted_probability'] as num) * 100).toStringAsFixed(1)}%'),
              if (data['actual_result'] != null)
                _buildDetailRow('Actual Result',
                    data['actual_result'] == 1 ? 'Won ✓' : 'Lost ✗'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
