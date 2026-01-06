import 'quiz_api.dart';

class Question {
  final String question;
  final List<String> options;
  final String correctAnswer;

  Question({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });

  // Convert API QuizQuestion to local Question model
  factory Question.fromApiQuestion(QuizQuestion apiQuestion) {
    return Question(
      question: apiQuestion.question,
      options: apiQuestion.options,
      correctAnswer: apiQuestion.correctAnswer,
    );
  }
}

class QuizData {
  static Future<List<Question>> getQuestions(
    String category,
    String difficulty,
  ) async {
    try {
      final apiQuestions = await QuizApiService.fetchQuestions(
        category,
        difficulty,
      );
      
      return apiQuestions
          .map((apiQ) => Question.fromApiQuestion(apiQ))
          .toList();
    } catch (e) {
      print('Error loading questions from API: $e');
      // Return empty list instead of fallback data
      return [];
    }
  }
}