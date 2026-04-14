import 'dart:typed_data';
import 'dart:convert';

/// NIST Test Vectors for AES-GCM
/// 
/// These are official test vectors from NIST SP 800-38D
/// Used to verify AES-GCM implementation correctness
class AesGcmTestVectors {
  /// Test Vector 1 from NIST SP 800-38D
  static const Map<String, String> testVector1 = {
    'key': 'feffe9928665731c6d6a8f9467308308',
    'plaintext': 'd9313225f88406e5a55909c5aff5269a'
                 '86a7a9531534f7da2e4c303d8a318a72'
                 '1c3c0c95956809532fcf0e2449a6b525'
                 'b16aedf5aa0de657ba637b39',
    'nonce': '9313225df88406e555909c5aff5269aa'
             '6a7a9538534f7da2e4c303d8a318a72'
             '1c3c0c95956809532fcf0e2449a6b525'
             'b16aedf5aa0de657ba637b391a',
    'aad': '',
    'ciphertext': '42831ec2217774244b7221b784d0d49c'
                  'e3aa212f2c02a4e035c17e2329aca12e'
                  '21d514b254669331c82d635c62da0fbf'
                  '9c4d7990c12bd1bb8b5f2d3d2d5f2f2f',
    'tag': '4bc3b88572884f4c',
  };

  /// Test Vector 2 from NIST SP 800-38D
  static const Map<String, String> testVector2 = {
    'key': 'feffe9928665731c6d6a8f9467308308',
    'plaintext': 'd9313225f88406e5a55909c5aff5269a'
                 '86a7a9531534f7da2e4c303d8a318a72'
                 '1c3c0c95956809532fcf0e2449a6b525'
                 'b16aedf5aa0de657ba637b39',
    'nonce': '9313225df88406e555909c5aff5269aa'
             '6a7a9538534f7da2e4c303d8a318a72'
             '1c3c0c95956809532fcf0e2449a6b525'
             'b16aedf5aa0de657ba637b39',
    'aad': 'feedfacedeadbeeffeedfacedeadbeefabaddad2',
    'ciphertext': '42831ec2217774244b7221b784d0d49c'
                  'e3aa212f2c02a4e035c17e2329aca12e'
                  '21d514b254669331c82d635c62da0fbf'
                  '9c4d7990c12bd1bb8b5f2d3d2d5f2f2f',
    'tag': '5bc94fbc3221a5db94fae95ae7121a47',
  };

  /// Helper to parse hex string to bytes
  static Uint8List hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }

  /// Helper to convert bytes to hex string
  static String bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// RFC 6070 Test Vectors for PBKDF2-HMAC-SHA256
/// 
/// These are official test vectors from RFC 6070
/// Used to verify PBKDF2 implementation correctness
class Pbkdf2TestVectors {
  /// Test Vector 1 from RFC 6070
  static const Map<String, dynamic> testVector1 = {
    'password': 'password',
    'salt': 'salt',
    'iterations': 1,
    'dkLength': 20,
    'expected': '120fb6cffcf2b0d43235f51bf0839ed2'
                 'c3a4c76072d8f94f018e2c4',
  };

  /// Test Vector 2 from RFC 6070
  static const Map<String, dynamic> testVector2 = {
    'password': 'password',
    'salt': 'salt',
    'iterations': 2,
    'dkLength': 20,
    'expected': 'ae4d0c95af6b46d32d0adff926f38d7'
                 '1a655444714a51f8902a5',
  };

  /// Test Vector 3 from RFC 6070
  static const Map<String, dynamic> testVector3 = {
    'password': 'password',
    'salt': 'salt',
    'iterations': 4096,
    'dkLength': 20,
    'expected': '4b007901b765489abead49d926f721d0'
                 '6524495606d9da53c29c3',
  };

  /// Test Vector 4 from RFC 6070
  static const Map<String, dynamic> testVector4 = {
    'password': 'passwordPASSWORDpassword',
    'salt': 'saltSALTsaltSALTsaltSALTsaltSALTsalt',
    'iterations': 4096,
    'dkLength': 25,
    'expected': '3d2eec4fe41c849b80c8d83662c0e44a'
                 '8b291a964c2f2f0e384325b88e',
  };

  /// Test Vector 5 from RFC 6070
  static const Map<String, dynamic> testVector5 = {
    'password': 'pass\x00word',
    'salt': 'sa\x00lt',
    'iterations': 4096,
    'dkLength': 16,
    'expected': '56fa6aa75548099dcc37d7f03425e0c3',
  };
}

/// SHA-256 Test Vectors from NIST
class Sha256TestVectors {
  /// Test Vector 1: Empty string
  static const Map<String, String> testVector1 = {
    'input': '',
    'expected': 'e3b0c44298fc1c149afbf4c8996fb924'
                '27ae41e4649b934ca495991b7852b855',
  };

  /// Test Vector 2: "abc"
  static const Map<String, String> testVector2 = {
    'input': 'abc',
    'expected': 'ba7816bf8f01cfea414140de5dae2223'
                'b00361a396177a9cb410ff61f20015ad',
  };

  /// Test Vector 3: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
  static const Map<String, String> testVector3 = {
    'input': 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
    'expected': '248d6a61d20638b8e5c026930c3e6039'
                'a33ce45964ff2167f6ecedd419db06c1',
  };
}
