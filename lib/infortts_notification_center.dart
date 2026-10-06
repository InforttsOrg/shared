import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'infortts_notification_service.dart';
import 'theme.dart';

/// Interactive Infortts Notification Center Modal / Drawer & Quick Bell Badge.
class InforttsNotificationCenter extends StatefulWidget {
  final String? initialCategory;
  final String appName;

  const InforttsNotificationCenter({
    Key? key,
    this.initialCategory,
    this.appName = 'Infortts',
  }) : super(key: key);

  static Future<void> show(BuildContext context, {String? initialCategory, String appName = 'Infortts'}) {
    final width = MediaQuery.of(context).size.width;
    if (width < 650) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => FractionallySizedBox(
          heightFactor: 0.88,
          child: InforttsNotificationCenter(
            initialCategory: initialCategory,
            appName: appName,
          ),
        ),
      );
    } else {
      return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
            child: InforttsNotificationCenter(
              initialCategory: initialCategory,
              appName: appName,
            ),
          ),
        ),
      );
    }
  }

  @override
  State<InforttsNotificationCenter> createState() => _InforttsNotificationCenterState();
}

class _InforttsNotificationCenterState extends State<InforttsNotificationCenter> {
  late String _selectedCategory;
  bool _unreadOnly = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'ALL', 'label': 'ALL', 'icon': Icons.notifications_none_rounded},
    {'id': 'INDIAN_STOCKS', 'label': '🇮🇳 INDIAN STOCKS', 'icon': Icons.trending_up_rounded},
    {'id': 'MACRO', 'label': '🔴 MACRO & FOREX', 'icon': Icons.public_rounded},
    {'id': 'TRADING', 'label': '⚡ TRADING', 'icon': Icons.bolt_rounded},
    {'id': 'SYSTEM', 'label': '🛡️ SYSTEM', 'icon': Icons.security_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'ALL';
    InforttsNotificationService.instance.fetchNotifications();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: InforttsNotificationService.instance,
      builder: (context, _) {
        final service = InforttsNotificationService.instance;
        final rawList = service.notifications;

        final filteredList = rawList.where((item) {
          if (_selectedCategory != 'ALL' && item.category != _selectedCategory) {
            return false;
          }
          if (_unreadOnly && item.isRead) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchTitle = item.title.toLowerCase().contains(query);
            final matchBody = item.body.toLowerCase().contains(query);
            final matchSymbol = item.symbol.toLowerCase().contains(query);
            final matchTopic = item.topic.toLowerCase().contains(query);
            return matchTitle || matchBody || matchSymbol || matchTopic;
          }
          return true;
        }).toList();

        final unreadCount = service.unreadCount;

        return Container(
          decoration: BoxDecoration(
            color: AcousticColors.darkCarbon,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AcousticColors.sonarCyan.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              _buildHeader(service, unreadCount),

              // Categories Tab Bar
              _buildCategoryTabBar(),

              // Quick Filter / Search Bar
              _buildSearchBar(unreadCount),

              // Notification List
              Expanded(
                child: service.isLoading && rawList.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AcousticColors.sonarCyan,
                        ),
                      )
                    : filteredList.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            itemCount: filteredList.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, index) {
                              final notif = filteredList[index];
                              return _buildNotificationCard(notif, service);
                            },
                          ),
              ),

              // Footer with notification permission status
              _buildFooter(service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(InforttsNotificationService service, int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AcousticColors.panelBg.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(color: AcousticColors.midGray.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AcousticColors.sonarCyan.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AcousticColors.sonarCyan, width: 0.8),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AcousticColors.sonarCyan, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "NOTIFICATION INTELLIGENCE",
                      style: GoogleFonts.outfit(
                        color: AcousticColors.titanium,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AcousticColors.sonarCyan,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$unreadCount NEW",
                          style: GoogleFonts.jetBrainsMono(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  "Indian Stocks • Macro Events • 1m A+ Scalps • Ecosystem",
                  style: GoogleFonts.outfit(color: AcousticColors.midGray, fontSize: 9.5),
                ),
              ],
            ),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                service.markAllAsRead(category: _selectedCategory == 'ALL' ? null : _selectedCategory);
              },
              icon: const Icon(Icons.done_all_rounded, size: 14, color: AcousticColors.sonarCyan),
              label: Text(
                "Mark all read",
                style: GoogleFonts.outfit(color: AcousticColors.sonarCyan, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 18, color: AcousticColors.steel),
            tooltip: "Refresh Feed",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => service.fetchNotifications(category: _selectedCategory),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: AcousticColors.steel),
            tooltip: "Close",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AcousticColors.black.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AcousticColors.midGray.withOpacity(0.15))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, idx) {
          final cat = _categories[idx];
          final catId = cat['id'] as String;
          final isSelected = _selectedCategory == catId;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = catId;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AcousticColors.sonarCyan.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AcousticColors.sonarCyan : AcousticColors.midGray.withOpacity(0.2),
                  width: isSelected ? 1.0 : 0.6,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 11,
                    color: isSelected ? AcousticColors.sonarCyan : AcousticColors.steel,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cat['label'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AcousticColors.titanium : AcousticColors.steel,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AcousticColors.panelBg.withOpacity(0.4),
        border: Border(bottom: BorderSide(color: AcousticColors.midGray.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 30,
              child: TextField(
                controller: _searchCtrl,
                style: GoogleFonts.outfit(color: AcousticColors.titanium, fontSize: 11),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search symbol, title or topic...",
                  hintStyle: GoogleFonts.outfit(color: AcousticColors.midGray, fontSize: 10.5),
                  prefixIcon: Icon(Icons.search_rounded, size: 14, color: AcousticColors.midGray),
                  prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  filled: true,
                  fillColor: AcousticColors.black.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AcousticColors.midGray.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AcousticColors.midGray.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AcousticColors.sonarCyan, width: 1.0),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              setState(() {
                _unreadOnly = !_unreadOnly;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: _unreadOnly ? AcousticColors.sonarCyan.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _unreadOnly ? AcousticColors.sonarCyan : AcousticColors.midGray.withOpacity(0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _unreadOnly ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 12,
                    color: _unreadOnly ? AcousticColors.sonarCyan : AcousticColors.steel,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Unread only",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: _unreadOnly ? FontWeight.bold : FontWeight.normal,
                      color: _unreadOnly ? AcousticColors.sonarCyan : AcousticColors.steel,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(InforttsNotificationEvent notif, InforttsNotificationService service) {
    Color tagColor = AcousticColors.midGray;
    String tagLabel = notif.category;
    IconData tagIcon = Icons.notifications_rounded;

    if (notif.isIndianStock) {
      tagColor = const Color(0xFFFF9933); // Saffron
      tagLabel = '🇮🇳 INDIAN STOCK';
      tagIcon = Icons.trending_up_rounded;
    } else if (notif.isMacro) {
      tagColor = Colors.redAccent;
      tagLabel = '🔴 MACRO ALERT';
      tagIcon = Icons.public_rounded;
    } else if (notif.isTrading) {
      tagColor = AcousticColors.sonarCyan;
      tagLabel = '⚡ 1m A+ SETUP';
      tagIcon = Icons.bolt_rounded;
    } else if (notif.category == 'SYSTEM') {
      tagColor = const Color(0xFFA855F7);
      tagLabel = '🛡️ SYSTEM';
      tagIcon = Icons.shield_rounded;
    }

    return InkWell(
      onTap: () async {
        if (!notif.isRead) {
          service.markAsRead(notif.id);
        }
        if (notif.url.isNotEmpty) {
          final uri = Uri.tryParse(notif.url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.isRead ? AcousticColors.panelBg.withOpacity(0.35) : AcousticColors.panelBg.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: notif.isRead
                ? AcousticColors.midGray.withOpacity(0.12)
                : tagColor.withOpacity(0.55),
            width: notif.isRead ? 0.6 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Badges, Status Dot and TimeAgo
            Row(
              children: [
                // Unread Indicator Dot
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: notif.isRead ? Colors.transparent : tagColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: notif.isRead ? AcousticColors.midGray.withOpacity(0.4) : Colors.white,
                      width: 1.0,
                    ),
                    boxShadow: notif.isRead
                        ? null
                        : [
                            BoxShadow(
                              color: tagColor.withOpacity(0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                ),
                const SizedBox(width: 8),

                // Category Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tagColor.withOpacity(0.4), width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tagIcon, size: 9, color: tagColor),
                      const SizedBox(width: 3),
                      Text(
                        tagLabel,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Symbol Tag if available
                if (notif.symbol.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AcousticColors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AcousticColors.sonarCyan.withOpacity(0.4), width: 0.6),
                    ),
                    child: Text(
                      notif.symbol.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: AcousticColors.sonarCyan,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Time ago
                Text(
                  notif.timeAgo,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: AcousticColors.midGray,
                  ),
                ),

                const SizedBox(width: 6),

                // Mark read icon button
                IconButton(
                  icon: Icon(
                    notif.isRead ? Icons.mark_email_read_outlined : Icons.done_rounded,
                    size: 14,
                    color: notif.isRead ? AcousticColors.midGray.withOpacity(0.5) : AcousticColors.sonarCyan,
                  ),
                  tooltip: notif.isRead ? "Marked as read" : "Mark as read",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    service.markAsRead(notif.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title
            Text(
              notif.title,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                color: notif.isRead ? AcousticColors.steel : AcousticColors.titanium,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),

            // Body
            Text(
              notif.body,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                color: notif.isRead ? AcousticColors.midGray : AcousticColors.steel,
                height: 1.35,
              ),
            ),

            if (notif.url.isNotEmpty && notif.url != 'https://admin.infortts.site') ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.open_in_new_rounded, size: 10, color: AcousticColors.sonarCyan),
                  const SizedBox(width: 4),
                  Text(
                    "Open details",
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      color: AcousticColors.sonarCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mark_email_read_rounded, size: 36, color: AcousticColors.midGray.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            "ALL CAUGHT UP",
            style: GoogleFonts.outfit(
              color: AcousticColors.steel,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "No matching alerts found for this filter.",
            style: GoogleFonts.outfit(color: AcousticColors.midGray, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(InforttsNotificationService service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AcousticColors.panelBg.withOpacity(0.8),
        border: Border(top: BorderSide(color: AcousticColors.midGray.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Icon(
            service.isGranted ? Icons.check_circle_rounded : Icons.notifications_paused_rounded,
            size: 12,
            color: service.isGranted ? Colors.greenAccent : AcousticColors.warnOrange,
          ),
          const SizedBox(width: 6),
          Text(
            service.isGranted ? "Push Subscriptions Active" : "Push Notifications Paused",
            style: GoogleFonts.outfit(
              fontSize: 9.5,
              color: service.isGranted ? AcousticColors.steel : AcousticColors.warnOrange,
            ),
          ),
          const Spacer(),
          if (!service.isGranted)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => service.requestPermission(context: context, appName: widget.appName),
              child: Text(
                "ENABLE PUSH",
                style: GoogleFonts.outfit(
                  color: AcousticColors.sonarCyan,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Standalone Bell Button with Real-time Unread Badge
class InforttsNotificationBell extends StatelessWidget {
  final String appName;
  final double size;

  const InforttsNotificationBell({
    Key? key,
    this.appName = 'Infortts',
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: InforttsNotificationService.instance,
      builder: (context, _) {
        final service = InforttsNotificationService.instance;
        final unreadCount = service.unreadCount;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_outlined,
                size: size,
                color: unreadCount > 0 ? AcousticColors.sonarCyan : AcousticColors.steel,
              ),
              tooltip: unreadCount > 0 ? "$unreadCount Unread Notifications" : "Notifications",
              onPressed: () => InforttsNotificationCenter.show(context, appName: appName),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AcousticColors.darkCarbon, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1.1, 1.1),
                      duration: const Duration(milliseconds: 1200),
                    ),
              ),
          ],
        );
      },
    );
  }
}
