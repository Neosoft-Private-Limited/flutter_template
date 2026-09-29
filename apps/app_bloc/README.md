# app_bloc

The example app built with [flutter_bloc](https://bloclibrary.dev) instead of
Riverpod. Same screens, routes, flavors and shared packages as `apps/app`;
only the state management and dependency injection differ.

```sh
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

Pick one app for your project and delete the other (see the root README,
"Choosing Riverpod or Bloc").
