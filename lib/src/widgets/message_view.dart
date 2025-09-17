/*
 * Copyright (c) 2022 Simform Solutions
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
import 'package:chatview/chatview.dart';
import 'package:chatview_utils/chatview_utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../extensions/extensions.dart';
import '../models/chat_bubble.dart';
import '../models/config_models/message_configuration.dart';
import '../utils/constants/constants.dart';
import '../values/typedefs.dart';
import 'chat_view_inherited_widget.dart';
import 'image_message_view.dart';
import 'reaction_widget.dart';
import 'text_message_view.dart';
import 'voice_message_view.dart';

class MessageView extends StatefulWidget {
  const MessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    required this.onLongPress,
    required this.isLongPressEnable,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.longPressAnimationDuration,
    this.onDoubleTap,
    this.highlightColor = Colors.grey,
    this.shouldHighlight = false,
    this.highlightScale = 1.2,
    this.messageConfig,
    this.onMaxDuration,
    this.controller,
  }) : super(key: key);

  /// Provides message instance of chat.
  final Message message;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Give callback once user long press on chat bubble.
  final DoubleCallBack onLongPress;

  /// Allow users to give max width of chat bubble.
  final double? chatBubbleMaxWidth;

  /// Provides configuration of chat bubble appearance from other user of chat.
  final ChatBubble? inComingChatBubbleConfig;

  /// Provides configuration of chat bubble appearance from current user of chat.
  final ChatBubble? outgoingChatBubbleConfig;

  /// Allow users to give duration of animation when user long press on chat bubble.
  final Duration? longPressAnimationDuration;

  /// Allow user to set some action when user double tap on chat bubble.
  final ValueSetter<Message>? onDoubleTap;

  /// Allow users to pass colour of chat bubble when user taps on replied message.
  final Color highlightColor;

  /// Allow users to turn on/off highlighting chat bubble when user tap on replied message.
  final bool shouldHighlight;

  /// Provides scale of highlighted image when user taps on replied image.
  final double highlightScale;

  /// Allow user to giving customisation different types
  /// messages.
  final MessageConfiguration? messageConfig;

  /// Allow user to turn on/off long press tap on chat bubble.
  final bool isLongPressEnable;

  final ChatController? controller;

  final ValueSetter<int>? onMaxDuration;

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;

  MessageConfiguration? get messageConfig => widget.messageConfig;

  bool get isLongPressEnable => widget.isLongPressEnable;

  @override
  void initState() {
    super.initState();
    if (isLongPressEnable) {
      _animationController = AnimationController(
        vsync: this,
        duration: widget.longPressAnimationDuration ??
            const Duration(milliseconds: 250),
        upperBound: 0.1,
        lowerBound: 0.0,
      );

      _animationController?.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController?.reverse();
        }
      });
    }
    if (widget.message.status != MessageStatus.read &&
        !widget.isMessageBySender) {
      widget.inComingChatBubbleConfig?.onMessageRead?.call(widget.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: isLongPressEnable ? _onLongPressStart : null,
      onDoubleTap: () {
        if (widget.onDoubleTap != null) widget.onDoubleTap!(widget.message);
      },
      child: (() {
        if (isLongPressEnable) {
          return AnimatedBuilder(
            builder: (_, __) {
              return Transform.scale(
                scale: 1 - _animationController!.value,
                child: _messageView,
              );
            },
            animation: _animationController!,
          );
        } else {
          return _messageView;
        }
      }()),
    );
  }

  Widget get _messageView {
    final message = widget.message.message;
    final emojiMessageConfiguration = messageConfig?.emojiMessageConfig;
    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.message.reaction.reactions.isNotEmpty ? 6 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          (() {
                if (message.isAllEmoji) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: emojiMessageConfiguration?.padding ??
                            EdgeInsets.fromLTRB(
                              leftPadding2,
                              4,
                              leftPadding2,
                              widget.message.reaction.reactions.isNotEmpty
                                  ? 14
                                  : 0,
                            ),
                        child: Transform.scale(
                          scale: widget.shouldHighlight
                              ? widget.highlightScale
                              : 1.0,
                          child: Text(
                            message,
                            style: emojiMessageConfiguration?.textStyle ??
                                const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                      if (widget.message.reaction.reactions.isNotEmpty)
                        ReactionWidget(
                          reaction: widget.message.reaction,
                          messageReactionConfig:
                              messageConfig?.messageReactionConfig,
                          isMessageBySender: widget.isMessageBySender,
                        ),
                    ],
                  );
                } else if (widget.message.messageType.isImage) {
                  return ImageMessageView(
                    message: widget.message,
                    isMessageBySender: widget.isMessageBySender,
                    imageMessageConfig: messageConfig?.imageMessageConfig,
                    messageReactionConfig: messageConfig?.messageReactionConfig,
                    highlightImage: widget.shouldHighlight,
                    highlightScale: widget.highlightScale,
                  );
                } else if (widget.message.messageType.isText) {
                  return EnhancedTextMessageView(
                    inComingChatBubbleConfig: widget.inComingChatBubbleConfig,
                    outgoingChatBubbleConfig: widget.outgoingChatBubbleConfig,
                    isMessageBySender: widget.isMessageBySender,
                    message: widget.message,
                    chatBubbleMaxWidth: widget.chatBubbleMaxWidth,
                    messageReactionConfig: messageConfig?.messageReactionConfig,
                    highlightColor: widget.highlightColor,
                    highlightMessage: widget.shouldHighlight,
                  );
                } else if (widget.message.messageType.isVoice) {
                  return VoiceMessageView(
                    screenWidth: MediaQuery.of(context).size.width,
                    message: widget.message,
                    config: messageConfig?.voiceMessageConfig,
                    onMaxDuration: widget.onMaxDuration,
                    isMessageBySender: widget.isMessageBySender,
                    messageReactionConfig: messageConfig?.messageReactionConfig,
                    inComingChatBubbleConfig: widget.inComingChatBubbleConfig,
                    outgoingChatBubbleConfig: widget.outgoingChatBubbleConfig,
                  );
                } else if (widget.message.messageType.isCustom &&
                    messageConfig?.customMessageBuilder != null) {
                  return messageConfig?.customMessageBuilder!(widget.message);
                }
              }()) ??
              const SizedBox(),
          ValueListenableBuilder(
            valueListenable: widget.message.statusNotifier,
            builder: (context, value, child) {
              if (widget.isMessageBySender &&
                  widget.controller?.initialMessageList.last.id ==
                      widget.message.id &&
                  widget.message.status == MessageStatus.read) {
                if (ChatViewInheritedWidget.of(context)
                        ?.featureActiveConfig
                        .lastSeenAgoBuilderVisibility ??
                    true) {
                  return widget.outgoingChatBubbleConfig?.receiptsWidgetConfig
                          ?.lastSeenAgoBuilder
                          ?.call(
                              widget.message,
                              applicationDateFormatter(
                                  widget.message.createdAt)) ??
                      lastSeenAgoBuilder(widget.message,
                          applicationDateFormatter(widget.message.createdAt));
                }
                return const SizedBox();
              }
              return const SizedBox();
            },
          )
        ],
      ),
    );
  }

  void _onLongPressStart(LongPressStartDetails details) async {
    await _animationController?.forward();
    widget.onLongPress(
      details.globalPosition.dy,
      details.globalPosition.dx,
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
}

// Enhanced TextMessageView to handle URLs
class EnhancedTextMessageView extends StatelessWidget {
  const EnhancedTextMessageView({
    Key? key,
    required this.message,
    required this.isMessageBySender,
    this.chatBubbleMaxWidth,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.messageReactionConfig,
    this.highlightColor = Colors.grey,
    this.highlightMessage = false,
  }) : super(key: key);

  final Message message;
  final bool isMessageBySender;
  final double? chatBubbleMaxWidth;
  final ChatBubble? inComingChatBubbleConfig;
  final ChatBubble? outgoingChatBubbleConfig;
  final MessageReactionConfiguration? messageReactionConfig;
  final Color highlightColor;
  final bool highlightMessage;

  @override
  Widget build(BuildContext context) {
    final textStyle = isMessageBySender
        ? outgoingChatBubbleConfig?.textStyle
        : inComingChatBubbleConfig?.textStyle;
    final color = isMessageBySender
        ? outgoingChatBubbleConfig?.color
        : inComingChatBubbleConfig?.color;

    // Parse the message for URLs and image markers
    final messageContent = _parseMessageContent(message.message);

    return Container(
      constraints: BoxConstraints(
        maxWidth: chatBubbleMaxWidth ?? double.infinity,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlightMessage ? highlightColor : color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...messageContent,
          if (message.reaction.reactions.isNotEmpty)
            ReactionWidget(
              reaction: message.reaction,
              messageReactionConfig: messageReactionConfig,
              isMessageBySender: isMessageBySender,
            ),
        ],
      ),
    );
  }

  List<Widget> _parseMessageContent(String text) {
    final List<Widget> content = [];
    final lines = text.split('\n');

    final urlRegex = RegExp(r'(https?://[^\s<>"\)]+)');
    final validImageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];

    bool _isImageUrl(String url) {
      return validImageExtensions.any(
        (ext) => url.toLowerCase().endsWith(ext),
      );
    }

    for (var line in lines) {
      if (line.trim().isEmpty) {
        content.add(const SizedBox(height: 4));
        continue;
      }

      // 🔹 Remove known prefixes before processing
      line = line.trim();
      if (line.toLowerCase().startsWith("image:")) {
        line = line.substring(6).trim();
      } else if (line.toLowerCase().startsWith("link:")) {
        line = line.substring(5).trim();
      }

      final urlMatches = urlRegex.allMatches(line);
      if (urlMatches.isEmpty) {
        // Just plain text
        content.add(
          Text(
            line,
            style: isMessageBySender
                ? outgoingChatBubbleConfig?.textStyle
                : inComingChatBubbleConfig?.textStyle,
          ),
        );
        continue;
      }

      // Process line containing URLs
      int lastIndex = 0;
      final List<InlineSpan> spans = [];

      for (final match in urlMatches) {
        if (match.start > lastIndex) {
          spans.add(
            TextSpan(
              text: line.substring(lastIndex, match.start),
              style: isMessageBySender
                  ? outgoingChatBubbleConfig?.textStyle
                  : inComingChatBubbleConfig?.textStyle,
            ),
          );
        }

        final rawUrl = match.group(0)!;
        final cleanUrl = _cleanUrl(rawUrl);

        if (_isImageUrl(cleanUrl)) {
          // ✅ render image widget instead of showing text
          content.add(_buildImageWidget(cleanUrl));
        } else {
          // clickable link
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => _launchUrl(cleanUrl),
                child: Text(
                  cleanUrl,
                  style: (isMessageBySender
                          ? outgoingChatBubbleConfig?.textStyle
                          : inComingChatBubbleConfig?.textStyle)
                      ?.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          );
        }

        lastIndex = match.end;
      }

      if (lastIndex < line.length) {
        spans.add(
          TextSpan(
            text: line.substring(lastIndex),
            style: isMessageBySender
                ? outgoingChatBubbleConfig?.textStyle
                : inComingChatBubbleConfig?.textStyle,
          ),
        );
      }

      if (spans.isNotEmpty) {
        content.add(
          RichText(
            text: TextSpan(
              children: spans,
              style: isMessageBySender
                  ? outgoingChatBubbleConfig?.textStyle
                  : inComingChatBubbleConfig?.textStyle,
            ),
          ),
        );
      }
    }

    return content;
  }

  Widget _buildImageWidget(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 180,
          height: 130,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 180,
              height: 130,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 180,
              height: 130,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }

  String _extractUrlFromMatch(String urlMatch) {
    // Remove any trailing characters that might be part of markdown syntax
    String url = urlMatch.trim();

    // Remove trailing parentheses, commas, periods, or other punctuation
    url = url.replaceAll(RegExp(r'[),.!;:]+$'), '');

    return url;
  }

  String _cleanUrl(String rawUrl) {
    // Clean up URL by removing trailing unwanted characters
    String cleanedUrl = rawUrl;

    // Remove trailing parentheses, commas, periods, or other punctuation
    cleanedUrl = cleanedUrl.replaceAll(RegExp(r'[),.!;:]+$'), '');

    // Remove any whitespace
    cleanedUrl = cleanedUrl.trim();

    return cleanedUrl;
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Failed to launch URL: $e');
    }
  }
}
