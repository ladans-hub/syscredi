/// Resultado explícito para operações de domínio sem lançar erros de negócio.
sealed class AppResult<T> {
  const AppResult();
  bool get isSuccess => this is Success<T>;
}

final class Success<T> extends AppResult<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends AppResult<T> {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;
}
