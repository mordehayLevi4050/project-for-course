import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/ids/new_id.dart';

import '../../support/uuid_v7.dart';

void main() {
  test('newId returns a UUID v7 string', () {
    expect(newId(), matches(uuidV7));
  });

  test('ids are unique', () {
    final ids = {for (var i = 0; i < 1000; i++) newId()};
    expect(ids, hasLength(1000));
  });

  test('the 48-bit time prefix never goes backwards', () {
    final first = newId().substring(0, 13);
    final later = newId().substring(0, 13);
    expect(later.compareTo(first), greaterThanOrEqualTo(0));
  });
}
