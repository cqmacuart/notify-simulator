import 'dart:convert';

class TemplateModel {
  final String id;
  final String name;
  final String title;
  final String body;
  final String? largeIconPath;   // color icon shown on the right
  final String? bigPicturePath;  // expanded image (BigPictureStyle)
  final String? appNameLabel;    // displayed in subText / summaryText

  const TemplateModel({
    required this.id,
    required this.name,
    required this.title,
    required this.body,
    this.largeIconPath,
    this.bigPicturePath,
    this.appNameLabel,
  });

  TemplateModel copyWith({
    String? name,
    String? title,
    String? body,
    String? largeIconPath,
    String? bigPicturePath,
    String? appNameLabel,
  }) => TemplateModel(
    id: id,
    name: name ?? this.name,
    title: title ?? this.title,
    body: body ?? this.body,
    largeIconPath: largeIconPath ?? this.largeIconPath,
    bigPicturePath: bigPicturePath ?? this.bigPicturePath,
    appNameLabel: appNameLabel ?? this.appNameLabel,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'title': title,
    'body': body,
    'largeIconPath': largeIconPath,
    'bigPicturePath': bigPicturePath,
    'appNameLabel': appNameLabel,
  };

  factory TemplateModel.fromJson(Map<String, dynamic> j) => TemplateModel(
    id: j['id'],
    name: j['name'],
    title: j['title'],
    body: j['body'],
    largeIconPath: j['largeIconPath'],
    bigPicturePath: j['bigPicturePath'],
    appNameLabel: j['appNameLabel'],
  );

  static List<TemplateModel> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => TemplateModel.fromJson(e)).toList();
  }

  static String listToJson(List<TemplateModel> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
