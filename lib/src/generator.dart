import 'dart:collection';

import 'package:fast_i18n/src/model.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:recase/recase.dart';

/// decides which class should be generated
class ClassTask {
  final String className;
  final Map<String, Value> members;

  ClassTask(this.className, this.members);
}

/// main generate function
/// returns a string representing the content of the .g.dart file
String generate(
    {required I18nConfig config, required List<I18nData> translations}) {
  StringBuffer buffer = StringBuffer();

  buffer.writeln();
  buffer.writeln('// Generated file. Do not edit.');
  buffer.writeln();
  buffer.writeln('import \'package:flutter/material.dart\';');
  buffer.writeln('import \'package:fast_i18n/fast_i18n.dart\';');

  _generateHeader(buffer, config, translations);

  buffer.writeln();
  buffer.writeln('// translations');

  for (I18nData localeData in translations) {
    _generateLocale(buffer, config, localeData);
  }

  return buffer.toString();
}

/// generates the header of the .g.dart file
/// contains the t function, LocaleSettings class and some global variables
void _generateHeader(
    StringBuffer buffer, I18nConfig config, List<I18nData> allLocales) {
  // identifiers
  const String mapVar = '_strings';
  const String baseLocaleVar = '_baseLocale';
  const String localeVar = '_locale';
  const String translationsClass = 'Translations';
  const String settingsClass = 'LocaleSettings';
  const String translationProviderKey = '_translationProviderKey';
  const String translationProviderClass = 'TranslationProvider';
  const String translationProviderStateClass = '_TranslationProviderState';
  const String inheritedClass = '_InheritedLocaleData';

  // constants
  final String translateVarInternal = '_${config.translateVariable}';
  final String translateVar = config.translateVariable;
  final String enumName = config.enumName;
  final String baseLocale = config.baseLocale;
  final String baseClassName = config.baseName.capitalize();

  // current locale variable
  buffer.writeln();
  buffer.writeln('const String $baseLocaleVar = \'$baseLocale\';');
  buffer.writeln();
  buffer.writeln('String $localeVar = $baseLocaleVar;');

  // map
  buffer.writeln();
  buffer.writeln('Map<String, $baseClassName> $mapVar = {');

  allLocales.forEach((localeData) {
    String finalClassName = localeData.base
        ? baseClassName
        : baseClassName + localeData.locale.capitalize().replaceAll('-', '');

    buffer.writeln('\t\'${localeData.locale}\': $finalClassName.instance,');
  });

  buffer.writeln('};');

  // t getter
  buffer.writeln();
  buffer.writeln('/// Method A: Simple');
  buffer.writeln('///');
  buffer.writeln(
      '/// Widgets using this method will not be updated when locale changes during runtime.');
  buffer.writeln(
      '/// Translation happens during initialization of the widget (call of t).');
  buffer.writeln('///');
  buffer.writeln('/// Usage:');
  buffer.writeln('/// String translated = t.someKey.anotherKey;');
  buffer
      .writeln('$baseClassName $translateVarInternal = $mapVar[$localeVar]!;');
  buffer.writeln('$baseClassName get $translateVar => $translateVarInternal;');

  // t getter (advanced)
  buffer.writeln();
  buffer.writeln('/// Method B: Advanced');
  buffer.writeln('///');
  buffer.writeln(
      '/// All widgets using this method will trigger a rebuild when locale changes.');
  buffer.writeln(
      '/// Use this if you have e.g. a settings page where the user can select the locale during runtime.');
  buffer.writeln('///');
  buffer.writeln('/// Step 1:');
  buffer.writeln('/// wrap your App with');
  buffer.writeln('/// TranslationProvider(');
  buffer.writeln('/// \tchild: MyApp()');
  buffer.writeln('/// );');
  buffer.writeln('///');
  buffer.writeln('/// Step 2:');
  buffer.writeln(
      '/// final t = $translationsClass.of(context); // get t variable');
  buffer.writeln(
      '/// String translated = t.someKey.anotherKey; // use t variable');
  buffer.writeln('class $translationsClass {');
  buffer.writeln('\t$translationsClass._(); // no constructor');
  buffer.writeln();
  buffer.writeln('\tstatic $baseClassName of(BuildContext context) {');
  buffer.writeln(
      '\t\treturn context.dependOnInheritedWidgetOfExactType<$inheritedClass>()!.translations;');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // enum
  buffer.writeln();
  buffer.writeln('/// Type-safe locales');
  buffer.writeln('///');
  buffer.writeln('/// Usage:');
  buffer.writeln(
      '/// - LocaleSettings.setLocaleTyped($enumName.${baseLocale.toEnumConstant()})');
  buffer.writeln(
      '/// - if (LocaleSettings.currentLocaleTyped == $enumName.${baseLocale.toEnumConstant()})');
  buffer.writeln('enum $enumName {');
  for (I18nData locale in allLocales) {
    buffer.writeln('\t${locale.locale.toEnumConstant()},');
  }
  buffer.writeln('}');

  // settings
  buffer.writeln();
  buffer.writeln('class $settingsClass {');
  buffer.writeln('\t$settingsClass._(); // no constructor');

  buffer.writeln();
  buffer.writeln('\t/// Uses locale of the device, fallbacks to base locale.');
  buffer.writeln('\t/// Returns the locale which has been set.');
  buffer.writeln('\t/// Be aware that the locales are case sensitive.');
  buffer.writeln('\tstatic String useDeviceLocale() {');
  buffer.writeln(
      '\t\tString deviceLocale = FastI18n.getDeviceLocale() ?? $baseLocaleVar;');
  buffer.writeln('\t\treturn setLocale(deviceLocale);');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Sets locale, fallbacks to base locale.');
  buffer.writeln('\t/// Returns the locale which has been set.');
  buffer.writeln('\t/// Be aware that the locales are case sensitive.');
  buffer.writeln('\tstatic String setLocale(String locale) {');
  buffer.writeln(
      '\t\t$localeVar = FastI18n.selectLocale(locale, $mapVar.keys.toList(), $baseLocaleVar);');
  buffer.writeln('\t\t$translateVarInternal = $mapVar[$localeVar]!;');
  buffer.writeln();
  buffer.writeln('\t\tfinal state = $translationProviderKey.currentState;');
  buffer.writeln('\t\tif (state != null) {');
  buffer.writeln('\t\t\tstate.setLocale($localeVar);');
  buffer.writeln('\t\t}');
  buffer.writeln();
  buffer.writeln('\t\treturn $localeVar;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Typed version of [setLocale]');
  buffer.writeln('\tstatic $enumName setLocaleTyped($enumName locale) {');
  buffer
      .writeln('\t\treturn setLocale(locale.toLanguageTag()).to$enumName()!;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Gets current locale.');
  buffer.writeln('\tstatic String get currentLocale {');
  buffer.writeln('\t\treturn $localeVar;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Typed version of [currentLocale]');
  buffer.writeln('\tstatic $enumName get currentLocaleTyped {');
  buffer.writeln('\t\treturn $localeVar.to$enumName()!;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Gets base locale.');
  buffer.writeln('\tstatic String get baseLocale {');
  buffer.writeln('\t\treturn $baseLocaleVar;');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Gets supported locales.');
  buffer.writeln('\tstatic List<String> get locales {');
  buffer.writeln('\t\treturn $mapVar.keys.toList();');
  buffer.writeln('\t}');

  buffer.writeln();
  buffer.writeln('\t/// Get supported locales with base locale sorted first.');
  buffer.writeln('\tstatic List<Locale> get supportedLocales {');
  buffer.writeln(
      '\t\treturn FastI18n.convertToLocales($mapVar.keys.toList(), $baseLocaleVar);');
  buffer.writeln('\t}');

  buffer.writeln('}');

  // enum extension
  buffer.writeln();
  buffer.writeln('// extensions for $enumName');
  buffer.writeln();
  buffer.writeln('extension ${enumName}Extensions on $enumName {');
  buffer.writeln('\tString toLanguageTag() {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase $enumName.${locale.locale.toEnumConstant()}: return \'${locale.locale}\';');
  }
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // string extension
  buffer.writeln('extension String${enumName}Extensions on String {');
  buffer.writeln('\t$enumName? to$enumName() {');
  buffer.writeln('\t\tswitch (this) {');
  for (I18nData locale in allLocales) {
    buffer.writeln(
        '\t\t\tcase \'${locale.locale}\': return $enumName.${locale.locale.toEnumConstant()};');
  }
  buffer.writeln('\t\t\tdefault: return null;');
  buffer.writeln('\t\t}');
  buffer.writeln('\t}');
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln('// wrappers');

  // TranslationProvider
  buffer.writeln();
  buffer.writeln(
      'GlobalKey<$translationProviderStateClass> $translationProviderKey = new GlobalKey<$translationProviderStateClass>();');
  buffer.writeln();
  buffer.writeln('class $translationProviderClass extends StatefulWidget {');
  buffer.writeln(
      '\t$translationProviderClass({required this.child}) : super(key: $translationProviderKey);');
  buffer.writeln();
  buffer.writeln('\tfinal Widget child;');
  buffer.writeln();
  buffer.writeln('\t@override');
  buffer.writeln(
      '\t$translationProviderStateClass createState() => $translationProviderStateClass();');
  buffer.writeln('}');

  buffer.writeln();
  buffer.writeln(
      'class $translationProviderStateClass extends State<$translationProviderClass> {');
  buffer.writeln('\tString locale = $localeVar;');
  buffer.writeln();
  buffer.writeln('\tvoid setLocale(String newLocale) {');
  buffer.writeln('\t\tsetState(() {');
  buffer.writeln('\t\t\tlocale = newLocale;');
  buffer.writeln('\t\t});');
  buffer.writeln('\t}');
  buffer.writeln();
  buffer.writeln('\t@override');
  buffer.writeln('\tWidget build(BuildContext context) {');
  buffer.writeln('\t\treturn $inheritedClass(');
  buffer.writeln('\t\t\ttranslations: $mapVar[locale]!,');
  buffer.writeln('\t\t\tchild: widget.child,');
  buffer.writeln('\t\t);');
  buffer.writeln('\t}');
  buffer.writeln('}');

  // InheritedLocaleData
  buffer.writeln();
  buffer.writeln('class $inheritedClass extends InheritedWidget {');
  buffer.writeln('\tfinal $baseClassName translations;');
  buffer.writeln(
      '\t$inheritedClass({required this.translations, required Widget child}) : super(child: child);');
  buffer.writeln();
  buffer.writeln('\t@override');
  buffer.writeln('\tbool updateShouldNotify($inheritedClass oldWidget) {');
  buffer.writeln('\t\treturn oldWidget.translations != translations;');
  buffer.writeln('\t}');
  buffer.writeln('}');
}

