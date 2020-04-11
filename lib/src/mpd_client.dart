import 'dart:async';
import 'dart:io';
import 'package:pedantic/pedantic.dart';

import 'string_socket.dart';
import 'utils.dart';
import 'error.dart';
import 'mpd_client_base.dart';
import 'constants.dart';


class MPDClient extends MPDClientBase {
  List<String> _pending;
  bool _iterating;
  int timeout;
  Socket _sock;
  Stream<String> _stringStream;

  MPDClient(bool useUnicode) : super(useUnicode);

  Future<void> clearerror();

  @override
  void reset() {
    super.reset();
    _pending = [];
    _iterating = false;
    _sock = null;
    _stringStream = null;
  }

  Future<void> connect(String host, {String port, int timeout}) async {
    if(_sock != null) {
      throw ConnectionException('Already connected');
    }

    if(timeout != null) {
      // TODO: add deprecation warning?
      this.timeout = timeout;
    }

    if(host.startsWith('/')) {
      _sock = await _connect_unix(host);
    } else {
      if(port == null) {
        throw FormatException(
          'port must be specified when connecting via tcp');
      }
      _sock = await _connect_tcp(host, port);
    }

    _stringStream = _sock.transform(socketTransformer).asBroadcastStream();

    try {
      await _hello();
    } catch(e) {
      print(e);
      await disconnect();
      rethrow;
    }
    return;
  }

  Future<void> disconnect() async {
    print('Disconnecting');
    if(_sock != null) {
      await _sock.close();
    }
    reset();
  }

  Future<Socket> _connect_unix(String host) async {
    throw UnimplementedError(
      "dart:io Sockets don't support Unix sockets");
  }

  Future<Socket> _connect_tcp(String host, String port) async {
    var sock = await Socket.connect(host, int.parse(port));
    return sock;
  } 

  Future<void> _hello() async {
    var hello = await _stringStream.first;
    if(!hello.endsWith('\n')) {
      throw ConnectionException('Connection lost while reading MPD hello');
    }
    hello = hello.trim();
    if(!hello.startsWith(HELLO_PREFIX)) {
      throw ProtocolException("Got invalid MPD hello: '$hello'");
    }
    mpdVersion = hello.substring(HELLO_PREFIX.length).trim();
    return;
  }

  void _send(String command, List<String> args, String retVal) {
    if(commandList != null) {
      throw CommandListException(
        'Cannot use send_$command in a command list');
    }
    _write_command(command, args: args);
    if(retVal != null) {
      _pending.add(command);
    }
  }

  Future<void> _write_command(String command, {List args}) async {
    var parts = [command];
    args ??= [];
    for (var arg in args) {
      if(arg is List) {
        switch(arg.length) {
          case 0:
            parts.add('":"');
            break;
          case 1:
            parts.add('"${int.parse(arg[0])}:"');
            break;
          default:
            parts.add('"${int.parse(arg[0])}:${int.parse(arg[1])}"');
            break;
        }
      } else {
        parts.add('"${escape(arg)}"');
      }
    }
    //TODO: implement logging
    if(command == 'password') {
      print('Calling MPD password(******)');
    } else {
      print('Calling MPD $command $args');
    }

    var cmd = parts.join(' ');
    await _write_line(cmd);
  }

  Future<void> _write_line(String line) async {
    _sock.writeln(line);
    await _sock.flush();
  }

  @override
  Future<dynamic> noSuchMethod(Invocation invocation) async {
    var cmd = _getSymbolName(invocation.memberName.toString());
    unawaited(_write_command(cmd));
    // await _write_command(cmd);
    var responseStream = _stringStream.timeout(
      Duration(seconds: 5),
      onTimeout: (_) {
        throw ConnectionException('Response incomplete');
      }).takeWhile((String element) {
        element = element.trim();
        if(element == 'OK'){
          return false;
        }
        if(element.startsWith('ACK')) {
          throw ProtocolException("Error response from MPD: $element");
        }
        return true;
    });
    await for (var line in responseStream) {
      print(line);
    }
  }

  // This is apparently acceptable
  // https://github.com/dart-lang/sdk/issues/28372
  String _getSymbolName(String rawSymbolString) {
    var exp = RegExp(r'Symbol\(\"([a-zA-Z_0-9]*)\"\)');
    return exp.firstMatch(rawSymbolString).group(1);
  }
}