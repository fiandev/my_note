import 'package:encrypt/encrypt.dart' as enc;

class CryptoHelper {
  enc.Encrypter _createEncrypter(String pin) {
    final key =
        enc.Key.fromUtf8(pin.padRight(32, '0').substring(0, 32)); // 256-bit key
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  enc.IV _ivFromId(String id) {
    return enc.IV.fromUtf8(id.padRight(16, '0').substring(0, 16));
  }

  String encrypt(String plainText, String pin, String noteId) {
    final encrypter = _createEncrypter(pin);
    final iv = _ivFromId(noteId);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText, String pin, String noteId) {
    final encrypter = _createEncrypter(pin);
    final iv = _ivFromId(noteId);
    final encrypted = enc.Encrypted.fromBase64(encryptedText);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
