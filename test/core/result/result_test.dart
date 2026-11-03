import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/result/result.dart';

String describe(Result<int> r) => switch (r) {
  Ok(:final value) => 'ok $value',
  Failure(:final message) => 'failed ${message.name}',
};

void main() {
  test('Ok and Failure are exhaustive and carry their payload', () {
    expect(describe(const Ok(3)), 'ok 3');
    expect(
      describe(const Failure(MessageKey.nameRequired)),
      'failed nameRequired',
    );
  });

  test('isOk, equality and toString', () {
    expect(const Ok(1).isOk, isTrue);
    expect(const Failure<int>(MessageKey.nameRequired).isOk, isFalse);
    expect(const Ok(1), const Ok(1));
    expect(const Ok(1), isNot(const Ok(2)));
    expect(
      const Failure<int>(MessageKey.nameRequired),
      const Failure<int>(MessageKey.nameRequired),
    );
    expect(const Ok(1).toString(), 'Ok(1)');
    expect(
      const Failure<int>(MessageKey.nameRequired).toString(),
      'Failure(nameRequired)',
    );
  });
}
