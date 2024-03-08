
import 'package:emojis/emoji.dart';
import 'package:flutter/material.dart';
import 'package:ruki_reactions/color_extensions.dart';
import 'package:ruki_reactions/components/lazy_loading_emojis.dart';
import 'package:ruki_reactions/components/more_reactions_page_view.dart';
import 'package:ruki_reactions/misc/flutter_scale_tab.dart';
import 'package:ruki_reactions/reaction.dart';
import 'package:ruki_reactions/ruki_reactions.dart';
import 'customizable_list.dart';
import 'reaction_widget.dart';

class MoreReactions extends StatefulWidget {
  final Function(String)? onReactionSelected;
  final EmojiStyle emojiStyle;
  final int? maxRecentEmojis;
  final Size? size;
  final int customReactionLimit;
  final bool enableCustomization;
  final bool displayEmojiGroups;
  final bool useHistory;
  final bool disableDefaultAction;
  final bool diableSkinToneGrouping;
  final ReactionWidgetController? reactionWidgetController;
  final Color? backgroundColor;
  final ReactionsMoreViewMode moreViewMode;
  final double emojiHorizontalFit;
  final double emojiVerticalFit;
  final bool showVariationsOnHold;
  const MoreReactions({
    super.key,
    this.onReactionSelected,
    this.customReactionLimit = 5,
    this.emojiHorizontalFit = 0.4,
    this.emojiVerticalFit = 0.4,
    this.enableCustomization = true,
    this.disableDefaultAction = false,
    this.diableSkinToneGrouping = false,
    this.showVariationsOnHold = false,
    this.moreViewMode = ReactionsMoreViewMode.bottomSheet,
    this.reactionWidgetController,
    this.backgroundColor,
    this.emojiStyle = const EmojiStyle(),
    this.size,
    this.displayEmojiGroups = false,
    this.maxRecentEmojis = 10,
    this.useHistory = true,
  });

  @override
  State<MoreReactions> createState() => _MoreReactionsState();
}

