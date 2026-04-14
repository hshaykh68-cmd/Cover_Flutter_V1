import 'dart:typed_data';

/// Represents encrypted data with its associated metadata
class EncryptedData {
  /// The encrypted bytes
  final Uint8List data;
  
  /// The initialization vector (IV) used for encryption
  final Uint8List iv;
  
  /// Optional authentication tag (for authenticated encryption)
  final Uint8List? authTag;
  
  /// The encryption algorithm used
  final String algorithm;
  
  const EncryptedData({
    required this.data,
    required this.iv,
    this.authTag,
    this.algorithm = 'AES-256-GCM',
  });
  
  /// Convert to a combined byte array (data + iv + authTag)
  Uint8List toBytes() {
    final totalLength = data.length + iv.length + (authTag?.length ?? 0);
    final combined = Uint8List(totalLength);
    
    int offset = 0;
    combined.setRange(offset, offset + iv.length, iv);
    offset += iv.length;
    combined.setRange(offset, offset + data.length, data);
    offset += data.length;
    if (authTag != null) {
      combined.setRange(offset, offset + authTag!.length, authTag!);
    }
    
    return combined;
  }
  
  /// Create EncryptedData from combined byte array
  static EncryptedData fromBytes(Uint8List combined, int ivLength, {int? authTagLength}) {
    final iv = combined.sublist(0, ivLength);
    final dataEnd = authTagLength != null ? combined.length - authTagLength : combined.length;
    final data = combined.sublist(ivLength, dataEnd);
    final authTag = authTagLength != null ? combined.sublist(dataEnd) : null;
    
    return EncryptedData(
      data: data,
      iv: iv,
      authTag: authTag,
    );
  }
  
  /// Convert to base64 string
  String toBase64() {
    return toBytes().toString();
  }
  
  /// Create from base64 string
  static EncryptedData fromBase64(String base64, int ivLength, {int? authTagLength}) {
    // This would require converting base64 to bytes
    // For now, return a placeholder
    throw UnimplementedError('Base64 conversion not yet implemented');
  }
}
