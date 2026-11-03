/// UUID v7: version nibble 7, RFC 4122 variant (8, 9, a or b).
final RegExp uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
