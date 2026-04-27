import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prediction.dart';

class ApiService {
  static const String baseUrl = 'https://ipl-win-predictor-erck.onrender.com';

  Future<PredictionResult> predictMatch({
    required double totalRuns,
    required int wicketsFallen,
    required int ballsBowled,
    required double targetRuns,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/predict');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'total_runs': totalRuns,
          'wickets_fallen': wicketsFallen,
          'balls_bowled': ballsBowled,
          'target_runs': targetRuns,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PredictionResult.fromJson(data);
      } else {
        throw Exception(
            'Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get prediction: $e');
    }
  }

  Future<void> submitFeedback(
      String docId, int actualResult, double userFeedback) async {
    try {
      final url = Uri.parse('$baseUrl/feedback');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'doc_id': docId,
          'actual_result': actualResult,
          'user_feedback': userFeedback,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit feedback: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
