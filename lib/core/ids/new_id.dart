import 'package:uuid/uuid.dart';

/// The only id generator (AD-8, AD-23): a UUID v7 string.
///
/// A form calls it once when it opens (and the add-member field again after
/// each successful add), so a repeated save of the same form reuses the id and
/// the insert writes nothing the second time.
String newId() => const Uuid().v7();
