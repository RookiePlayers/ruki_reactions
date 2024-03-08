## 0.0.1-dev

* A Emoji Reaction for your project. This package handles all your emoji reaction needs, including allowing customisable emojis, and a history of previously used emojis. 

- Emoji List for quick reactions
- Select paginated list of over 3500+ emojis
- Customised emoji picker experience, including skin-tone segmentation
- Create custom list of quick reaction that's presisted on device thanks to sqlite.
- Store history of most used Reactions
- Browse through emojis in a paginated List view or a categorized exploration of (smileys, People, Nature and more).

## 0.0.1
* Changed ReactionProvider to singleton for proper disposal of the sql db instance. Prevent memory leaks.
* Added Additional ReactionsController to allow manual wiping of data stored via sqllite
* Added support for custom default reactions
* 20 more default emojis
* Custom Loader option
* sqllite only opens up once, speedfing up time for initial reactions list

## 0.0.2
* Fixed: scrollable reactions list
* More button can more be brought to the start of the Reactions list using `leadingMoreButton`
* Fixed: limit is now capped to the size of the default emoji list (19), custom emojis can be added to increase this limit