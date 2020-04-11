import 'dart:io';
import 'dart:typed_data';
import 'dart:async';


var socketTransformer = StreamTransformer<Uint8List, String>.fromHandlers(
  handleData: (data, sink) {
    sink.add(String.fromCharCodes(data));
  }
);