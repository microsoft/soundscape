# Localization

The project's base internationalization is `en-US` (English, United States).

The `LocalizationContext.swift` class manages the app's supported languages and is responsible for extracting translated strings.

## String Resources

For every supported language, there is a `Localizable.strings` file which holds the translated strings.

These files are located in folders that correspond to their locale identifiers. For example, the strings file for `en-US` is located in:  
`GuideDogs/Assets/Localization/en-US.lproj/Localizable.strings`

The `.strings` files hold key-value pairs. The value is the translated string and the key is an identifier, to be used in the code and by the translators.  
Above every string should be a comment that describes the context in which the string will be used. For example:

```strings
/* The title for the settings screen */
"settings.screen_title" = "Settings";
```

### Strings With Parameters

If a string contains parameters, make sure to add a description to every parameter and include an example of the original string in the comment.

For strings with 1 parameter, use the `"%@"` tag to indicate a parameter. For example:

```strings
/* Notification text, %@ is a location name, "At Starbucks" */
"directions.at_poi" = "At %@";
```

For strings with 2 parameters and above, use numbered tags, such as `%1$@, %2$@, %3$@...`.  
These tags let the translators reorder the arguments that appear in the original string if needed. For example:

```strings
/* Notification text, %1$@ is a road name, %2$@ is the distance with units, "Intersects with <Pike Street> in <200 feet>"  */
"directions.intersects_with_in" = "Intersects with %1$@ in %2$@";
```

For consistency, parameters should always be of type `String` (`%@`). Do not use other tags such as numbers (e.g. `%d` or `%f`).

### Adding String Resources

First try to find the string you want to add the among existing strings. The `.strings` file contains `// MARK:` tags, so it's easier to find string sections with Xcode's direct access menu.

If it does not exist, add the new key, value and comment to the appropriate `.strings` file.
Make sure to find the appropriate location inside the file, as sections are separated like so:

```strings
//-------------------------------
// MARK: - Settings
//-------------------------------
```

**Important**:

* Make sure the new key is unique.  
* Make sure to not use concatenations for localized strings.

### Using String Resources

#### From Code

In order to display localized strings, use the `GDLocalizedString(_ key: String)` global function and pass in the key for the required string.

```swift
GDLocalizedString("settings.screen_title")
// Output: "Settings"
```

If a string requires parameters, add them in order after the `key` param.  
**Reminder:** Parameters should always be of type `String`.

```swift
GDLocalizedString("directions.at_poi", "Starbucks")
// Output: "At Starbucks"

GDLocalizedString("directions.intersects_with_in", "Pike Street", "200 feet")
// Output: "Intersects with Pike Street in 200 feet"
```

**Note:** The `GDLocalizedString()` first tries to search for the string in the current selected app language (`LocalizationContext.currentAppLocale`), and if the key is not found, it then tries the base language `en-US`.

**Note:** The `GDLocalizedString()` function replaces and build on top of the standard iOS function `NSLocalizedString()`.

### From Interface Builder

The `UILocalizationSupport` class adds support for localizing properties inside Xcode's Interface Builder UI (`.storyboard` and `.xib` files). It supports standard UI elements such as labels, buttons and search bars. Additional elements (such as custom UI controls) can be added as needed.

In order to use localized strings in UI elements, set the key of the required string resource in the `localization` text field in the attributes inspector.

Additional supported fields:

* **Lowercased:** Invokes the `lowercased()` function on the original string with the current app locale.
* **Uppercased:** Invokes the `uppercased()` function on the original string with the current app locale.
* **Accessibility label:** Sets the item's localized accessibility label.
* **Accessibility hint:** Sets the item's localized accessibility hint.
* **Accessibility value:** Sets the item's localized accessibility value.

**Note:** You can set the regular text value to simulate how the text will be display on the screen.

### Adding a New Language or Region

In Xcode, select `Project` → `Localizations` and press the `+` (plus) button. Select the language you want to add, in the pop-up select only the `Localizable.string` file and select `Finish`.
This will create another string resource file for the desired language, which should be used to contain the translations.

**Important:** There should only be one `.strings` file per language. Storyboards and XIBs should not have their own `.strings` file, rather use the custom attributes discussed in this document.

## Testing

You can use the built-in features in Xcode to test the translations.  
In Xcode, select `Product` → `Scheme` → `Edit Scheme`

* Set the `Application Language` to test in a desired language
* Select `Double-Length Pseudolanguage` to have the strings display in double Length. `"Settings"` → `"Settings Settings"`
* Select `Accented Pseudolanguage` to have the strings display with an accent. `"Settings"` → `"S̈ët̃t̃i̥ñģş"`
* Select `Bounded Pseudolanguage` to have the strings display with an accent. `"Settings"` → `"[# Settings #]"`
