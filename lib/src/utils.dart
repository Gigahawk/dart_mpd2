String escape(String text) {
  return text.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
}