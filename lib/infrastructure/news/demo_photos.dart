import 'dart:math';
import 'dart:typed_data';

/// Des photos de démo pour le mode mémoire, dessinées à la volée : un ciel, un
/// soleil, une montagne et un sol, en PNG (lisible sur toutes les
/// plateformes, sans fichier ni dépendance).
abstract final class DemoPhotos {
  /// Une scène parmi quelques-unes, d'après [seed].
  static Uint8List scene(int seed, {int width = 192, int height = 144}) {
    final palette = _palettes[seed % _palettes.length];
    final random = Random(seed);
    final sunX = width * (0.2 + random.nextDouble() * 0.6);
    final sunY = height * (0.15 + random.nextDouble() * 0.2);
    final peak = width * (0.3 + random.nextDouble() * 0.4);
    final horizon = height * 0.62;

    final pixels = Uint8List(height * (width * 3 + 1));
    var offset = 0;
    for (var y = 0; y < height; y++) {
      pixels[offset++] = 0; // Filtre « aucun » pour la ligne.
      for (var x = 0; x < width; x++) {
        final color = switch (true) {
          _ when y >= horizon => _mix(
            palette.ground,
            palette.groundFar,
            (height - y) / (height - horizon),
          ),
          _ when (y - height * 0.3) > (x - peak).abs() * 0.7 =>
            palette.mountain,
          _ when pow(x - sunX, 2) + pow(y - sunY, 2) < pow(height * 0.09, 2) =>
            palette.sun,
          _ => _mix(palette.skyTop, palette.skyBottom, y / horizon),
        };
        pixels[offset++] = color.$1;
        pixels[offset++] = color.$2;
        pixels[offset++] = color.$3;
      }
    }
    return _png(width, height, pixels);
  }

  static const _palettes = [
    // Matin au lac, forêt, coucher de soleil, montagne, plage, veillée.
    (
      skyTop: (110, 180, 240),
      skyBottom: (200, 230, 250),
      sun: (255, 240, 170),
      mountain: (120, 140, 160),
      ground: (40, 110, 170),
      groundFar: (90, 160, 210),
    ),
    (
      skyTop: (140, 200, 235),
      skyBottom: (220, 240, 250),
      sun: (255, 250, 200),
      mountain: (70, 120, 80),
      ground: (50, 120, 50),
      groundFar: (110, 170, 80),
    ),
    (
      skyTop: (250, 140, 90),
      skyBottom: (255, 210, 140),
      sun: (255, 245, 210),
      mountain: (120, 70, 90),
      ground: (90, 60, 50),
      groundFar: (160, 100, 70),
    ),
    (
      skyTop: (80, 140, 220),
      skyBottom: (180, 210, 240),
      sun: (255, 255, 230),
      mountain: (150, 150, 165),
      ground: (100, 140, 70),
      groundFar: (160, 190, 110),
    ),
    (
      skyTop: (90, 190, 240),
      skyBottom: (190, 235, 255),
      sun: (255, 235, 130),
      mountain: (90, 170, 200),
      ground: (230, 200, 140),
      groundFar: (250, 225, 170),
    ),
    (
      skyTop: (20, 30, 70),
      skyBottom: (60, 60, 110),
      sun: (250, 240, 210),
      mountain: (35, 40, 70),
      ground: (150, 70, 30),
      groundFar: (240, 150, 50),
    ),
  ];

  static (int, int, int) _mix((int, int, int) a, (int, int, int) b, double t) {
    final k = t.clamp(0.0, 1.0);
    return (
      (a.$1 + (b.$1 - a.$1) * k).round(),
      (a.$2 + (b.$2 - a.$2) * k).round(),
      (a.$3 + (b.$3 - a.$3) * k).round(),
    );
  }

  /// PNG RGB 8 bits, données zlib en blocs « stockés » (non compressés).
  static Uint8List _png(int width, int height, Uint8List scanlines) {
    final out = BytesBuilder()..add([137, 80, 78, 71, 13, 10, 26, 10]);
    final header = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8) // Profondeur.
      ..setUint8(9, 2); // RGB.
    _chunk(out, 'IHDR', header.buffer.asUint8List());
    _chunk(out, 'IDAT', _zlibStored(scanlines));
    _chunk(out, 'IEND', Uint8List(0));
    return out.toBytes();
  }

  static Uint8List _zlibStored(Uint8List data) {
    final out = BytesBuilder()..add([0x78, 0x01]);
    for (var start = 0; start < data.length || start == 0; start += 65535) {
      final end = min(start + 65535, data.length);
      final length = end - start;
      out
        ..addByte(end == data.length ? 1 : 0)
        ..add([
          length & 0xff,
          length >> 8,
          ~length & 0xff,
          (~length >> 8) & 0xff,
        ])
        ..add(Uint8List.sublistView(data, start, end));
      if (end == data.length) break;
    }
    var a = 1, b = 0;
    for (final byte in data) {
      a = (a + byte) % 65521;
      b = (b + a) % 65521;
    }
    final adler = (b << 16) | a;
    out.add([
      adler >> 24 & 0xff,
      adler >> 16 & 0xff,
      adler >> 8 & 0xff,
      adler & 0xff,
    ]);
    return out.toBytes();
  }

  static void _chunk(BytesBuilder out, String type, Uint8List data) {
    final typed = Uint8List.fromList([...type.codeUnits, ...data]);
    final length = ByteData(4)..setUint32(0, data.length);
    final crc = ByteData(4)..setUint32(0, _crc32(typed));
    out
      ..add(length.buffer.asUint8List())
      ..add(typed)
      ..add(crc.buffer.asUint8List());
  }

  static final _crcTable = List<int>.generate(256, (n) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
  });

  static int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc = _crcTable[(crc ^ byte) & 0xff] ^ (crc >> 8);
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
