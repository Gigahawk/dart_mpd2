import 'dart:io';

import 'utils.dart';
import 'error.dart';
import 'mpd_client_base.dart';

class MPDClient extends MPDClientBase {
  List<String> _pending;
  bool _iterating;
  int timeout;
  RawSynchronousSocket _sock;

  MPDClient(bool useUnicode) : super(useUnicode);

  @override
  void reset() {
    super.reset();
    _pending = [];
    _iterating = false;
    _sock = null;
  }

  void connect(String host, {String port, int timeout}) {
    if(_sock != null) {
      throw ConnectionException("Already connected");
    }

    if(timeout != null) {
      // TODO: add deprecation warning?
      this.timeout = timeout;
    }

    if(host.startsWith('/')) {
      _sock = _connect_unix(host);
    } else {
      if(port == null) {
        throw FormatException(
          "port must be specified when connecting via tcp");
      }
      _sock = _connect_tcp(host, port);
    }

    try {
      var helloLine = String.fromCharCodes(_sock.readSync(100));
      print(helloLine);
    } catch(e) {
      print(e);
      disconnect();
      rethrow;
    }
  }

  void disconnect() {
    print('Disconnecting');
    if(_sock != null) {
      _sock.closeSync();
    }
    reset();
  }

  RawSynchronousSocket _connect_unix(String host) {
    throw UnimplementedError(
      "dart:io Sockets don't support Unix sockets");
  }

  RawSynchronousSocket _connect_tcp(String host, String port) {
    var sock = RawSynchronousSocket.connectSync(host, int.parse(port));
    return sock;
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

  void _write_command(String command, {List args}) {
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
      print('Calling MPD $command$args');
    }

    var cmd = parts.join(' ');
    _write_line(cmd);
  }

  void _write_line(line) {
    //_sock.write(line);
    //_sock.flush();
  }
}