/// generates all classes of one locale
/// all non-default locales has a postfix of their locale code
/// e.g. Strings, StringsDe, StringsFr
void _generateLocale(
    StringBuffer buffer, I18nConfig config, I18nData localeData) {
  Queue<ClassTask> queue = Queue();

  queue.add(ClassTask(
    config.baseName.capitalize(),
    localeData.root.entries,
  ));

  do {
    ClassTask task = queue.removeFirst();

    _generateClass(
      config,
      localeData.base,
      localeData.locale,
      buffer,
      queue,
      task.className,
      task.members,
    );
  } while (queue.isNotEmpty);
}

/// generates a class and all of its members of ONE locale
/// adds subclasses to the queue
void _generateClass(
  I18nConfig config,
  bool base,
  String locale,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className,
  Map<String, Value> currMembers,
) {
  String finalClassName =
      base ? className : className + locale.capitalize().replaceAll('-', '');

  buffer.writeln();

  if (base) {
    buffer.writeln('class $finalClassName {');
  } else {
    buffer.writeln('class $finalClassName implements $className {');
  }

  buffer.writeln('\t$finalClassName._(); // no constructor');
  buffer.writeln();
  buffer.writeln('\tstatic $finalClassName _instance = $finalClassName._();');
  buffer.writeln('\tstatic $finalClassName get instance => _instance;');
  buffer.writeln();

  currMembers.forEach((key, value) {
    key = key.toCase(config.keyCase);

    buffer.write('\t');
    if (!base) buffer.write('@override ');

    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('String $key = \'${value.content}\';');
      } else {
        buffer.writeln(
            'String $key${_toParameterList(value.params)} => \'${value.content}\';');
      }
    } else if (value is ListNode) {
      String type = value.plainStrings ? 'String' : 'dynamic';
      buffer.write('List<$type> get $key => ');
      _generateList(base, locale, buffer, queue, className, value.entries, 0);
    } else if (value is ObjectNode) {
      String childClassName = className + key.capitalize();
      if (value.mapMode) {
        // inline map
        String type = value.plainStrings ? 'String' : 'dynamic';
        buffer.write('Map<String, $type> get $key => ');
        _generateMap(
            base, locale, buffer, queue, childClassName, value.entries, 0);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassName, value.entries));

        String finalChildClassName = base
            ? childClassName
            : childClassName + locale.capitalize().replaceAll('-', '');

        buffer.writeln(
            '$finalChildClassName get $key => $finalChildClassName._instance;');
      }
    }
  });

  buffer.writeln('}');
}

