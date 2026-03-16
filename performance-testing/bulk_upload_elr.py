#!/usr/bin/env python3
"""
RTR ELR Bulk Upload Utility
Sends HL7 messages from a local directory to the NEDSS-DataIngestion (DI) API.

Usage:
    python3 bulk_upload_elr.py --dir ./test_data --host localhost --clientid <ID> --clientsecret <SECRET>
"""

import os
import requests
import argparse
import sys

def get_token(base_url, client_id, client_secret):
    """Obtain JWT token from DI API"""
    url = f"{base_url}/api/auth/token"
    headers = {
        "clientid": client_id,
        "clientsecret": client_secret
    }
    try:
        response = requests.post(url, headers=headers)
        response.raise_for_status()
        return response.text # TokenController returns raw string of token
    except Exception as e:
        print(f"Error obtaining token: {e}")
        sys.exit(1)

def upload_elr(base_url, token, file_path, client_id, client_secret):
    """Upload a single HL7 file to DI API"""
    url = f"{base_url}/api/elrs"
    headers = {
        "Authorization": f"Bearer {token}",
        "msgType": "HL7_ELR",
        "clientid": client_id,
        "clientsecret": client_secret,
        "Content-Type": "text/plain"
    }
    
    with open(file_path, 'r') as f:
        payload = f.read()
    
    try:
        response = requests.post(url, headers=headers, data=payload)
        if response.status_code == 200:
            print(f"Successfully uploaded: {os.path.basename(file_path)}")
            return True
        else:
            print(f"Failed to upload {os.path.basename(file_path)}: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"Error uploading {os.path.basename(file_path)}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="Bulk upload ELR HL7 files to RTR Data Ingestion API")
    parser.add_argument("--dir", required=True, help="Directory containing .hl7 files")
    parser.add_argument("--host", default="localhost", help="DI API host (default: localhost)")
    parser.add_argument("--port", default="8081", help="DI API port (default: 8081)")
    parser.add_argument("--clientid", required=True, help="Keycloak Client ID")
    parser.add_argument("--clientsecret", required=True, help="Keycloak Client Secret")
    
    args = parser.parse_args()
    
    base_url = f"http://{args.host}:{args.port}"
    
    # 1. Get Token
    print("Authenticating...")
    token = get_token(base_url, args.clientid, args.clientsecret)
    
    # 2. Iterate and Upload
    files = [f for f in os.listdir(args.dir) if f.endswith(".hl7")]
    if not files:
        print(f"No .hl7 files found in {args.dir}")
        return

    print(f"Found {len(files)} files. Starting upload...")
    success_count = 0
    for filename in files:
        file_path = os.path.join(args.dir, filename)
        if upload_elr(base_url, token, file_path, args.clientid, args.clientsecret):
            success_count += 1
    
    print(f"\nUpload Complete!")
    print(f"Successfully uploaded: {success_count}/{len(files)}")

if __name__ == "__main__":
    main()
