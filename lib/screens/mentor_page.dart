import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import '../models/mentor_message.dart';
import '../services/mentor_service.dart';
import '../services/theme_controller.dart';

// MentorPage is stateful so it can have a TextEditingController (read/clear text field)
// and a local state flag _sending to disable send button
class MentorPage extends StatefulWidget {
  const MentorPage({super.key});

  @override
  State<MentorPage> createState() => _MentorPageState();
}

class _MentorPageState extends State<MentorPage> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await MentorService.sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mentor is unavailable: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.watch<ThemeController>().accentColor;
    // Explicit padding for input bar, so it sits above navbar
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 28, 20, 12),
            child: Text(
              'Mentor',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
                letterSpacing: -1,
              ),
            ),
          ),
          Expanded(
            // Automatic UI updates via StreamBuilder
            child: StreamBuilder<List<MentorMessage>>(
              // Live updating list from firestore
              stream: MentorService.messagesStream(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: accentColor),
                  );
                }
                final messages = snap.data!;
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Let Mentor help you plan your next journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[400],
                          height: 1.3,
                        ),
                      ),
                    ),
                  );
                }
                final reversed = messages.reversed.toList();
                return ListView.builder(
                  // Reverse chronological message order
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: reversed.length,
                  itemBuilder: (ctx, i) => _MessageBubble(
                    message: reversed[i],
                    accentColor: accentColor,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad + 30),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message Mentor…',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MentorMessage message;
  final Color accentColor;
  const _MessageBubble({required this.message, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    // Align bubbles based on role
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: const TextStyle(
                    fontSize: 15, height: 1.4, color: Colors.white),
              )
            : MarkdownBody(
                data: message.text,
                shrinkWrap: true,
                softLineBreak: true,
                styleSheet: _mentorMarkdownStyle,
              ),
      ),
    );
  }
}

final _mentorBaseTextStyle =
    const TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF1A1A1A));

final _mentorMarkdownStyle = MarkdownStyleSheet(
  p: _mentorBaseTextStyle,
  strong: _mentorBaseTextStyle.copyWith(fontWeight: FontWeight.w700),
  em: _mentorBaseTextStyle.copyWith(fontStyle: FontStyle.italic),
  h1: _mentorBaseTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
  h2: _mentorBaseTextStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
  h3: _mentorBaseTextStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
  listBullet: _mentorBaseTextStyle,
);
