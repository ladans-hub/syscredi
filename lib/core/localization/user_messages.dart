import '../../app/theme/app_theme.dart';

String userMessage(Object? raw, {int status = 0}) {
  final english = localeCode.value.startsWith('en');
  final message = _flatten(raw).trim();
  final lower = message.toLowerCase();

  if (status == 401 ||
      lower.contains('token bearer') ||
      lower.contains('unauthorized')) {
    return english
        ? 'Your session has expired. Sign in again to continue.'
        : 'A sua sessão expirou. Entre novamente para continuar.';
  }
  if (status == 403 || lower.contains('forbidden')) {
    return english
        ? 'You do not have permission to perform this action.'
        : 'Não possui permissão para realizar esta operação.';
  }
  if (status == 404 ||
      lower.contains('not found') ||
      lower.contains('não encontrado')) {
    return english
        ? 'The requested record was not found or is no longer available.'
        : 'O registo solicitado não foi encontrado ou já não está disponível.';
  }
  if (status == 409 ||
      lower.contains('conflict') ||
      lower.contains('noutra máquina')) {
    return english
        ? 'This record was changed by another operation. Refresh the data and try again.'
        : 'Este registo foi alterado por outra operação. Actualize os dados e tente novamente.';
  }
  if (status == 429 ||
      lower.contains('rate limit') ||
      lower.contains('demasiados pedidos')) {
    return english
        ? 'Too many requests were made. Wait a moment and try again.'
        : 'Foram efectuados muitos pedidos. Aguarde um momento e tente novamente.';
  }
  if (lower.contains('clientid') && lower.contains('uuid')) {
    return english
        ? 'Select a valid client before continuing.'
        : 'Seleccione um cliente válido antes de continuar.';
  }
  if (lower.contains('productid') && lower.contains('uuid')) {
    return english
        ? 'Select a valid credit product before continuing.'
        : 'Seleccione um produto de crédito válido antes de continuar.';
  }
  if (lower.contains('must be a uuid') || lower.contains('isuuid')) {
    return english
        ? 'One of the selected records is invalid. Select it again and retry.'
        : 'Um dos registos seleccionados é inválido. Seleccione-o novamente e tente outra vez.';
  }
  if (lower.contains('must be') || lower.contains('should not be empty')) {
    return english
        ? 'Review the form fields and enter valid information.'
        : 'Revise os campos do formulário e introduza informações válidas.';
  }
  if (lower.contains('duplicate') || lower.contains('unique constraint')) {
    return english
        ? 'A record with the same information already exists.'
        : 'Já existe um registo com as mesmas informações.';
  }
  if (lower.contains('foreign key') || lower.contains('violates')) {
    return english
        ? 'This operation cannot be completed because the record is being used elsewhere.'
        : 'Esta operação não pode ser concluída porque o registo está a ser utilizado noutro local.';
  }
  if (status >= 500) {
    return english
        ? 'The service is temporarily unavailable. Try again in a few moments.'
        : 'O serviço está temporariamente indisponível. Tente novamente dentro de alguns instantes.';
  }
  if (message.isEmpty) {
    return english
        ? 'The operation could not be completed. Review the information and try again.'
        : 'Não foi possível concluir a operação. Reveja as informações e tente novamente.';
  }
  return message;
}

String _flatten(Object? raw) {
  if (raw is Iterable) {
    return raw.map(_flatten).where((item) => item.isNotEmpty).join('\n');
  }
  return raw?.toString().replaceFirst('Exception: ', '') ?? '';
}
