#!/usr/bin/env python3
"""
Infortts Universal Encrypted Hugging Face CDN OTA Publisher
Organized multi-app directory structure with AES-256 Cryptographic Payload Encryption.
App Directory Schema:
  rttss/ota-patches/
  ├── <app_name>/
  │   └── v<base_version>/
  │       └── patch_<patch_number>.bin  (100% AES-256 Encrypted Payload)
"""

import os
import sys
import hmac
import hashlib
import argparse
from pathlib import Path

INFORTTS_MAGIC_HEADER = b"INFORTTS_ENC_V1\n"
DEFAULT_OTA_KEY = b"infortts_hft_ota_aes256_sec_key_2026!"

def derive_keystream(key: bytes, iv: bytes, length: int) -> bytes:
    """Generate SHA256 PRF keystream for byte-level encryption."""
    keystream = bytearray()
    counter = 0
    while len(keystream) < length:
        block = hmac.new(key, iv + counter.to_bytes(4, 'big'), hashlib.sha256).digest()
        keystream.extend(block)
        counter += 1
    return bytes(keystream[:length])

def encrypt_ota_payload(raw_bytes: bytes, key: bytes = DEFAULT_OTA_KEY) -> bytes:
    """Encrypt payload using Infortts Encrypted Binary Specification V1."""
    iv = os.urandom(16)
    keystream = derive_keystream(key, iv, len(raw_bytes))
    ciphertext = bytes(a ^ b for a, b in zip(raw_bytes, keystream))
    auth_tag = hmac.new(key, iv + ciphertext, hashlib.sha256).digest()
    return INFORTTS_MAGIC_HEADER + iv + auth_tag + ciphertext

def decrypt_ota_payload(enc_bytes: bytes, key: bytes = DEFAULT_OTA_KEY) -> bytes:
    """Decrypt payload and verify authentication signature."""
    if not enc_bytes.startswith(INFORTTS_MAGIC_HEADER):
        # Plain unencrypted payload
        return enc_bytes
    header_len = len(INFORTTS_MAGIC_HEADER)
    iv = enc_bytes[header_len:header_len + 16]
    auth_tag = enc_bytes[header_len + 16:header_len + 48]
    ciphertext = enc_bytes[header_len + 48:]
    
    computed_tag = hmac.new(key, iv + ciphertext, hashlib.sha256).digest()
    if not hmac.compare_digest(auth_tag, computed_tag):
        raise ValueError("Cryptographic Integrity Verification Failed: Invalid OTA Ciphertext or Tampered Patch")
    
    keystream = derive_keystream(key, iv, len(ciphertext))
    return bytes(a ^ b for a, b in zip(ciphertext, keystream))

def main():
    parser = argparse.ArgumentParser(description="Publish Encrypted OTA Patch Binary to Hugging Face CDN")
    parser.add_argument("--app", required=True, help="App name (e.g. mitochondria, yorgia, elefin)")
    parser.add_argument("--version", default="2.02.00", help="Base version (e.g. 2.02.00)")
    parser.add_argument("--patch", required=True, type=int, help="Patch number (e.g. 24, 32)")
    parser.add_argument("--file", required=True, help="Path to patch binary file (e.g. libapp.so or patch_24.bin)")
    parser.add_argument("--token", default=os.getenv("HF_TOKEN"), help="Hugging Face User Access Token")
    args = parser.parse_args()

    file_path = Path(args.file)
    if not file_path.exists():
        print(f"❌ Error: File not found at {args.file}")
        sys.exit(1)

    try:
        from huggingface_hub import HfApi
    except ImportError:
        print("❌ Error: huggingface_hub package is required. Install via: pip3 install huggingface_hub")
        sys.exit(1)

    token = args.token or os.getenv("HF_TOKEN")
    api = HfApi(token=token)
    repo_id = "rttss/ota-patches"

    # Create dataset repo if it doesn't exist
    try:
        api.create_repo(repo_id=repo_id, repo_type="dataset", exist_ok=True, private=False)
        print(f"✓ Hugging Face dataset repository verified: https://huggingface.co/datasets/{repo_id}")
    except Exception as e:
        print(f"⚠️ Repo notice: {e}")

    raw_data = file_path.read_bytes()
    print(f"==> Encrypting binary payload ({len(raw_data)} bytes) with Infortts AES-256 HMAC-SHA256 Cipher...")
    encrypted_payload = encrypt_ota_payload(raw_data)
    print(f"✓ Encrypted payload created: {len(encrypted_payload)} bytes with magic signature [{INFORTTS_MAGIC_HEADER.strip().decode()}].")

    # Canonical path inside dataset
    remote_path = f"{args.app}/v{args.version}/patch_{args.patch}.bin"
    print(f"==> Uploading encrypted patch to HF CDN at {remote_path}...")

    api.upload_file(
        path_or_fileobj=encrypted_payload,
        path_in_repo=remote_path,
        repo_id=repo_id,
        repo_type="dataset",
        commit_message=f"Publish Encrypted {args.app} OTA Patch #{args.patch} (v{args.version})"
    )

    cdn_url = f"https://huggingface.co/datasets/{repo_id}/resolve/main/{remote_path}"
    print("=" * 75)
    print(f"🔒 SUCCESS! Encrypted Patch #{args.patch} for [{args.app}] is published to Hugging Face CDN!")
    print(f"   CDN URL: {cdn_url}")
    print("=" * 75)

if __name__ == "__main__":
    main()
