import 'package:mailer/src/util.dart';
import 'package:test/test.dart';

main() {
  test('chunkEncodedBytes', () {
    expect(chunkEncodedBytes(null), null);
    var s = '\r\n';
    expect(chunkEncodedBytes(''), '$s');
    expect(chunkEncodedBytes('0'), '0$s');
    expect(chunkEncodedBytes('07'), '07$s');
    var c = 'ABCDEF';
    while (c.length < 76) c += '0123456789';
    expect(c, hasLength(76));
    var c1 = c.substring(0, c.length - 1);
    expect(chunkEncodedBytes('${c1}'), '${c1}${s}');
    expect(chunkEncodedBytes('${c}'), '${c}${s}');
    expect(chunkEncodedBytes('${c}0'), '${c}${s}0${s}');
    expect(chunkEncodedBytes('${c}01'), '${c}${s}01${s}');
    expect(chunkEncodedBytes('${c}${c}'), '${c}${s}${c}${s}');
    expect(chunkEncodedBytes('${c}${c}0'), '${c}${s}${c}${s}0${s}');
    expect(chunkEncodedBytes('${c}${c}01'), '${c}${s}${c}${s}01${s}');
  });
}
