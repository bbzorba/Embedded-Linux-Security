#!/usr/bin/bash

# Configuration
REAL_NAME="Baris Zorba"
EMAIL="bbzorba@hotmail.com"
PKG_NAME="mydebapp"
VERSION="1.0"
DEB_DIR="$HOME/Desktop/Embedded_Systems/Security/debbuild"
PKG_DIR="$DEB_DIR/${PKG_NAME}-${VERSION}"

# 1. Install required tools
echo "Installing build and signing tools..."
sudo apt update
sudo apt install -y build-essential devscripts dh-make debhelper coreutils diffutils make gnupg

# 2. Conditional GPG Key Generation (Unattended, Empty Passphrase)
echo "Checking for existing GPG key..."
if gpg --list-secret-keys --with-colons | grep -q "$EMAIL"; then
    echo "=> GPG key for $EMAIL already exists. Skipping generation."
else
    echo "=> No GPG key found for $EMAIL. Generating a new key pair..."
    cat <<EOF > gpg_batch_config
Key-Type: RSA
Key-Length: 4096
Name-Real: $REAL_NAME
Name-Email: $EMAIL
Expire-Date: 0
%no-protection
%commit
EOF
    gpg --batch --generate-key gpg_batch_config
    rm gpg_batch_config
    echo "=> GPG key generated successfully."
fi

# Extract the full fingerprint to avoid the "long key ID discouraged" warning
GPG_FINGERPRINT=$(gpg --list-secret-keys --with-colons "$EMAIL" | grep fpr | head -n 1 | awk -F: '{print $10}')
echo "Using GPG Fingerprint: $GPG_FINGERPRINT"

# 3. Setup Workspace & Clean old artifacts
cd "$DEB_DIR" || exit
echo "Cleaning up old build artifacts..."
rm -rf "${PKG_NAME}-${VERSION}"
rm -f "${PKG_NAME}_${VERSION}"*

mkdir -p "$PKG_DIR"
cd "$PKG_DIR" || exit

# 4. Initialize Package Structure
dh_make -s --createorig -e "$EMAIL" --yes

# Overwrite Control File
cat > debian/control <<EOF
Source: ${PKG_NAME}
Section: utils
Priority: optional
Maintainer: ${REAL_NAME} <${EMAIL}>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.2

Package: ${PKG_NAME}
Architecture: all
Description: Custom release file installer
 This is an automated signed build for embedded linux security.
EOF

# Overwrite Rules File
printf '#!/usr/bin/make -f\n%%:\n\tdh $@\n\noverride_dh_auto_build:\n\techo "Welcome to my secure embedded linux system" > myappliance-release\n\techo "version 1.0" >> myappliance-release\n\noverride_dh_auto_install:\n\tmkdir -p debian/mydebapp/etc\n\tinstall -m 644 myappliance-release debian/mydebapp/etc/myappliance-release\n' > debian/rules
chmod +x debian/rules

# 5. Build an unsigned package first
debuild -us -uc

# 6. Sign the package build artifacts using debsign
echo "-----------------------------------"
echo "Signing the package artifacts..."
cd "$DEB_DIR" || exit
CHANGES_FILE="${PKG_NAME}_${VERSION}-1_amd64.changes"

debsign -k"$GPG_FINGERPRINT" "$CHANGES_FILE"

# 7. Verify package signatures using your personal public keyring explicitly
echo "Verifying package signature..."
dscverify --keyring "$HOME/.gnupg/pubring.kbx" "${PKG_NAME}_${VERSION}-1.dsc"

# 8. Safe Installation (Removes conflicting old packages first)
echo "-----------------------------------"
echo "Preparing system for installation..."
sudo apt remove -y myapprel mydebapp 2>/dev/null

echo "Installing newly built package..."
sudo apt install -y "./${PKG_NAME}_${VERSION}-1_all.deb"

# 9. Final Verification
echo "-----------------------------------"
echo "Verifying target file creation..."
if [ -f "/etc/myappliance-release" ]; then
    echo "SUCCESS: File found in /etc/"
    cat /etc/myappliance-release
else
    echo "ERROR: Target file missing."
fi