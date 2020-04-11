import 'package:tuple/tuple.dart';
import '../error.dart';

List<String> _splitLimit(String line, String separator, int limit) {
  var split = line.split(separator);
  if(split.length <= limit + 1) {
    return split;
  }
  var out = split.sublist(0, limit);
  var rest = split.sublist(limit).join(separator);
  out.add(rest);
  return out;
}
abstract class AbstractParser {
  Tuple2<String, String> parsePair(String line, String separator) {
    if(line == null) {
      return null;
    }
    
    var pair = _splitLimit(line, separator, 1);
    if(pair.length != 2) {
      throw ProtocolException("Could not parse pair: '$line'");
    }
    return Tuple2<String, String>(pair[0], pair[1]);
  }

  Iterable<Tuple2<String, String>> parsePairs(List<String> lines, {String separator=': '}) sync* {
    for (var line in lines) {
      yield parsePair(line, separator);
    }
  }

  Iterable<Map<String, dynamic>> parseObjects(List<String> lines, {List<String> delimiters, bool lookup_delimiter=false}) sync* {
    var obj = {};
    for (var pair in parsePairs(lines)) {
      var key = pair.item1.toLowerCase();
      var value = pair.item2;

      if(lookup_delimiter && delimiters == null) {
        delimiters = [key];
      }
      if(obj.isNotEmpty) {
        if(delimiters.contains(key)) {
          yield obj;
          obj = {};
        } else if(obj.containsKey(key)) {
          if(!obj[key] is List) {
            obj[key] = [obj[key], value];
          } else {
            obj[key].add(value);
          }
          continue;
        }
      }
      obj[key] = value;
    }
    if(obj.isNotEmpty) {
      yield obj;
    }
  }

  Iterable<Tuple2<String, String>> parseRawStickers(lines) sync* {
    for (var pair in parsePairs(lines)) {
      var sticker = pair.item2;
      var value = _splitLimit(sticker, '=', 1);
      if(value.length != 2) {
        throw ProtocolException('Could not parse sticker: $sticker');
      }
      yield Tuple2<String, String>(value[0], value[1]);
    }
  }
}

abstract class AbstractChangeParser extends AbstractParser {
  Iterable<Map<String, dynamic>> parseChanges(lines) {
    return parseObjects(lines, delimiters: ['cpos']);
  }
}

abstract class AbstractDatabaseParser extends AbstractParser {
  Iterable<Map<String, dynamic>> parseDatabase(lines) {
    return parseObjects(
      lines, delimiters: ['file', 'directory', 'playlist']);
  }
}