// lib/widgets/enhanced_prediction_card.dart
import 'package:flutter/material.dart';
import 'package:ipl_win_predictor/theme/app_theme.dart';
import 'package:lottie/lottie.dart';

class EnhancedPredictionCard extends StatefulWidget {
  final double winProbability;
  final String predictionId;
  final Function(double) onFeedback;

  const EnhancedPredictionCard({
    super.key,
    required this.winProbability,
    required this.predictionId,
    required this.onFeedback,
  });

  @override
  State<EnhancedPredictionCard> createState() => _EnhancedPredictionCardState();
}

class _EnhancedPredictionCardState extends State<EnhancedPredictionCard>
    with SingleTickerProviderStateMixin {
  double? _feedback;
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winPercent = widget.winProbability * 100;
    final losePercent = 100 - winPercent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotateAnimation.value,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 8,
        shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildProbabilityGauge(winPercent),
                const SizedBox(height: 24),
                _buildProbabilityBars(winPercent, losePercent),
                const SizedBox(height: 24),
                _buildFeedbackSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Prediction',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on real-time match analysis',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProbabilityGauge(double winPercent) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 220,
          width: 220,
          child: CircularProgressIndicator(
            value: winPercent / 100,
            strokeWidth: 24,
            backgroundColor: Colors.red.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              winPercent > 60
                  ? AppTheme.successColor
                  : winPercent > 40
                      ? AppTheme.warningColor
                      : AppTheme.errorColor,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: winPercent),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) => Text(
                '${value.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chance to Win',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: winPercent > 60
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                winPercent > 60
                    ? 'High Chance'
                    : winPercent > 40
                        ? 'Balanced Match'
                        : 'Low Chance',
                style: TextStyle(
                  color: winPercent > 60
                      ? AppTheme.successColor
                      : winPercent > 40
                          ? AppTheme.warningColor
                          : AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProbabilityBars(double winPercent, double losePercent) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WIN', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  widthFactor: winPercent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${winPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LOSE', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  widthFactor: losePercent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.orange],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${losePercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Was this prediction accurate?',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        if (_isSubmitting)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          )
        else if (_feedback != null)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: Column(
              children: [
                Lottie.asset(
                  'assets/animations/checkmark.json',
                  height: 80,
                  repeat: false,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for your feedback!',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModernFeedbackButton(
                label: 'Accurate',
                value: 1.0,
                icon: Icons.check_circle,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 12),
              _buildModernFeedbackButton(
                label: 'Partial',
                value: 0.5,
                icon: Icons.trending_flat,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 12),
              _buildModernFeedbackButton(
                label: 'Inaccurate',
                value: 0.0,
                icon: Icons.cancel,
                color: AppTheme.errorColor,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildModernFeedbackButton({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          setState(() => _isSubmitting = true);
          await widget.onFeedback(value);
          setState(() {
            _feedback = value;
            _isSubmitting = false;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
