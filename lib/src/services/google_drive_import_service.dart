import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'imported_payload.dart';

class DrivePayloadFile {
  final String id;
  final String name;
  final String? mimeType;
  final String? size;
  final DateTime? modifiedTime;

  const DrivePayloadFile({
    required this.id,
    required this.name,
    this.mimeType,
    this.size,
    this.modifiedTime,
  });

  String get contentType => _contentTypeFromDrive(name, mimeType);
}

class GoogleDriveImportService {
  GoogleDriveImportService()
      : _googleSignIn = GoogleSignIn(
          clientId: _googleWebClientId.isEmpty ? null : _googleWebClientId,
          scopes: const [drive.DriveApi.driveReadonlyScope],
        );

  static const String _googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  final GoogleSignIn _googleSignIn;
  drive.DriveApi? _api;

  Future<void> signIn() async {
    _assertGoogleDrivePlatformIsReady();

    final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in was cancelled.');
    }

    final client = await _googleSignIn.authenticatedClient();
    if (client == null) {
      throw StateError('Could not create authenticated Google API client.');
    }

    _api = drive.DriveApi(client);
  }

  Future<List<DrivePayloadFile>> listPayloadFiles({int pageSize = 30}) async {
    await signIn();

    final api = _api!;
    final response = await api.files.list(
      pageSize: pageSize,
      orderBy: 'modifiedTime desc',
      q: _drivePayloadQuery,
      $fields: 'files(id,name,mimeType,size,modifiedTime)',
    );

    return (response.files ?? const <drive.File>[])
        .where((file) => file.id != null && file.name != null)
        .map(
          (file) => DrivePayloadFile(
            id: file.id!,
            name: file.name!,
            mimeType: file.mimeType,
            size: file.size,
            modifiedTime: file.modifiedTime,
          ),
        )
        .toList(growable: false);
  }

  Future<ImportedPayload> downloadPayloadFile(DrivePayloadFile file) async {
    await signIn();

    final media = await _api!.files.get(
      file.id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    );

    if (media is! drive.Media) {
      throw StateError('Drive file could not be downloaded as raw media. Export Google Docs files first.');
    }

    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }

    return ImportedPayload(
      name: file.name,
      bytes: builder.takeBytes(),
      contentType: file.contentType,
      source: 'google_drive',
    );
  }

  Future<void> signOut() => _googleSignIn.signOut();
}


void _assertGoogleDrivePlatformIsReady() {
  if (kIsWeb) {
    if (GoogleDriveImportService._googleWebClientId.isEmpty) {
      throw StateError(
        'Google Drive import for Web is not configured. Add a Google OAuth Web Client ID, then run: '
        'flutter run -d chrome --web-hostname localhost --web-port 7357 '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com. '
        'Also add http://localhost and http://localhost:7357 to Authorized JavaScript origins.',
      );
    }
    return;
  }

  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux) {
    throw UnsupportedError(
      'Direct Google Drive OAuth import is not supported on this desktop target. '
      'Use Files and choose a Google Drive for desktop synced folder instead.',
    );
  }
}

const _drivePayloadQuery = "trashed = false and ("
    "name contains '.json' or "
    "name contains '.xml' or "
    "name contains '.csv' or "
    "name contains '.sql' or "
    "name contains '.pb' or "
    "name contains '.protobuf' or "
    "name contains '.bin' or "
    "mimeType = 'application/json' or "
    "mimeType = 'text/xml' or "
    "mimeType = 'application/xml' or "
    "mimeType = 'text/csv' or "
    "mimeType = 'application/octet-stream')";

String _contentTypeFromDrive(String name, String? mimeType) {
  final guessed = guessContentTypeFromName(name);
  if (guessed != 'auto') return guessed;

  final mt = mimeType?.toLowerCase() ?? '';
  if (mt.contains('json')) return 'application/json';
  if (mt.contains('xml')) return 'application/xml';
  if (mt.contains('csv')) return 'text/csv';
  if (mt.contains('octet-stream')) return 'application/x-protobuf';
  return 'auto';
}
