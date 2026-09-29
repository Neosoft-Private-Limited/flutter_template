// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Plantilla Flutter';

  @override
  String get navHome => 'Inicio';

  @override
  String get navPosts => 'Publicaciones';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get homeTitle => 'Componentes';

  @override
  String get homeIntro =>
      'Un punto de partida neutro. Sustituye esta pantalla por tu primera funcionalidad.';

  @override
  String get buttonsSection => 'Botones';

  @override
  String get primaryAction => 'Principal';

  @override
  String get secondaryAction => 'Secundario';

  @override
  String get textAction => 'Texto';

  @override
  String get loadingLabel => 'Cargando';

  @override
  String get formSection => 'Validación de formularios';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'nombre@ejemplo.com';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get submitAction => 'Enviar';

  @override
  String get formValid => 'El formulario es válido';

  @override
  String get validationRequired => 'Este campo es obligatorio';

  @override
  String get validationInvalidEmail => 'Introduce un correo electrónico válido';

  @override
  String validationTooShort(int min) {
    return 'Usa al menos $min caracteres';
  }

  @override
  String get dialogSection => 'Diálogos';

  @override
  String get showDialogAction => 'Mostrar diálogo';

  @override
  String get dialogTitle => '¿Descartar cambios?';

  @override
  String get dialogMessage =>
      'Este diálogo de ejemplo no tiene efectos secundarios.';

  @override
  String get confirmAction => 'Confirmar';

  @override
  String get cancelAction => 'Cancelar';

  @override
  String get dialogConfirmed => 'Confirmado';

  @override
  String get dialogCancelled => 'Cancelado';

  @override
  String get statesSection => 'Estados';

  @override
  String get postsTitle => 'Publicaciones';

  @override
  String get postsEmptyTitle => 'Aún no hay publicaciones';

  @override
  String get postsEmptyMessage => 'Las nuevas publicaciones aparecerán aquí.';

  @override
  String get postsCachedNotice =>
      'Mostrando publicaciones guardadas. Desliza para actualizar cuando vuelvas a tener conexión.';

  @override
  String postTitle(int id) {
    return 'Publicación $id';
  }

  @override
  String get retryAction => 'Reintentar';

  @override
  String get errorTitle => 'Algo salió mal';

  @override
  String get errorNetwork =>
      'Parece que no tienes conexión. Compruébala e inténtalo de nuevo.';

  @override
  String get errorTimeout =>
      'El servidor tardó demasiado en responder. Inténtalo de nuevo.';

  @override
  String get errorServer =>
      'El servidor no pudo procesar la solicitud. Inténtalo más tarde.';

  @override
  String get errorNotFound => 'No encontramos lo que buscabas.';

  @override
  String get errorUnauthorized =>
      'Tu sesión ha caducado. Vuelve a iniciar sesión.';

  @override
  String get errorParsing => 'Recibimos una respuesta inesperada del servidor.';

  @override
  String get errorUnknown => 'Ocurrió algo inesperado. Inténtalo de nuevo.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get themeSection => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageSection => 'Idioma';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get aboutSection => 'Acerca de esta compilación';

  @override
  String get environmentLabel => 'Entorno';

  @override
  String get apiLabel => 'API';

  @override
  String get graphQLLabel => 'GraphQL';

  @override
  String get dataSection => 'Datos';

  @override
  String get clearDataAction => 'Borrar datos locales';

  @override
  String get clearDataMessage =>
      'Elimina la sesión guardada, el contenido en caché y las preferencias de este dispositivo.';

  @override
  String get clearDataDone => 'Datos locales borrados';

  @override
  String get notFoundTitle => 'Página no encontrada';

  @override
  String get notFoundMessage =>
      'Es posible que el enlace esté roto o que la página se haya eliminado.';

  @override
  String get goHomeAction => 'Ir al inicio';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';
}
