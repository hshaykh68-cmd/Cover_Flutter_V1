# Cryptographic Primitives Module

## Overview

This module provides the core cryptographic primitives for the Cover app, implementing industry-standard algorithms for encryption, key derivation, and hashing.

## Components

### 1. AES-GCM Cipher (`aes_gcm_cipher.dart`)

**Purpose**: Authenticated encryption using AES-256-GCM (Galois/Counter Mode)

**Features**:
- AES-256 encryption (256-bit key)
- Authenticated encryption with associated data (AAD)
- Automatic MAC verification to detect tampering
- Support for custom nonces or automatic random nonce generation
- Serialization to/from bytes and base64 for storage

**Security Properties**:
- Confidentiality: Data is encrypted using AES-256
- Integrity: GCM mode provides authentication via MAC
- Nonce uniqueness: Random 12-byte nonces prevent replay attacks

**Usage Example**:
```dart
final key = cryptoService.generateRandomKey(length: 32);
final cipher = AesGcmCipher.fromKeyBytes(key);

// Encrypt
final encrypted = await cipher.encrypt(
  plaintext,
  associatedData: aad,
  nonce: nonce, // Optional - random if not provided
);

// Decrypt
final decrypted = await cipher.decrypt(encrypted, associatedData: aad);
```

### 2. PBKDF2 Key Deriver (`pbkdf2_key_deriver.dart`)

**Purpose**: Derive cryptographic keys from passwords/PINs using PBKDF2-HMAC-SHA256

**Features**:
- Configurable iteration count (default: 100,000)
- Configurable key length (default: 32 bytes for AES-256)
- Configurable salt length (default: 16 bytes)
- Security parameter validation
- Salt generation and storage

**Security Properties**:
- Slow key derivation to prevent brute force attacks
- Salt ensures same password produces different keys
- HMAC-SHA256 for cryptographic strength

**Usage Example**:
```dart
final deriver = Pbkdf2KeyDeriver(
  iterations: 100000,
  keyLength: 32,
  saltLength: 16,
);

// Derive key with new salt
final result = await deriver.deriveKey('my_password');
print(result.key); // 32-byte derived key
print(result.salt); // 16-byte salt (store this!)

// Derive same key using stored salt
final sameKey = await deriver.deriveKeyWithSalt('my_password', storedSalt);
```

### 3. Crypto Service (`crypto_service.dart`, `crypto_service_impl.dart`)

**Purpose**: Unified interface for all cryptographic operations

**Features**:
- Key derivation from passwords
- AES-GCM encryption/decryption (bytes and strings)
- SHA-256 hashing
- Secure random number generation
- Constant-time comparison to prevent timing attacks

**Usage Example**:
```dart
final cryptoService = ref.watch(cryptoServiceProvider);

// Derive key from PIN
final keyResult = await cryptoService.deriveKey('1234');

// Encrypt data
final encrypted = await cryptoService.encryptString(
  'secret message',
  keyResult.key,
);

// Decrypt data
final decrypted = await cryptoService.decryptString(encrypted, keyResult.key);

// Hash data
final hash = cryptoService.sha256Hash(data);

// Constant-time comparison (for PIN verification)
final match = cryptoService.constantTimeCompare(pin1, pin2);
```

## Test Vectors

The module includes comprehensive test vectors from NIST and RFC standards:

### AES-GCM Test Vectors
- Source: NIST SP 800-38D
- Validates encryption/decryption correctness
- Tests nonce reuse scenarios
- Tests AAD (Associated Authenticated Data)

### PBKDF2 Test Vectors
- Source: RFC 6070
- Validates key derivation correctness
- Tests various iteration counts
- Tests special characters in passwords

### SHA-256 Test Vectors
- Source: NIST
- Validates hash function correctness
- Tests empty string, short strings, and long strings

## Security Considerations

### Key Management
- Keys are never logged or exposed
- Keys are kept in memory only when needed
- Use secure storage for long-term key persistence (Phase 2)

### Random Number Generation
- Uses cryptographically secure random number generator
- Nonces are always unique for each encryption
- Salts are randomly generated for each key derivation

### Timing Attacks
- PIN comparison uses constant-time algorithm
- Prevents attackers from guessing PINs via timing analysis

### Parameter Security
- PBKDF2 iterations: 100,000 (OWASP recommendation for SHA-256)
- Key length: 32 bytes (256 bits for AES-256)
- Salt length: 16 bytes (128 bits)
- Nonce length: 12 bytes (96 bits, recommended for GCM)

## Performance

### Encryption Speed
- AES-GCM is hardware-accelerated on most modern devices
- Typical speed: ~100 MB/s on modern smartphones

### Key Derivation Speed
- PBKDF2 with 100,000 iterations: ~100-200ms on modern devices
- This slowness is intentional to prevent brute force attacks
- Consider caching derived keys for performance

## Testing

Run the crypto tests:
```bash
flutter test test/core/crypto/
```

Test coverage includes:
- ✅ Encryption/decryption round-trip
- ✅ Empty data handling
- ✅ Large data handling
- ✅ Tampering detection (ciphertext, MAC, nonce)
- ✅ AAD (Associated Authenticated Data)
- ✅ Serialization (bytes, base64)
- ✅ Key derivation with various parameters
- ✅ Key derivation with special characters and unicode
- ✅ SHA-256 hashing against NIST test vectors
- ✅ Constant-time comparison
- ✅ End-to-end crypto flows

## Dependencies

- `cryptography`: Dart cryptography package for AES-GCM, PBKDF2, SHA-256
- `flutter_riverpod`: Dependency injection

## Future Enhancements

- [ ] Hardware-backed key integration (Phase 2)
- [ ] Key rotation strategy
- [ ] Memory cleanup for sensitive data
- [ ] Performance benchmarks
- [ ] FIPS 140-2 validation (if required)
