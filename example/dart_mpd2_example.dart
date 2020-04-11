import 'package:dart_mpd2/mpd.dart';

void main() async {
  var client = MPDClient(true);
  await client.connect('localhost', port: '6600');
  await client.clearerror();
  print(client.mpdVersion);
  await client.disconnect();
}