class _MoreReactionsState extends State<MoreReactions>
    with AutomaticKeepAliveClientMixin {
  PageController pageController = PageController();
  EmojiGroup? selectedGroup;
  bool selectedHistory = false;
  String? emojiToReplace;
  final CustomizableListController _customListController =
      CustomizableListController();

  @override
  void initState() {
    selectedHistory = widget.useHistory;
    selectedGroup =
        widget.useHistory ? EmojiGroup.component : EmojiGroup.objects.all.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      if (widget.enableCustomization)
        Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: widget.backgroundColor ??
                  Theme.of(context).cardColor.withShade(0.01),
            ),
            padding: widget.moreViewMode == ReactionsMoreViewMode.popup
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: CustomizableList(
              controller: _customListController,
              getCustomReactions: () =>
                  getCustomReactions(limit: widget.customReactionLimit),
              onChangeReactionSelected: (s) {
                setState(() {
                  emojiToReplace = s;
                });
              },
              disableVariation: widget.diableSkinToneGrouping,
              onReactionSelected: widget.onReactionSelected,
              emojiStyle: widget.emojiStyle,
              size: widget.size,
              limit: widget.customReactionLimit,
            )),
      SizedBox(
        height: widget.moreViewMode == ReactionsMoreViewMode.popup ? 2 : 10,
      ),
      Expanded(
          child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withShade(0.01),
                borderRadius: widget.moreViewMode == ReactionsMoreViewMode.popup
                    ? const BorderRadius.all(Radius.circular(20))
                    : const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
              ),
              padding: widget.moreViewMode == ReactionsMoreViewMode.popup
                  ? EdgeInsets.zero
                  : const EdgeInsets.all(20),
              child: widget.displayEmojiGroups
                  ? _buildSingleChildScrollview(context)
                  : _buildCustomScrollview(context)))
    ]);
  }

  _buildSingleChildScrollview(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: widget.size?.width ??
            MediaQuery.of(context).size.width *
                (widget.moreViewMode == ReactionsMoreViewMode.popup ? 1 : 0.8),
        height: widget.size?.height ?? MediaQuery.of(context).size.height * 0.5,
        child: Column(
          children: [
            Expanded(
                child: _buildReactionBuilder(context, recentlyUsedEmojis: []))
          ],
        ),
      ),
    );
  }

  _buildCustomScrollview(BuildContext context) {
    return SizedBox(
      width: widget.size?.width ??
          MediaQuery.of(context).size.width *
              (widget.moreViewMode == ReactionsMoreViewMode.popup ? 1 : 0.8),
      height: widget.size?.height ?? MediaQuery.of(context).size.height * 0.5,
      child: CustomScrollView(
        slivers: [
         
          if (widget.useHistory)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Text(
                  'Recently Used'.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          if (widget.useHistory)
            SliverToBoxAdapter(
                child:
                    _buildReactionsDB(context, getRecentReactions(context))),
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: widget.backgroundColor ??
                Theme.of(context).cardColor.withShade(0.01),
            elevation: 0,
            titleSpacing: 0,
            shadowColor: Colors.transparent,
            toolbarHeight: kToolbarHeight * 0.7,
            surfaceTintColor: Colors.transparent,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                selectedGroup!.name.toUpperCase(),
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          _buildReactionBuilder(context, recentlyUsedEmojis: [])
        ],
      ),
    );
  }

  _buildReactionsDB(BuildContext context, Future<List<String>> getReactions,
      [String? title]) {
    return FutureBuilder(
      future: getReactions,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.runtimeType != List<String>) {
            return const Text('No custom reactions');
          }
          List<String> reactions = snapshot.data as List<String>;
          if (reactions.isEmpty) return Container();
          return _buildReactions(context, reactions);
        } else if (snapshot.hasError) {
          return Container();
        } else if (snapshot.hasError) {
          return Container();
        }
        return Container(
          width: 200,
          height: widget.emojiStyle.size * 1.5,
          constraints:
              BoxConstraints(maxWidth: 200, maxHeight: widget.emojiStyle.size),
          child: ListView.builder(
            itemCount: 5,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => Container(
              height: widget.emojiStyle.size,
              width: widget.emojiStyle.size,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(5),
              ),
              margin: const EdgeInsets.only(right: 5),
              child: Container()
            ),
          ),
        );
      },
    );
  }

  _buildReactions(BuildContext context, List<String> reactions) {
    return LazyLoadingEmojis(
      size: widget.size,
      horizontalFit: widget.emojiHorizontalFit,
      verticalFit: widget.emojiVerticalFit,
      emojis: reactions,
      builder: (emoji) => _buildReaction(emoji ?? ''),
      emojiStyle: widget.emojiStyle,
      useGridView: true,
      gridViewScrollPhysics: const NeverScrollableScrollPhysics(),
    );
    // Wrap(
    //   alignment: WrapAlignment.start,
    //   children: <Widget>[
    //     for (var reaction in reactions) _buildReaction(reaction),
    //   ],
    // );
    // GridView.builder(
    //   shrinkWrap: true,
    //   itemCount: reactions.length,
    //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: 5,
    //     crossAxisSpacing: 5,
    //     mainAxisSpacing: 5,
    //   ),
    //   itemBuilder: (context, index) {
    //     return _buildReaction(reactions[index]);
    //   },
    // );
  }

  _buildReaction(String reaction) {
    return ReactionWidget(
      emojiStyle: widget.emojiStyle,
      controller: widget.reactionWidgetController,
      reaction: reaction,
      onReactionSelected: _onReactionSelected,
      disableVariations: widget.diableSkinToneGrouping,
      showVariationsOnHold: widget.showVariationsOnHold,
      disableDefaultAction: emojiToReplace != null,
    );
  }

  Future<List<String>> getRecentReactions(BuildContext context) async {
    List<Reaction> reactions =
        await ReactionProvider.instance.getRecentlyUsedReactions(limit: widget.maxRecentEmojis);
    return reactions.map((e) => e.emoji).toList();
  }

  _onReactionSelected(String reaction) async {
    if (reaction == emojiToReplace) return;
    if (emojiToReplace != null) {
      await replaceEmoji(
          emojiToReplace: emojiToReplace,
          newEmoji: reaction,
          limit: widget.customReactionLimit,
          onReplaced: (emoji) {});
      _customListController.refresh();
      return;
    }
    widget.onReactionSelected?.call(reaction);
  }

  Widget _buildAllReactionsByGroups(BuildContext context) {
    final isSmall =
        (widget.size?.width ?? MediaQuery.of(context).size.width) < 500;
    return SizedBox(
      width: widget.size?.width ?? MediaQuery.of(context).size.width,
      height: widget.size?.height ?? MediaQuery.of(context).size.height,
      child: Column(children: [
        Expanded(
            child: ListView.builder(
                itemCount:
                    EmojiGroup.objects.all.length + (widget.useHistory ? 1 : 0),
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final e = (index == 0 && widget.useHistory)
                      ? EmojiGroup.component
                      : EmojiGroup
                          .objects.all[index - (widget.useHistory ? 1 : 0)];
                  final isRecent = widget.useHistory && index == 0;
                  final shouldHighlight = isRecent
                      ? selectedHistory
                      : selectedGroup == e && !selectedHistory;

                  return Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.fastLinearToSlowEaseIn,
                      padding: EdgeInsets.all(isSmall ? 1 : 5),
                      margin: const EdgeInsets.only(right: 5),
                      constraints: !isSmall
                          ? null
                          : BoxConstraints(
                              maxWidth: isSmall ? 40 : 100,
                              maxHeight: isSmall ? 40 : 100,
                            ),
                      decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: isSmall
                                ? Colors.transparent
                                : shouldHighlight
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.7) ??
                                        Theme.of(context).primaryColor,
                          ),
                          color: shouldHighlight
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          shape: isSmall ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius:
                              isSmall ? null : BorderRadius.circular(8)),
                      child: isSmall
                          ? Center(
                              child: ScaleTap(
                                onPressed: () {
                                  setState(() {
                                    selectedGroup = e;
                                    selectedHistory = isRecent;
                                    pageController.animateToPage(index,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut);
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Center(
                                    child: Icon(
                                        isRecent ? Icons.history : e.icon,
                                        size: 21,
                                        color: shouldHighlight
                                            ? Theme.of(context).cardColor
                                            : Theme.of(context).primaryColor),
                                  ),
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: () {
                                setState(() {
                                  selectedGroup = e;
                                  pageController.jumpToPage(index);
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(isRecent ? Icons.history : e.icon,
                                      color: shouldHighlight
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7)),
                                  const SizedBox(width: 5),
                                  Text(
                                    isRecent ? "History" : e.name,
                                    style: TextStyle(
                                      color: shouldHighlight
                                          ? Colors.white
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  );
                })),
        Expanded(
            flex: 6,
            child: MoreReactionsPageView(
              pageController: pageController,
              emojiVerticalFit: widget.emojiVerticalFit,
              emojiHorizontalFit: widget.emojiHorizontalFit,
              disableDefaultAction: emojiToReplace != null,
              disableSkinToneGrouping: widget.diableSkinToneGrouping,
              showVariationsOnHold: widget.showVariationsOnHold,
              selectedGroup: selectedGroup ??
                  (widget.useHistory
                      ? EmojiGroup.component
                      : EmojiGroup.objects.all.first),
              useHistory: widget.useHistory,
              recenclyUsed: _buildReactionsDB(
                  context, getRecentReactions(context), 'Recently Used'),
              emojiGroups: EmojiGroup.objects.all,
              onReactionSelected: _onReactionSelected,
              emojiStyle: widget.emojiStyle,
              onPageChanged: (index) {
                setState(() {
                  if (index == 0 && widget.useHistory) {
                    selectedHistory = true;
                    return;
                  }
                  selectedHistory = false;
                  selectedGroup = EmojiGroup
                      .objects.all[index - (widget.useHistory ? 1 : 0)];
                });
              },
            ))
      ]),
    );
  }

  Widget _buildReactionBuilder(BuildContext context,
      {List<String> recentlyUsedEmojis = const []}) {
    if (widget.displayEmojiGroups) return _buildAllReactionsByGroups(context);
    List<String> emojis =
        EmojiExt.sortEmojis(skinToneGrouping: !widget.diableSkinToneGrouping);
    return LazyLoadingEmojis(
      size: widget.size,
      horizontalFit: widget.emojiHorizontalFit,
      verticalFit: widget.emojiVerticalFit,
      emojis: (emojis),
      headerEmojis: recentlyUsedEmojis,
      builder: (emoji) => _buildReaction(emoji ?? ''),
      emojiStyle: widget.emojiStyle,
      selectedGroup: selectedGroup,
      onGroupSelected: (e) {
        setState(() {
          selectedGroup = e;
        });
      },
    );
    // int numHor =
    //     ((size?.width ?? MediaQuery.of(context).size.width) / emojiStyle.size)
    //         .floor();
    // print(
    //     'numHor: ${numHor} - ${Emoji.byGroup(valu).length} x ${(Emoji.byGroup(valu).length / numHor).ceil()}');
    // return ListView.builder(
    //   shrinkWrap: true,
    //   itemCount: (Emoji.byGroup(valu).length / numHor).ceil(),
    //   itemBuilder: (context, index) {
    //     return Wrap(
    //       alignment: WrapAlignment.start,
    //       children: <Widget>[
    //         for (var reaction in Emoji.byGroup(valu).toList().sublist(
    //             index * numHor,
    //             min((index + 1) * numHor, Emoji.byGroup(valu).length)))
    //           _buildReaction(reaction.char),
    //       ],
    //     );
    //   },
    // );
  }

  @override
  bool get wantKeepAlive => true;

 
}
