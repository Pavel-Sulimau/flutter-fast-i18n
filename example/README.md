# Example

## Step 1: Add dependencies

```yaml
dependencies:
  fast_i18n: ^3.0.0

dev_dependencies:
  build_runner: any
```

## Step 2: Create JSON files

Create these files inside your `lib` directory. Preferably in one common package like `lib/i18n`.

`strings.i18n.json (default, fallback)`

```json
{
  "hello": "Hello $name",
  "save": "Save",
  "login": {
    "success": "Logged in successfully",
    "fail": "Logged in failed"
  }
}
```

`strings_de.i18n.json`

```json
{
  "hello": "Hallo $name",
  "save": "Speichern",
  "login": {
    "success": "Login erfolgreich",
    "fail": "Login fehlgeschlagen"
  }
}
```

## Step 3: Generate the dart code

```
flutter pub run build_runner build
```

## Step 4: Initialize

a) use device locale
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LocaleSettings.useDeviceLocale();
  runApp(MyApp());
}
```

b) use specific locale
```dart
@override
void initState() {
  super.initState();
  String storedLocale = loadFromStorage(); // your logic here
  LocaleSettings.setLocale(storedLocale);
}
```

## Step 4a: Override 'supportedLocales'

This is optional but recommended.

Standard flutter controls (e.g. back button's tooltip) will also pick the right locale.

```dart
MaterialApp(
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: LocaleSettings.supportedLocales, // <---
)
```

## Step 4b: iOS configuration

```
File: ios/Runner/Info.plist

<key>CFBundleLocalizations</key>
<array>
   <string>en</string>
   <string>de</string>
</array>
```

## Step 5: Use your translations

```dart
// raw string
String translated = t.hello(name: 'Tom');

// inside component
Text(t.login.success)

// advanced
TranslationProvider(child: MyApp()); // wrap your app with the TranslationProvider
final t = Translations.of(context); // reacts on locale changes
String translateAdvanced = t.hello(name: 'Tom');
```

## API

When the dart code has been generated, you will see some useful classes and functions

`t` - the translate variable for simple translations

`Translations.of(context)` - translations which reacts to locale changes

`TranslationProvider` - App wrapper, used for `Translations.of(context)`

`LocaleSettings.useDeviceLocale()` - use the locale of the device

`LocaleSettings.setLocale('de')` - change the locale

`LocaleSettings.setLocaleTyped(AppLocale.en)` - change the locale (typed version)

`LocaleSettings.currentLocale` - get the current locale

`LocaleSettings.currentLocaleTyped` - get the current locale (typed version)

`LocaleSettings.locales` - get the supported locales

`LocaleSettings.supportedLocales` - see step 4a

## Configuration

All settings can be set in the `build.yaml` file. Place it in the root directory.

```yaml
targets:
  $default:
    builders:
      fast_i18n:i18nBuilder:
        options:
          base_locale: en
          input_directory: lib/i18n
          input_file_pattern: .i18n.json
          output_directory: lib/i18n
          output_file_pattern: .g.dart
          translate_var: t
          enum_name: AppLocale
          key_case: snake
          maps:
            - a
            - b
            - c.d
```

Key|Type|Usage|Default
---|---|---|---
base_locale|`String`|locale of default json|`en`
input_directory|`String`|path to input directory|`null (whole project)`
input_file_pattern|`String`|input file pattern|`.i18n.json`
output_directory|`String`|path to output directory|`null (whole project)`
output_file_pattern|`String`|output file pattern|`.g.dart`
translate_var|`String`|translate variable name|`t`
enum_name|`String`|enum name|`AppLocale`
key_case|`snake` or `camel`|transform keys to snake or camel case|`null (no transform)`
maps|`List<String>`|entries which should be accessed via keys|`[]`

## Additional features

**Maps**

Sometimes you need to access the translations via keys.
Define the maps in your `config.i18n.json`.
Keep in mind that all nice features like autocompletion are gone.

`strings.i18n.json`
```json
{
  "welcome": "Welcome",
  "thisIsAMap": {
    "hello world": "hello"
  },
  "classicClass": {
    "hello": "hello",
    "aMapInClass": {
      "hi": "hi"
    }
  }
}
```

`config.i18n.json`
```yaml
targets:
  $default:
    builders:
      fast_i18n:i18nBuilder:
        options:
          maps:
            - thisIsAMap
            - classicClass.aMapInClass
```

Now you can access this via key:

```dart
String a = t.thisIsAMap['hello world'];
String b = t.classicClass.hello; // the "classical" way
String c = t.classicClass.aMapInClass['hi']; // nested
```

**Lists**

Lists are fully supported.

```json
{
  "niceList": [
    "hello",
    "nice",
    [
      "nestedList"
    ],
    {
      "wow": "wow"
    },
    {
      "a map entry": "cool"
    }
  ]
}
```

```dart
String a = t.niceList[1];
String b = t.niceList[2][0];
String c = t.niceList[3].wow;
String d = t.niceList[4]['a map entry'];
```