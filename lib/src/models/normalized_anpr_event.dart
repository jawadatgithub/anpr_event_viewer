import 'anpr_image_ref.dart';

class NormalizedAnprEvent {
  final String id;
  final String? plateNumber;
  final String? plateNumberArabic;
  final String? country;
  final String? emirate;
  final String? vehicleType;
  final String? vehicleColor;
  final String? make;
  final String? model;
  final String? cameraId;
  final String? cameraName;
  final String? locationName;
  final String? lane;
  final String? direction;
  final double? confidence;
  final DateTime? timestamp;
  final AnprImageRef? vehicleImage;
  final AnprImageRef? plateImage;
  final String sourceFormat;
  final Map<String, dynamic> rawFields;
  final String rawPayload;

  const NormalizedAnprEvent({
    required this.id,
    this.plateNumber,
    this.plateNumberArabic,
    this.country,
    this.emirate,
    this.vehicleType,
    this.vehicleColor,
    this.make,
    this.model,
    this.cameraId,
    this.cameraName,
    this.locationName,
    this.lane,
    this.direction,
    this.confidence,
    this.timestamp,
    this.vehicleImage,
    this.plateImage,
    required this.sourceFormat,
    required this.rawFields,
    required this.rawPayload,
  });

  String get displayPlate {
    if (plateNumber?.trim().isNotEmpty == true) return plateNumber!;
    if (plateNumberArabic?.trim().isNotEmpty == true) return plateNumberArabic!;
    return 'Unknown plate';
  }

  String get displayLocation => locationName ?? cameraName ?? cameraId ?? 'Unknown location';

  factory NormalizedAnprEvent.fromMappedFields({
    required String sourceFormat,
    required Map<String, dynamic> fields,
    required String rawPayload,
    required String fallbackId,
  }) {
    String? s(List<String> aliases) => _first(fields, aliases)?.toString().trim();

    double? d(List<String> aliases) {
      final value = s(aliases);
      if (value == null || value.isEmpty) return null;
      return double.tryParse(value.replaceAll('%', '').trim());
    }

    return NormalizedAnprEvent(
      id: s(A.id) ?? fallbackId,
      plateNumber: s(A.plateNumber),
      plateNumberArabic: s(A.plateNumberArabic),
      country: s(A.country),
      emirate: s(A.emirate),
      vehicleType: s(A.vehicleType),
      vehicleColor: s(A.vehicleColor),
      make: s(A.make),
      model: s(A.model),
      cameraId: s(A.cameraId),
      cameraName: s(A.cameraName),
      locationName: s(A.locationName),
      lane: s(A.lane),
      direction: s(A.direction),
      confidence: d(A.confidence),
      timestamp: DateTime.tryParse(s(A.timestamp) ?? ''),
      vehicleImage: AnprImageRef.fromDynamic(s(A.vehicleImage)),
      plateImage: AnprImageRef.fromDynamic(s(A.plateImage)),
      sourceFormat: sourceFormat,
      rawFields: fields,
      rawPayload: rawPayload,
    );
  }

  static dynamic _first(Map<String, dynamic> map, List<String> aliases) {
    for (final alias in aliases) {
      if (map.containsKey(alias) && map[alias] != null) return map[alias];
    }

    final normalized = <String, dynamic>{};
    for (final entry in map.entries) {
      normalized[_norm(entry.key)] = entry.value;
    }

    for (final alias in aliases) {
      final key = _norm(alias);
      if (normalized.containsKey(key) && normalized[key] != null) return normalized[key];
    }

    return null;
  }

  static String _norm(String key) {
    return key.trim().replaceAll('_', '').replaceAll('-', '').replaceAll(' ', '').replaceAll('.', '').toLowerCase();
  }
}

class A {
  static const id = ['id', 'eventId', 'event_id', 'معرف', 'رقم_الحدث'];

  static const plateNumber = [
    'plateNumber',
    'plate_number',
    'plate',
    'plateNo',
    'plate_no',
    'licensePlate',
    'رقم_اللوحة',
    'رقم اللوحة',
    'اللوحة',
  ];

  static const plateNumberArabic = [
    'plateNumberArabic',
    'plate_number_arabic',
    'arabicPlate',
    'arabic_plate',
    'اللوحة_بالعربية',
    'رقم_اللوحة_بالعربية',
  ];

  static const country = ['country', 'countryArabic', 'الدولة'];
  static const emirate = ['emirate', 'region', 'city', 'الإمارة', 'الامارة', 'المنطقة'];

  static const vehicleType = ['vehicleType', 'vehicle_type', 'type', 'vehicle.type', 'نوع_المركبة', 'نوع المركبة'];
  static const vehicleColor = ['vehicleColor', 'vehicle_color', 'color', 'vehicle.color', 'لون_المركبة', 'اللون'];
  static const make = ['make', 'brand', 'manufacturer', 'vehicle.make', 'الشركة', 'الصانع'];
  static const model = ['model', 'vehicleModel', 'vehicle.model', 'الطراز', 'الموديل'];

  static const cameraId = ['cameraId', 'camera_id', 'cameraID', 'camera.cameraId', 'معرف_الكاميرا'];
  static const cameraName = ['cameraName', 'camera_name', 'camera', 'camera.cameraName', 'اسم_الكاميرا', 'الكاميرا'];
  static const locationName = ['locationName', 'location_name', 'location', 'site', 'camera.locationName', 'الموقع', 'اسم_الموقع'];
  static const lane = ['lane', 'laneNo', 'lane_no', 'camera.lane', 'المسار', 'الحارة'];
  static const direction = ['direction', 'movement', 'entryExit', 'camera.direction', 'الاتجاه', 'الحركة'];

  static const confidence = ['confidence', 'score', 'accuracy', 'الثقة', 'الدقة'];
  static const timestamp = ['timestamp', 'time', 'dateTime', 'date_time', 'eventTime', 'وقت_الحدث', 'التاريخ'];

  static const vehicleImage = [
    'vehicleImage',
    'vehicle_image',
    'vehicleImageBase64',
    'vehicle_image_base64',
    'carImage',
    'car_image',
    'image',
    'images.vehicleImage',
    'images.vehicle_image',
    'صورة_المركبة',
    'صورة السيارة',
  ];

  static const plateImage = [
    'plateImage',
    'plate_image',
    'plateImageBase64',
    'plate_image_base64',
    'plateCrop',
    'plate_crop',
    'images.plateImage',
    'images.plate_image',
    'صورة_اللوحة',
  ];
}
