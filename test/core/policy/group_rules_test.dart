import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/policy/group_rules.dart';
import 'package:groupay/core/policy/verdict.dart';

void main() {
  group('isGroupMutable', () {
    test('not archived: Allow', () {
      expect(isGroupMutable((isArchived: false)), const Allow());
    });

    test('archived: Deny(groupArchived)', () {
      expect(
        isGroupMutable((isArchived: true)),
        const Deny(MessageKey.groupArchived),
      );
    });
  });

  group('mayArchive', () {
    test('not archived: Allow', () {
      expect(mayArchive((isArchived: false)), const Allow());
    });

    test('already archived: Deny(groupArchived)', () {
      expect(
        mayArchive((isArchived: true)),
        const Deny(MessageKey.groupArchived),
      );
    });
  });

  group('mayRestore', () {
    test('archived: Allow', () {
      expect(mayRestore((isArchived: true)), const Allow());
    });

    test('not archived: Deny(groupNotArchived)', () {
      expect(
        mayRestore((isArchived: false)),
        const Deny(MessageKey.groupNotArchived),
      );
    });
  });

  group('maySetActive', () {
    test('not archived: Allow', () {
      expect(maySetActive((isArchived: false)), const Allow());
    });

    test('archived: Deny(groupArchived)', () {
      expect(
        maySetActive((isArchived: true)),
        const Deny(MessageKey.groupArchived),
      );
    });
  });
}
