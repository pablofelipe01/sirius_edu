import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Burbuja de mensaje estilo chat para conversaciones con IA.
/// Long-press o botón de copiar en mensajes de IA.
class AIMessageBubble extends StatelessWidget {
  final String text;
  final bool isFromAI;
  final String time;
  final bool isLoading;

  const AIMessageBubble({
    super.key,
    required this.text,
    required this.isFromAI,
    this.time = '',
    this.isLoading = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado'),
        backgroundColor: Color(0xFF27AE60),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isFromAI)
              Container(
                margin: const EdgeInsets.only(right: 6, bottom: 4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2980B9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
            Flexible(
              child: GestureDetector(
                onLongPress: isFromAI && !isLoading ? () => _copyToClipboard(context) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFromAI
                        ? const Color(0xFFE8F4FD)
                        : const Color(0xFFE8F8E8),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isFromAI ? 4 : 16),
                      bottomRight: Radius.circular(isFromAI ? 16 : 4),
                    ),
                  ),
                  child: isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF2980B9).withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Escribiendo...',
                              style: TextStyle(
                                color: const Color(0xFF2980B9).withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF2C3E50),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isFromAI)
                                  GestureDetector(
                                    onTap: () => _copyToClipboard(context),
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: Icon(Icons.copy, size: 14, color: Color(0xFF95A5A6)),
                                    ),
                                  ),
                                if (time.isNotEmpty)
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF95A5A6),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
