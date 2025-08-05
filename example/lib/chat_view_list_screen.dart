import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';

import 'chat_view_screen.dart';
import 'data.dart';

class ChatViewListScreen extends StatefulWidget {
  const ChatViewListScreen({super.key});

  @override
  State<ChatViewListScreen> createState() => _ChatViewListScreenState();
}

class _ChatViewListScreenState extends State<ChatViewListScreen> {
  final _searchController = TextEditingController();

  ChatViewListController? _chatListController;

  ScrollController? _scrollController;

  // Assign the controller in didChangeDependencies
  // to ensure PrimaryScrollController is available.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController = PrimaryScrollController.of(context);
    _chatListController ??= ChatViewListController(
      initialChatList: Data.chatList(),
      scrollController: _scrollController!,
      disposeOtherResources: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _chatListController == null
          ? const Center(child: CircularProgressIndicator())
          : ChatViewList(
              controller: _chatListController!,
              appbar: ChatViewListAppBar(
                titleText: 'ChatView',
                centerTitle: false,
                scrolledUnderElevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Handle search action
                    },
                  ),
                ],
              ),
              header: SizedBox(
                height: 60,
                child: ListView(
                  padding: const EdgeInsetsGeometry.all(12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip.elevated(
                      backgroundColor: Colors.grey.shade200,
                      label: Text(
                          'All Chats (${_chatListController?.chatListMap.length ?? 0})'),
                      onSelected: (bool value) =>
                          _chatListController?.clearSearch(),
                    ),
                    const SizedBox(width: 12),
                    FilterChip.elevated(
                      backgroundColor: Colors.grey.shade200,
                      label: const Text('Pinned Chats'),
                      onSelected: (bool value) {
                        _chatListController?.setSearchChats(
                          _chatListController?.chatListMap.values
                                  .where((e) => e.settings.pinStatus.isPinned)
                                  .toList() ??
                              [],
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    FilterChip.elevated(
                      backgroundColor: Colors.grey.shade200,
                      label: const Text('Unread Chats'),
                      onSelected: (bool value) {
                        _chatListController?.setSearchChats(
                          _chatListController?.chatListMap.values
                                  .where((e) => (e.unreadCount ?? 0) > 0)
                                  .toList() ??
                              [],
                        );
                      },
                    ),
                  ],
                  // separatorBuilder: (_, __) => const SizedBox(width: 12),
                ),
              ),
              loadMoreChats: () async =>
                  await Future.delayed(const Duration(seconds: 2)),
              menuConfig: ChatMenuConfig(
                enabled: true,
                deleteCallback: (chat) {
                  Future.delayed(
                    // Call this after the animation of menu is completed
                    // To show the pin status change animation
                    const Duration(milliseconds: 800),
                    () {
                      _chatListController?.removeChat(chat.id);
                    },
                  );
                  Navigator.of(context).pop();
                },
                muteStatusCallback: (result) {
                  Future.delayed(
                    // Call this after the animation of menu is completed
                    // To show the pin status change animation
                    const Duration(milliseconds: 800),
                    () {
                      _chatListController?.updateChat(
                        result.chat.id,
                        (previousChat) => previousChat.copyWith(
                          settings: previousChat.settings.copyWith(
                            muteStatus: result.status,
                          ),
                        ),
                      );
                    },
                  );
                  Navigator.of(context).pop();
                },
                pinStatusCallback: (result) {
                  Future.delayed(
                    // Call this after the animation of menu is completed
                    // To show the pin status change animation
                    const Duration(milliseconds: 800),
                    () {
                      _chatListController?.updateChat(
                        result.chat.id,
                        (previousChat) => previousChat.copyWith(
                          settings: previousChat.settings.copyWith(
                            pinStatus: result.status,
                          ),
                        ),
                      );
                    },
                  );
                  Navigator.of(context).pop();
                },
              ),
              enablePagination: true,
              loadMoreConfig: const LoadMoreConfig(),
              tileConfig: ListTileConfig(
                pinIconConfig: const PinIconConfig(),
                muteIconConfig: const MuteIconConfig(),
                typingStatusConfig: const TypingStatusConfig(
                  showUserNames: true,
                ),
                unreadCountConfig: const UnreadCountConfig(
                  style: UnreadCountStyle.ninetyNinePlus,
                ),
                userAvatarConfig: UserAvatarConfig(
                  backgroundColor: Colors.red.shade100,
                ),
                onTap: (chat) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatViewScreen(
                        chat: chat,
                      ),
                    ),
                  );
                },
              ),
              searchConfig: ChatViewListSearchConfig(
                textEditingController: _searchController,
                debounceDuration: const Duration(milliseconds: 300),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                onSearch: (value) async {
                  if (value.isEmpty) {
                    return null;
                  }
                  final list = _chatListController?.chatListMap.values
                      .where((chat) =>
                          chat.name.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                  return list;
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    _chatListController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
