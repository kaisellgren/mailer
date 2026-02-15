import 'dart:async';
import 'package:mailer/src/mime/stream_splitter.dart';
import 'package:test/test.dart';

void main() {
  group('StreamSplitter', () {
    test('Splits simple long chunk', () async {
      var transformer = StreamSplitter(5);
      var data = [1, 2, 3, 4, 5, 6, 7];
      var stream = Stream.fromIterable([data]);
      var result = await transformer.bind(stream).toList();

      // Produces smaller chunks than necessary due to recursive splitting with
      // target = max ~/ 2
      expect(
          result,
          equals([
            [1, 2],
            [3, 4],
            [5],
            [13, 10],
            [6],
            [7]
          ]));
    });

    test('Splits across multiple chunks', () async {
      var transformer = StreamSplitter(5);
      // 1,2,3
      // 4,5,6
      var stream = Stream.fromIterable([
        [1, 2, 3],
        [4, 5, 6]
      ]);
      var result = await transformer.bind(stream).toList();

      // [1,2,3] -> current=3
      // [4,5,6] -> len 3 + current 3 = 6 > 5.
      // target = 5 ~/ 2 = 2. 2+3=5 <= 5. target=2.
      // split([4,5,6], 2) -> [4,5], [6]
      // process([4,5]) -> len 2 + current 3 = 5. Add [4,5]. EOL next. current=0.
      // process([6]) -> len 1 + current 0 = 1. EOL added. Add [6]. current=1.

      expect(
          result,
          equals([
            [1, 2, 3],
            [4, 5],
            [13, 10],
            [6]
          ]));
    });

    test('Exact multiple of maxLength', () async {
      var transformer = StreamSplitter(5);
      var stream = Stream.fromIterable([
        [1, 2, 3, 4, 5],
        [6, 7, 8, 9, 10]
      ]);
      var result = await transformer.bind(stream).toList();

      expect(
          result,
          equals([
            [1, 2, 3, 4, 5],
            [13, 10],
            [6, 7, 8, 9, 10]
          ]));
    });

    test('Exact multiple in one chunk', () async {
      var transformer = StreamSplitter(5);
      var stream = Stream.fromIterable([
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      ]);
      var result = await transformer.bind(stream).toList();

      expect(
          result,
          equals([
            [1, 2],
            [3, 4],
            [5],
            [13, 10],
            [6],
            [7, 8],
            [9, 10]
          ]));
    });
  });
}
