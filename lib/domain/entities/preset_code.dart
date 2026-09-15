import 'filter_config.dart';
import 'filter_preset.dart';
import 'package:doctorfilter/core/math/kelvin_engine.dart';

/// A short code that carries a preset's three values and nothing else.
///
/// Sharing a preset should not require an account, a server, or the user's
/// contacts. The whole preset fits in five characters, so it travels in any
/// message the user was already going to send.
///
/// The name is deliberately not encoded. It would make the code long enough to
/// need copy-paste rather than reading aloud, and a name in one language is
/// noise to whoever receives it. The values are the preset.
abstract final class PresetCode {
  /// Crockford's alphabet: no I, L, O or U, so a code read aloud or typed from
  /// a photo cannot become a different valid code.
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Kelvin is stored in 50 K steps. Finer than anyone can see, and it keeps
  /// the whole payload inside 25 bits.
  static const int _kelvinStep = 50;

  static const int _payloadBits = 21;
  static const int _checksumBits = 4;

  static String encode({
    required int kelvin,
    required int densityPercent,
    required int extraDimPercent,
  }) {
    final k = ((kelvin.clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin) -
                KelvinEngine.minKelvin) ~/
            _kelvinStep)
        .clamp(0, 127);
    final d = densityPercent.clamp(0, FilterConfig.maxDensityPercent);
    final e = extraDimPercent.clamp(0, FilterConfig.maxExtraDimPercent);

    final payload = (k << 14) | (d << 7) | e;
    final value = (payload << _checksumBits) | _checksum(payload);

    final buffer = StringBuffer();
    for (var shift = _payloadBits + _checksumBits - 5; shift >= 0; shift -= 5) {
      buffer.write(_alphabet[(value >> shift) & 0x1F]);
    }
    return buffer.toString();
  }

  static String ofPreset(FilterPreset preset) => encode(
        kelvin: preset.kelvin,
        densityPercent: preset.densityPercent,
        extraDimPercent: preset.extraDimPercent,
      );

  /// Returns null for anything that is not a valid code.
  ///
  /// The checksum is the point: without it a mistyped character yields a
  /// perfectly plausible preset several hundred kelvin away, and the user has
  /// no way of knowing they are not looking at what they were sent.
  static ({int kelvin, int densityPercent, int extraDimPercent})? decode(
    String code,
  ) {
    final cleaned = code.trim().toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length != 5) return null;

    var value = 0;
    for (final character in cleaned.split('')) {
      // Crockford's substitutions, so a code transcribed by a human still works.
      final normalised = switch (character) {
        'I' || 'L' => '1',
        'O' => '0',
        'U' => 'V',
        _ => character,
      };
      final index = _alphabet.indexOf(normalised);
      if (index < 0) return null;
      value = (value << 5) | index;
    }

    final payload = value >> _checksumBits;
    if (value & ((1 << _checksumBits) - 1) != _checksum(payload)) return null;

    final kelvin =
        KelvinEngine.minKelvin + ((payload >> 14) & 0x7F) * _kelvinStep;
    final density = (payload >> 7) & 0x7F;
    final extraDim = payload & 0x7F;

    // A code can be well-formed and still describe something outside what this
    // version allows; the caps are the app's promise, not the sender's.
    return (
      kelvin: kelvin.clamp(KelvinEngine.minKelvin, KelvinEngine.maxKelvin),
      densityPercent: density.clamp(0, FilterConfig.maxDensityPercent),
      extraDimPercent: extraDim.clamp(0, FilterConfig.maxExtraDimPercent),
    );
  }

  /// Not cryptography — a typo detector. Four bits catches the overwhelming
  /// majority of single-character slips, which is the whole failure mode here.
  static int _checksum(int payload) {
    var sum = 0;
    for (var shift = 0; shift < _payloadBits; shift += 5) {
      sum += (payload >> shift) & 0x1F;
    }
    return sum & ((1 << _checksumBits) - 1);
  }
}
