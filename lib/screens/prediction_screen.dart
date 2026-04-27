// lib/screens/enhanced_prediction_screen.dart
import 'package:flutter/material.dart';
import 'package:ipl_win_predictor/models/prediction.dart';
import '../services/api_service.dart';
import '../widgets/prediction_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';
import '../theme/app_theme.dart';

class EnhancedPredictionScreen extends StatefulWidget {
  const EnhancedPredictionScreen({super.key});

  @override
  State<EnhancedPredictionScreen> createState() =>
      _EnhancedPredictionScreenState();
}

class _EnhancedPredictionScreenState extends State<EnhancedPredictionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _totalRunsController = TextEditingController();
  final _wicketsController = TextEditingController();
  final _ballsController = TextEditingController();
  final _targetController = TextEditingController();

  bool _isLoading = false;
  PredictionResult? _result;
  String _currentPredictionId = '';
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
  }

  Future<void> _predict() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _result = null;
        _currentPredictionId = '';
      });

      try {
        final apiService = ApiService();
        final result = await apiService.predictMatch(
          totalRuns: double.parse(_totalRunsController.text),
          wicketsFallen: int.parse(_wicketsController.text),
          ballsBowled: int.parse(_ballsController.text),
          targetRuns: double.parse(_targetController.text),
        );

        setState(() {
          _result = result;
          _currentPredictionId = result.predictionId;
          _isLoading = false;
        });
        _fadeController.forward(from: 0.0);
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _handleFeedback(double feedback) async {
    if (_currentPredictionId.isEmpty) {
      _showSnackBar('Error: No prediction ID found', isError: true);
      return;
    }

    try {
      final apiService = ApiService();
      await apiService.submitFeedback(
        _currentPredictionId,
        feedback >= 0.5 ? 1 : 0,
        feedback,
      );
      _showSnackBar('Thank you for your feedback!', isError: false);
    } catch (e) {
      _showSnackBar('Feedback error: $e', isError: true);
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _totalRunsController.clear();
    _wicketsController.clear();
    _ballsController.clear();
    _targetController.clear();
    setState(() {
      _result = null;
      _currentPredictionId = '';
    });
    _fadeController.reset();
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: _buildInputCard(),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading) _buildLoadingShimmer(),
                  if (_result != null && !_isLoading)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: EnhancedPredictionCard(
                        winProbability: _result!.winProbability,
                        predictionId: _currentPredictionId,
                        onFeedback: _handleFeedback,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the current match statistics',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _totalRunsController,
                label: 'Current Total Runs',
                icon: Icons.score,
                hint: 'e.g., 150',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter runs';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _wicketsController,
                label: 'Wickets Fallen',
                icon: Icons.sports_cricket,
                hint: '0-10',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter wickets';
                  final wickets = int.tryParse(value);
                  if (wickets == null || wickets < 0 || wickets > 10) {
                    return 'Wickets must be 0-10';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ballsController,
                label: 'Balls Bowled',
                icon: Icons.timer,
                hint: '0-120',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter balls';
                  final balls = int.tryParse(value);
                  if (balls == null || balls < 0 || balls > 120) {
                    return 'Balls must be 0-120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _targetController,
                label: 'Target Runs',
                icon: Icons.flag,
                hint: 'e.g., 200',
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter target';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _predict,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Analyze Match'),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.number,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _totalRunsController.dispose();
    _wicketsController.dispose();
    _ballsController.dispose();
    _targetController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
