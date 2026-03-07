import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<String> generateText(String prompt) async {
    const apiKey = "AIzaSyBqdVyA6jl-IOIeXHP_1W4Vb5A38iPU4t4";
    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final content = [Content.text(prompt)];

    try {
      final response = await model.generateContent(content);
      return response.toString();
    } catch (e) {
      throw Exception('Error while generating text: $e');
    }
  }

  static Future<String> getPredictions(String inputData) async {
    // Implement the logic for getPredictions here
    // For example, you can call generateText with the inputData
    return await generateText(inputData);
  }
}
