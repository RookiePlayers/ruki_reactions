A Emoji Reaction for your project. This package handles all your emoji reaction needs, including allowing customisable emojis, and a history of previously used emojis. 
## Features

- Emoji List for quick reactions
- Select paginated list of over 3500+ emojis
- Customised emoji picker experience, including skin-tone segmentation
- Create custom list of quick reaction that's presisted on device thanks to sqlite.
- Store history of most used Reactions
- Browse through emojis in a paginated List view or a categorized exploration of (smileys, People, Nature and more).


## Getting started

- `dart pub get ruki-reactions`
- That's it!


## Usage

```dart

class _MyHomePageState extends State<MyHomePage> {
  String emoji = '👍';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( backgroundColor: Theme.of(context).colorScheme.inversePrimary,
         title: Text(widget.title),
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20),),
            Center(
              child: SizedBox(
                width: 300,
                child: Reactions(
                  onReactionSelected: (e){
                    setState(() {
                      emoji = e;
                    });
                  },
                )
              )
            ),
          ],
        ),
      ),
     );
  }
}
```

## API Reference

### RukiReactions
| Property | Description | Type | Default |
| --- | --- | --- | --- |
| `onReactionSelected` | Callback function to be called when a reaction is selected | `Function(String)?` | `null` |
| `moreViewMode` | The mode to use for the more view. Can be `ReactionsMoreViewMode.popup` or `ReactionsMoreViewMode.bottomSheet` | `ReactionsMoreViewMode` | `ReactionsMoreViewMode.popup` |
| `allowMoreView` | Whether to allow the more view | `bool` | `true` |
| `moreIcon` | The icon to use for the more view | `Icon?` | `null` |
| `emojiStyle` | The style to use for the emojis | `EmojiStyle` | `EmojiStyle()` |
| `moreEmojiStyle` | The style to use for the emojis in the more view | `EmojiStyle?` | `EmojiStyle()` |
| `useHistory` | Whether to use the history | `bool` | `true` |
| `size` | The size of the widget | `Size?` | `null` |
| `displayEmojiGroups` | Whether to display emoji groups | `bool` | `false` |
| `limit` | The limit of the reactions to display | `int` | `6` |
| `enableCustom` | Whether to enable custom reactions | `bool` | `false` |
| `diableSkinToneGroupingForMoreView` | Whether to disable skin tone grouping for the more view | `bool` | `false` |
| `disableSkinTone` | Whether to disable skin tone | `bool` | `true` |
| `recentEmojiPerPage` | The number of recent emojis per page | `int?` | `null` |
| `backgroundColor` | The background color of the widget | `Color?` | `null` |
| `emojiHorizontalFit` | The horizontal fit of the emojis | `double?` | `null` |
| `emojiVerticalFit` | The vertical fit of the emojis | `double?` | `null` |
| `showVariationsOnHold` | Whether to show variations on hold | `bool` | `true` |
| `emojiToReplace` | The emoji to replace | `String?` | `null` |
| `reactionWidgetController` | The controller for the reaction widget | `ReactionWidgetController` | `ReactionWidgetController()` |
| `customDefaultReactions` | Add default emojis to be displayed | `List<String>?` | `null` |
| `controller` | A controller for the Reactions backend to manually clear or add data | `ReactionsController?` | `null` | 
