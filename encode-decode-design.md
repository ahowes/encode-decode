# Encode/Decode Tool — Design Document

## Overview

A browser-based text transformation utility providing encoding, decoding, hashing, and formatting operations through a single unified interface. Inspired by the Google Admin Toolbox Encode/Decode tool.

---

## Goals

- Provide a fast, frictionless way to transform text without writing code
- Support the most common encoding/decoding operations in one place
- Require no login, installation, or external dependencies

---

## User Interface

### Layout

- Single-page application
- Text input area (top) — paste or type source content
- Transformation selector — choose operation type
- Action button — execute the transformation
- Output area (bottom) — display result

### UX Requirements

- Copy-to-clipboard button on the output area
- Clear/reset button to wipe both input and output
- Transformation selector shows operations grouped by category
- Output is read-only and selectable

---

## Transformations

### Base64

| Operation | Description |
|---|---|
| Base64 Encode | Encode text to standard Base64 (RFC 4648) |
| Base64 Decode | Decode standard Base64 to plain text |
| Base64Url Encode | Encode using URL-safe alphabet (`-` and `_` instead of `+` and `/`) |
| Base64Url Decode | Decode URL-safe Base64 |

### URL Encoding

| Operation | Description |
|---|---|
| URL Encode | Percent-encode special characters for use in URLs |
| URL Decode | Decode percent-encoded URL strings |

### Hashing

| Operation | Description |
|---|---|
| MD5 Hash | Generate MD5 digest of input text |

> Note: MD5 is provided for legacy/diagnostic use only. It is not suitable for security-sensitive hashing.

### SAML

| Operation | Description |
|---|---|
| SAML Encode | Deflate-compress and Base64-encode a SAML assertion |
| SAML Decode | Base64-decode and inflate a SAML assertion to readable XML |

> Primary use case: diagnosing SSO and federated authentication flows.

### JSON

| Operation | Description |
|---|---|
| Pretty Print | Format a minified or unformatted JSON string with indentation |

### Quoted-Printable

| Operation | Description |
|---|---|
| Quoted-Printable Encode | Encode text to Quoted-Printable format (RFC 2045) |
| Quoted-Printable Decode | Decode Quoted-Printable encoded text |

> Primarily used in email MIME encoding.

### Character Encoding

| Operation | Description |
|---|---|
| UTF-16 Decode | Decode a UTF-16 byte sequence to readable text |
| Hex Decode | Decode a hexadecimal string to plain text |

---

## Transformation Categories (for UI grouping)

1. Base64
2. URL
3. Hashing
4. SAML / SSO
5. JSON
6. Email (Quoted-Printable)
7. Character Encoding (UTF-16, Hex)

---

## Out of Scope (v1)

The following were evaluated and excluded from the initial version:

| Feature | Reason Excluded |
|---|---|
| Base32 encode/decode | Low demand outside niche use cases |
| SHA-256 / SHA-1 hashing | Can be added in v2; MD5 covers immediate diagnostic needs |
| AES / symmetric encryption | Encryption adds key management complexity beyond scope |
| Binary / octal / decimal conversion | Developer-focused; separate tool more appropriate |
| UTF-16 Encode / Hex Encode | Decode-only covers the primary diagnostic use case |
| File upload | Binary file handling significantly increases scope |
| Operation chaining | Increases UI complexity; defer to v2 |
| API / CLI access | Out of scope for a web utility |

---

## Target Users

| User Type | Primary Use Cases |
|---|---|
| Google Workspace / G Suite admins | SAML/SSO debugging, email header analysis |
| Web developers | Base64, URL encoding, JSON formatting, JWT inspection |
| Active Directory / LDAP admins | FILETIME / pwdLastSet conversion |
| Security engineers | MD5 verification, SAML assertion inspection |

---

## Future Considerations (v2+)

- SHA-1 and SHA-256 hashing
- Hex encode (complement existing hex decode)
- UTF-16 encode
- Operation chaining (pipe output to next transformation)
- File upload for binary-safe operations
- Dark mode
- Keyboard shortcut to trigger transformation
