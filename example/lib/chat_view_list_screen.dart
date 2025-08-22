import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';

import 'colors.dart';
import 'data.dart';
import 'main.dart';
import 'widgets/category_chip.dart';

enum FilterType {
  all('All'),
  unread('Unread 99+'),
  group('Groups');

  const FilterType(this.label);

  final String label;

  bool get isAll => this == all;

  bool get isUnread => this == unread;

  bool get isGroup => this == group;

  List<ChatViewListItem> filterChats(List<ChatViewListItem> chats) {
    return switch (this) {
      FilterType.unread =>
        chats.where((e) => (e.unreadCount ?? 0) > 0).toList(),
      FilterType.group => chats.where((e) => e.chatRoomType.isGroup).toList(),
      FilterType.all => chats,
    };
  }
}

class ChatViewListScreen extends StatefulWidget {
  const ChatViewListScreen({super.key});

  @override
  State<ChatViewListScreen> createState() => _ChatViewListScreenState();
}

class _ChatViewListScreenState extends State<ChatViewListScreen> {
  final _searchController = TextEditingController();

  ChatViewListController? _chatListController;

  ScrollController? _scrollController;

  FilterType filter = FilterType.all;

  // Assign the controller in didChangeDependencies
  // to ensure PrimaryScrollController is available.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController = PrimaryScrollController.of(context);
    _chatListController ??= ChatViewListController(
      initialChatList: Data.chatList,
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
              appbar: const ChatViewListAppBar(
                centerTitle: true,
                scrolledUnderElevation: 0,
                titleText: 'ChatView List',
              ),
              header: SizedBox(
                height: 60,
                child: ListView(
                  padding: const EdgeInsetsGeometry.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryChip(
                      value: filter,
                      groupValue: FilterType.all,
                      onSelected: () => _filterChats(FilterType.all),
                    ),
                    const SizedBox(width: 12),
                    CategoryChip(
                      value: filter,
                      counts: _chatListController?.chatListMap.values
                              .where((e) => e.chatRoomType.isGroup)
                              .length ??
                          0,
                      groupValue: FilterType.group,
                      onSelected: () => _filterChats(FilterType.group),
                    ),
                    const SizedBox(width: 12),
                    CategoryChip(
                      value: filter,
                      groupValue: FilterType.unread,
                      onSelected: () => _filterChats(FilterType.unread),
                    ),
                  ],
                ),
              ),
              menuConfig: ChatMenuConfig(
                deleteCallback: (chat) =>
                    _chatListController?.removeChat(chat.id),
                muteStatusCallback: (result) => _chatListController?.updateChat(
                  result.chat.id,
                  (previousChat) => previousChat.copyWith(
                    settings: previousChat.settings.copyWith(
                      muteStatus: result.status,
                    ),
                  ),
                ),
                pinStatusCallback: (result) => _chatListController?.updateChat(
                  result.chat.id,
                  (previousChat) => previousChat.copyWith(
                    settings: previousChat.settings.copyWith(
                      pinStatus: result.status,
                    ),
                  ),
                ),
              ),
              tileConfig: ListTileConfig(
                userActiveStatusConfig: UserActiveStatusConfig(
                  color: (status) => switch (status) {
                    UserActiveStatus.online => Colors.greenAccent,
                    UserActiveStatus.offline => AppColors.grey200,
                  },
                  alignment: UserActiveStatusAlignment.bottomRight,
                ),
                lastMessageStatusConfig: LastMessageStatusConfig(
                  showStatusFor: (message) => message.sentBy == '2',
                  color: (status) => switch (status) {
                    MessageStatus.read => Colors.red,
                    _ => Colors.black,
                  },
                ),
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
                      builder: (context) => ChatScreen(
                        chat: chat,
                      ),
                    ),
                  );
                },
              ),
              searchConfig: SearchConfig(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                prefixIcon: null,
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.search_rounded, color: Color(0xff6A6C6C)),
                ),
                textEditingController: _searchController,
                textFieldBackgroundColor: AppColors.grey200,
                debounceDuration: const Duration(milliseconds: 300),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                onSearch: (value) async {
                  if (value.isEmpty) {
                    return null;
                  }

                  List<ChatViewListItem> chats =
                      _chatListController?.chatListMap.values.toList() ?? [];

                  if (!filter.isAll) {
                    chats = filter.filterChats(chats);
                  }

                  final list = chats
                      .where((chat) =>
                          chat.name.toLowerCase().contains(value.toLowerCase()))
                      .toList();
                  return list;
                },
              ),
            ),
    );
  }

  void _filterChats(FilterType type) {
    _searchController.clear();
    filter = type;
    if (type.isAll) {
      _chatListController?.clearSearch();
    } else {
      final chats = type.filterChats(
        _chatListController?.chatListMap.values.toList() ?? [],
      );
      _chatListController?.setSearchChats(chats);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _chatListController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
