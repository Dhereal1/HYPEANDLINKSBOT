import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiChatService {
  Future<String> ask({
    required List<Map<String, String>> messages,
  }) async {
    // Preferred names for current setup:
    // - BOT_API_URL
    // - BOT_API_KEY
    // Backward compatibility for previous deployments:
    // - AI_BACKEND_URL
    // - API_KEY
    final botApiUrl =
        (dotenv.env['BOT_API_URL'] ?? dotenv.env['AI_BACKEND_URL'] ?? '')
            .trim();
    final botApiKey =
        (dotenv.env['BOT_API_KEY'] ?? dotenv.env['API_KEY'] ?? '').trim();
    if (botApiUrl.isNotEmpty && botApiKey.isNotEmpty) {
      return _callBotApiDirect(
        botApiUrl: botApiUrl,
        botApiKey: botApiKey,
        messages: messages,
      );
    }
    return _callProxy(messages: messages);
  }

  Future<String> _callProxy({
    required List<Map<String, String>> messages,
  }) async {
    final uri = _resolveProxyEndpoint();
    final response = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'messages': messages}),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('AI proxy failed with status ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid AI proxy response payload');
    }
    final text = (decoded['response'] ?? '').toString().trim();
    if (text.isEmpty) {
      throw Exception('Empty AI response');
    }
    return text;
  }

  Future<String> _callBotApiDirect({
    required String botApiUrl,
    required String botApiKey,
    required List<Map<String, String>> messages,
  }) async {
    final uri =
        Uri.parse('${botApiUrl.replaceAll(RegExp(r"/+$"), "")}/api/chat');
    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': botApiKey,
          },
          body: jsonEncode({
            'messages': messages,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw Exception('BOT API failed with status ${response.statusCode}');
    }
    return _extractResponseFromNdjson(response.body);
  }

  String _extractResponseFromNdjson(String body) {
    var finalResponse = '';
    final lines = body.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      try {
        final parsed = jsonDecode(line);
        if (parsed is Map<String, dynamic>) {
          final responseText = (parsed['response'] ?? '').toString().trim();
          if (responseText.isNotEmpty) {
            finalResponse = responseText;
            continue;
          }
          final token = (parsed['token'] ?? '').toString();
          if (token.isNotEmpty && finalResponse.isEmpty) {
            finalResponse += token;
          }
        }
      } catch (_) {
        // Ignore malformed chunks.
      }
    }
    if (finalResponse.trim().isEmpty) {
      throw Exception('Empty AI response');
    }
    return finalResponse;
  }

  Uri _resolveProxyEndpoint() {
    final explicit = dotenv.env['AI_PROXY_URL']?.trim() ?? '';
    if (explicit.isNotEmpty) {
      return Uri.parse(explicit);
    }
    return Uri.base.resolve('/api/ai');
  }
}
