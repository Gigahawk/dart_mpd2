import 'package:dart_mpd2/mpd.dart';

void main() {
  var client = MPDClient(true);
  client.connect('localhost', port: '6600');
}
