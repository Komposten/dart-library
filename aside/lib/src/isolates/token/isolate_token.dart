import 'package:aside/src/isolates/token/isolate_token_mock.dart'
    if (dart.library.ui) 'dart:ui'
    show RootIsolateToken;

/// Get the [RootIsolateToken] for the current isolate if this is a Flutter app, otherwise always [null]
Object? get rootIsolateToken => RootIsolateToken.instance;
