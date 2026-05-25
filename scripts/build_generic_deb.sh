#!/usr/bin/bash

# Configuration
PKG_NAME="mydebapp"
VERSION="1.0"
DEB_DIR="$HOME/Desktop/Embedded_Systems/Security/debbuild"
PKG_DIR="$DEB_DIR/${PKG_NAME}-${VERSION}"
EMAIL="bbzorba@hotmail.com"

# 1. Setup & Cleanup (Start with a totally clean slate)
cd "$DEB_DIR" || exit
echo "Cleaning up old build artifacts..."
rm -rf "${PKG_NAME}-${VERSION}"
rm -f "${PKG_NAME}_${VERSION}"*

echo "Creating new project directory..."
mkdir -p "$PKG_DIR"

# 2. Initialize package
cd "$PKG_DIR" || exit
dh_make -s --createorig -e "$EMAIL" --yes

# 3. Create Control file
cat > debian/control <<EOF
Source: ${PKG_NAME}
Section: utils
Priority: optional
Maintainer: ${EMAIL}
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.2

Package: ${PKG_NAME}
Architecture: all
Description: Custom release file installer
 This is an automated build for embedded linux security.
EOF

# 4. Create Rules file with forced Tab characters
printf '#!/usr/bin/make -f\n%%:\n\tdh $@\n\noverride_dh_auto_build:\n\techo "Welcome to my secure embedded linux system" > myappliance-release\n\techo "version 1.0" >> myappliance-release\n\noverride_dh_auto_install:\n\tmkdir -p debian/mydebapp/etc\n\tinstall -m 644 myappliance-release debian/mydebapp/etc/myappliance-release\n' > debian/rules

# Ensure rules file is executable
chmod +x debian/rules

# 5. Build the package
debuild -us -uc

# 6. Install the package
echo "-----------------------------------"
echo "Installing generated package..."
cd "$DEB_DIR" || exit
# We use ./ to explicitly tell apt this is a local file
sudo apt install -y "./${PKG_NAME}_${VERSION}-1_all.deb"

# 7. Verify installation
echo "-----------------------------------"
echo "Verifying installation..."
if [ -f "/etc/myappliance-release" ]; then
    echo "SUCCESS: File found in /etc/"
    cat /etc/myappliance-release
else
    echo "ERROR: Installation failed."
fi