import 'package:isar/isar.dart';

part 'user_list.g.dart';

@collection
class UserList {
  Id? isarId;

  @Index(unique: true)
  final String name;

  UserList({required this.name});
}
