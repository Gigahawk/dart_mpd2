class MPDClientBase {
  bool useUnicode;
  bool iterate = false;
  String mpdVersion;
  List<String> commandList;

  MPDClientBase(this.useUnicode) {
    reset();
  }

  void noidle() {
    throw UnimplementedError(
      'Abstract ``MPDClientBase`` does not implement ``noidle``');
  }

  void reset() {
    mpdVersion = null;
    commandList = null;
  }
}