/// generates a map of ONE locale
/// similar to _generateClass but anonymous and accessible via key
void _generateMap(
  bool base,
  String locale,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className,
  Map<String, Value> currMembers,
  int depth,
) {
  buffer.writeln('{');

  currMembers.forEach((key, value) {
    _addTabs(buffer, depth + 2);
    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('\'$key\': \'${value.content}\',');
      } else {
        buffer.writeln(
            '\'$key\': ${_toParameterList(value.params)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      buffer.write('\'$key\': ');
      _generateList(
          base, locale, buffer, queue, className, value.entries, depth + 1);
    } else if (value is ObjectNode) {
      String childClassName = className + key.capitalize();
      if (value.mapMode) {
        // inline map
        buffer.write('\'$key\': ');
        _generateMap(base, locale, buffer, queue, childClassName, value.entries,
            depth + 1);
      } else {
        // generate a class later on
        queue.add(ClassTask(childClassName, value.entries));

        String finalChildClassName = base
            ? childClassName
            : childClassName + locale.capitalize().replaceAll('-', '');

        buffer.writeln('\'$key\': $finalChildClassName._instance,');
      }
    }
  });

  _addTabs(buffer, depth + 1);

  buffer.write('}');

  if (depth == 0) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

/// generates a list
void _generateList(
  bool base,
  String locale,
  StringBuffer buffer,
  Queue<ClassTask> queue,
  String className,
  List<Value> currList,
  int depth,
) {
  buffer.writeln('[');

  for (int i = 0; i < currList.length; i++) {
    Value value = currList[i];
    _addTabs(buffer, depth + 2);
    if (value is TextNode) {
      if (value.params.isEmpty) {
        buffer.writeln('\'${value.content}\',');
      } else {
        buffer.writeln(
            '${_toParameterList(value.params)} => \'${value.content}\',');
      }
    } else if (value is ListNode) {
      _generateList(
          base, locale, buffer, queue, className, value.entries, depth + 1);
    } else if (value is ObjectNode) {
      String childClassName = className + depth.toString() + 'i' + i.toString();
      queue.add(ClassTask(childClassName, value.entries));

      String finalChildClassName = childClassName + locale.capitalize();
      buffer.writeln('$finalChildClassName._instance,');
    }
  }

  _addTabs(buffer, depth + 1);

  buffer.write(']');

  if (depth == 0) {
    buffer.writeln(';');
  } else {
    buffer.writeln(',');
  }
}

/// returns the parameter list
/// e.g. ({required Object name, required Object age}) for definition = true
/// or (name, age) for definition = false
String _toParameterList(List<String> params, {bool definition = true}) {
  StringBuffer buffer = StringBuffer();
  buffer.write('(');
  if (definition) buffer.write('{');
  for (int i = 0; i < params.length; i++) {
    if (i != 0) buffer.write(', ');
    if (definition) buffer.write('required Object ');
    buffer.write(params[i]);
  }
  if (definition) buffer.write('}');
  buffer.write(')');
  return buffer.toString();
}

/// writes count times \t to the buffer
void _addTabs(StringBuffer buffer, int count) {
  for (int i = 0; i < count; i++) {
    buffer.write('\t');
  }
}

extension on String {
  /// capitalizes a given string
  /// 'hello' => 'Hello'
  /// 'heLLo' => 'HeLLo'
  /// 'Hello' => 'Hello'
  /// '' => ''
  String capitalize() {
    if (this.isEmpty) return '';
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }

  String toCase(String? caseName) {
    switch (caseName) {
      case 'snake':
        return snakeCase;
      case 'camel':
        return camelCase;
      default:
        return this;
    }
  }

  String toEnumConstant() {
    return this.toLowerCase().camelCase;
  }
}
