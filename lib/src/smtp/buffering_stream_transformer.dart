import 'dart:async';
import 'dart:typed_data';

class BufferingStreamTransformer extends StreamTransformerBase<List<int>, List<int>> {
  final int bufferSize;

  BufferingStreamTransformer(this.bufferSize);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) {
    var controller = StreamController<List<int>>();
    var buffer = BytesBuilder();

    stream.listen(
      (data) {
        if (data.length >= bufferSize) {
          if (buffer.isNotEmpty) {
            controller.add(buffer.takeBytes());
          }
          controller.add(data);
        } else {
          buffer.add(data);
          if (buffer.length >= bufferSize) {
            controller.add(buffer.takeBytes());
          }
        }
      },
      onError: controller.addError,
      onDone: () {
        if (buffer.isNotEmpty) {
          controller.add(buffer.takeBytes());
        }
        controller.close();
      },
      cancelOnError: true,
    );

    return controller.stream;
  }
}
