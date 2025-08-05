# PACE Authentication Implementation

This document describes the PACE (Password Authenticated Connection Establishment) authentication implementation for electronic Machine Readable Travel Documents (eMRTD).

## Overview

PACE is an authentication protocol that allows secure access to eMRTD documents using either:
- **MRZ Password**: Derived from the Machine Readable Zone data (birth date, expiry date, document number)
- **CAN Password**: Card Access Number provided by the user

## Implementation Details

### PACE Modes

The implementation supports two PACE modes:

```dart
enum PACEMode {
  mrz(1),  // MRZ-based authentication
  can(2),  // CAN-based authentication
}
```

### Usage

#### Basic PACE Authentication

```dart
final paceAuth = PACEAuthentication(nfcCard);

// Using MRZ password
final mrzPassword = '85010112345678901234567890'; // Derived from MRZ
final sessionKeys = await paceAuth.authenticate(mrzPassword, PACEMode.mrz);

// Using CAN password
final canPassword = '123456'; // User-provided CAN
final sessionKeys = await paceAuth.authenticate(canPassword, PACEMode.can);
```

#### Integration with MRTD Interface

The `MRTDInterface` class now supports PACE authentication:

```dart
final mrtd = MRTDInterface(nfcCard);

// Try PACE first, fall back to BAC
try {
  final mrzPassword = '${birthDate}${expiryDate}${documentNumber}';
  await mrtd.authenticateWithPACE(mrzPassword, PACEMode.mrz);
} catch (e) {
  // Fall back to BAC authentication
  await mrtd.authenticate(birthDate, expiryDate, documentNumber);
}
```

## Protocol Steps

The PACE implementation follows these steps:

1. **Select PACE Application**: Select the PACE application on the card
2. **Set MSE for PACE**: Configure the security environment with PACE algorithm and mode
3. **General Authenticate 1**: Get encrypted nonce from the card
4. **General Authenticate 2**: Key agreement phase 1 (mapping)
5. **General Authenticate 3**: Key agreement phase 2 (key exchange)
6. **General Authenticate 4**: Mutual authentication

## Security Features

- **Constant-time comparisons**: Prevents timing attacks
- **Secure random number generation**: Uses cryptographically secure random numbers
- **Session key derivation**: Proper key derivation using SHA1
- **Mutual authentication**: Both card and reader authenticate each other

## Error Handling

The implementation throws `AuthException` with descriptive messages for various failure scenarios:

- PACE application selection failure
- MSE configuration failure
- General Authenticate command failures
- Authentication token verification failure

## Limitations

This is a simplified implementation for demonstration purposes. In a production environment, you would need:

1. **Proper ASN.1 parsing**: More robust ASN.1 structure parsing
2. **Real cryptographic operations**: Actual ECDH key generation and computation
3. **3DES implementation**: Proper 3DES encryption/decryption
4. **Error recovery**: Better error handling and recovery mechanisms
5. **Performance optimization**: Optimized for real-world usage

## Testing

The implementation includes basic tests to verify:

- PACE authentication instance creation
- Exception handling with proper error messages
- Mock NFC card interface for testing

## References

- [ICAO 9303 - P11](https://www.icao.int/publications/Documents/9303_p11_cons_en.pdf)
- [BSI TR-03110](https://www.bsi.bund.de/EN/Publications/TechnicalGuidelines/tr03110/tr03110_node.html) 