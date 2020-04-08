class MPDException implements Exception {
  String cause;
  MPDException(this.cause);
}

class ConnectionException extends MPDException {
  ConnectionException(cause) : super(cause);
}

class ProtocolException extends MPDException {
  ProtocolException(cause) : super(cause);
}

class CommandException extends MPDException {
  CommandException(cause) : super(cause);
}

class CommandListException extends MPDException {
  CommandListException(cause) : super(cause);
}

class PendingCommandException extends MPDException {
  PendingCommandException(cause) : super(cause);
}

class IteratingException extends MPDException {
  IteratingException(cause) : super(cause);
}