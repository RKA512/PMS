/// Why the file exists:
/// Provides professional, strongly typed failure representations for Domain & Use Case error handling.
/// Implements [Error Handling Policy EH-202, EH-100] replacing generic exception trapping with robust Failure types.
library;

abstract class Failure {
  final String code;
  final String message;

  const Failure({
    required this.code,
    required this.message,
  });

  @override
  String toString() => '[$code]: $message';
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required String code,
    required String message,
  }) : super(code: code, message: message);
}

class AuthorizationFailure extends Failure {
  const AuthorizationFailure({
    required String code,
    required String message,
  }) : super(code: code, message: message);
}

class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    required String code,
    required String message,
  }) : super(code: code, message: message);
}

class FinancialFailure extends Failure {
  const FinancialFailure({
    required String code,
    required String message,
  }) : super(code: code, message: message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String code,
    required String message,
  }) : super(code: code, message: message);
}

class SystemFailure extends Failure {
  const SystemFailure({
    required String code,
    required String message,
  }) : super(code: code, message: message);
}
