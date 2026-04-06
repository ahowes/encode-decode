# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a native macOS app (SwiftUI) for encoding, decoding, hashing, and formatting text. The design spec is in `encode-decode-design.md`.

## Transformations to Implement

Grouped by category (used for UI picker grouping):

| Category | Operations |
|---|---|
| Base64 | Encode, Decode, Base64Url Encode, Base64Url Decode |
| URL | Encode, Decode |
| Hashing | MD5 (diagnostic use only) |
| SAML / SSO | Encode (deflate + base64), Decode (base64 + inflate) |
| JSON | Pretty Print |
| Email | Quoted-Printable Encode, Quoted-Printable Decode |
| Character Encoding | UTF-16 Decode, Hex Decode |

## UI Layout

- Input `TextEditor` (top)
- `Picker` for transformation selection, grouped by category
- Transform button
- Output `TextEditor` (bottom, read-only)
- Copy-to-clipboard button on output
- Clear/reset button for both fields

## Architecture Notes

- SAML encode/decode requires zlib deflate/inflate — use `Compression` framework (`COMPRESSION_ZLIB`) with raw deflate (no header/checksum)
- MD5 requires `CryptoKit` (`Insecure.MD5`)
- All transformations should be pure functions that take `String` → `Result<String, Error>`
- No external dependencies; use only Apple frameworks
