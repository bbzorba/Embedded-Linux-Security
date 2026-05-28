#!/usr/bin/bash

REAL_NAME="Baris Zorba"
EMAIL="bbzorba@hotmail.com"

echo "Installing signing tools..."
sudo apt update
sudo apt install -y gnupg debsigs debsig-verify

echo "Checking for existing GPG key..."

if gpg --list-secret-keys --with-colons | grep -q "$EMAIL"; then
    echo "GPG key already exists."
else
    echo "Generating new GPG key..."

    cat <<EOF > gpg_batch
Key-Type: RSA
Key-Length: 4096
Name-Real: $REAL_NAME
Name-Email: $EMAIL
Expire-Date: 0
%no-protection
%commit
EOF

    gpg --batch --generate-key gpg_batch
    rm gpg_batch
fi

GPG_FINGERPRINT=$(gpg --list-secret-keys --with-colons "$EMAIL" | grep fpr | head -n1 | awk -F: '{print $10}')

echo "Fingerprint:"
echo "$GPG_FINGERPRINT"

POLICY_ID=$(echo "$GPG_FINGERPRINT" | cut -c1-8)

echo "Using Policy ID: $POLICY_ID"

echo "Exporting public key..."
gpg --export "$GPG_FINGERPRINT" > outputs/public.key

echo "Creating debsig policy directories..."
sudo mkdir -p /etc/debsig/policies/$POLICY_ID
sudo mkdir -p /usr/share/debsig/keyrings/$POLICY_ID

sudo cp outputs/public.key /usr/share/debsig/keyrings/$POLICY_ID/

echo "Creating policy file..."

cat <<EOF | sudo tee /etc/debsig/policies/$POLICY_ID/mydebapp.pol
<?xml version="1.0"?>
<Policy xmlns="https://www.debian.org/debsig/1.0/">
  <Origin Name="mydebapp" id="$POLICY_ID" Description="My Secure Embedded Package"/>
  <Selection>
    <Required Type="origin" File="/usr/share/debsig/keyrings/$POLICY_ID/public.key"/>
  </Selection>
  <Verification MinVersion="0.1"/>
</Policy>
EOF

echo "Debsig setup complete."