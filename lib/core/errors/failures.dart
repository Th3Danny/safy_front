import 'package:equatable/equatable.dart';

abstract class failure extends Equatable {
  final String message;

  const failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends failure {
  const ServerFailure(String message) : super(message);
}