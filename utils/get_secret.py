#!/usr/bin/env python3
"""
Quick OCI Vault Secret Retrieval

Retrieves the csv-processor-aws-secret-key-cnx secret from OCI Vault.
"""

import os
import base64
import oci

def get_secret():
    """Get the AWS secret key from OCI Vault."""
    
    # Configuration
    secret_name = "csv-processor-aws-secret-key-cnx"
    vault_id = os.environ.get('VAULT_OCID')
    compartment_id_env = os.environ.get('OCI_COMPARTMENT_ID')
    
    if not vault_id:
        print("Error: VAULT_OCID environment variable not set")
        print("Run: source oci-compartment.env")
        return None
    
    print(f"Getting secret: {secret_name}")
    print(f"From vault: {vault_id}")
    
    try:
        # Try Resource Principals first, then config file
        try:
            signer = oci.auth.signers.get_resource_principals_signer()
            config = {}
            compartment_id = signer.compartment_id
            print("Using Resource Principal authentication")
        except Exception:
            config = oci.config.from_file()
            signer = None
            # Use compartment from environment if available, otherwise use tenancy
            compartment_id = compartment_id_env or config['tenancy']
            print("Using config file authentication")
            print(f"Compartment ID: {compartment_id}")
        
        # Create clients - VaultsClient to list secrets, SecretsClient to get content
        if signer:
            vaults_client = oci.vault.VaultsClient(config, signer=signer)
            secrets_client = oci.secrets.SecretsClient(config, signer=signer)
        else:
            vaults_client = oci.vault.VaultsClient(config)
            secrets_client = oci.secrets.SecretsClient(config)
        
        # Find secret using VaultsClient
        print("Searching for all secrets in vault...")
        all_secrets = vaults_client.list_secrets(
            compartment_id=compartment_id,
            vault_id=vault_id
        )
        
        print(f"Found {len(all_secrets.data)} secrets in vault:")
        for secret in all_secrets.data:
            print(f"  - {secret.secret_name} (state: {secret.lifecycle_state})")
        
        # Now search for our specific secret
        response = vaults_client.list_secrets(
            compartment_id=compartment_id,
            vault_id=vault_id,
            name=secret_name
        )
        
        if not response.data:
            print(f"Secret '{secret_name}' not found")
            return None
        
        secret_id = response.data[0].id
        
        # Get secret content using SecretsClient
        bundle = secrets_client.get_secret_bundle(secret_id=secret_id)
        content = bundle.data.secret_bundle_content.content
        secret_value = base64.b64decode(content).decode('utf-8')
        
        print("✅ Secret retrieved successfully!")
        return secret_value
        
    except Exception as e:
        print(f"Error: {e}")
        return None


if __name__ == "__main__":
    secret = get_secret()
    if secret:
        print(f"Secret value: {secret}")
    else:
        print("Failed to retrieve secret")