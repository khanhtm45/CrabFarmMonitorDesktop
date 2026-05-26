import 'package:flutter/foundation.dart';

import '../data/mock_ai_assistant_data.dart';
import '../models/ai_assistant.dart';

class AiAssistantService extends ChangeNotifier {
  final List<AiChatMessage> _messages =
      List.of(MockAiAssistantData.initialChat(), growable: true);

  String _search = '';

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  String get overviewSummary => MockAiAssistantData.overviewSummary;
  List<AiInsightCard> get overviewKpi => MockAiAssistantData.overviewKpi();
  List<String> get quickPrompts => MockAiAssistantData.quickPrompts;
  List<AiRecommendation> get recommendations =>
      MockAiAssistantData.recommendations();
  List<AiAlertInsight> get aiAlerts => MockAiAssistantData.aiAlerts();

  List<AiRecommendation> get filteredRecommendations {
    if (_search.trim().isEmpty) return recommendations;
    final q = _search.toLowerCase();
    return recommendations
        .where(
          (r) =>
              r.title.toLowerCase().contains(q) ||
              r.module.toLowerCase().contains(q),
        )
        .toList();
  }

  void setSearch(String v) {
    _search = v;
    notifyListeners();
  }

  void sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    _messages.add(
      AiChatMessage(
        id: 'u-${now.millisecondsSinceEpoch}',
        isUser: true,
        text: trimmed,
        time: time,
      ),
    );

    _messages.add(
      AiChatMessage(
        id: 'a-${now.millisecondsSinceEpoch}',
        isUser: false,
        text: MockAiAssistantData.replyFor(trimmed),
        time: time,
      ),
    );
    notifyListeners();
  }

  void applyRecommendation(String id) {
    notifyListeners();
  }

  void dismissAlert(String id) {
    notifyListeners();
  }
}
