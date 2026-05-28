#!/usr/bin/env bash
set -euo pipefail

trap 'echo "❌ ERROR at line $LINENO"' ERR

echo "=================================================="
echo "START BUILD SCRIPT"
echo "=================================================="

PKG_NAME="mydebapp"
VERSION="1.0"

DEB_DIR="$HOME/debbuild"
PKG_DIR="$DEB_DIR/${PKG_NAME}-${VERSION}"

REAL_NAME="Baris Zorba"
EMAIL="bbzorba@hotmail.com"

# ---------------- INSTALL ----------------
echo "[1] tools..."
sudo apt-get update -qq
sudo apt-get install -y -qq build-essential devscripts dh-make debhelper gnupg

# ---------------- GPG ----------------
echo "[2] gpg..."

if ! gpg --list-secret-keys "$EMAIL" >/dev/null 2>&1; then
cat <<EOF > key
Key-Type: RSA
Key-Length: 4096
Name-Real: $REAL_NAME
Name-Email: $EMAIL
Expire-Date: 0
%no-protection
%commit
EOF
gpg --batch --generate-key key
rm -f key
fi

FPR=$(gpg --list-secret-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10; exit}')

# ---------------- WORKSPACE ----------------
echo "[3] workspace..."

rm -rf "$PKG_DIR"
mkdir -p "$DEB_DIR"
cd "$DEB_DIR"

rm -rf "${PKG_NAME}-${VERSION}"
mkdir "${PKG_NAME}-${VERSION}"
cd "${PKG_NAME}-${VERSION}"

# ---------------- DH MAKE ----------------
echo "[4] dh_make..."

export DEBIAN_FRONTEND=noninteractive
export TERM=dumb

dh_make -s -e "$EMAIL" --createorig -y < /dev/null

rm -f debian/*.ex debian/*.EX 2>/dev/null || true

# ---------------- CONTROL ----------------
cat > debian/control <<EOF
Source: $PKG_NAME
Section: utils
Priority: optional
Maintainer: $REAL_NAME <$EMAIL>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.2

Package: $PKG_NAME
Architecture: all
Depends: \${misc:Depends}
Description: simple package
 test
EOF

# ---------------- RULES ----------------
cat > debian/rules <<'EOF'
#!/usr/bin/make -f

%:
	dh $@

override_dh_auto_build:
	echo "BUILD OK" > myappliance-release

override_dh_auto_install:
	mkdir -p debian/mydebapp/etc
	install -m 644 myappliance-release debian/mydebapp/etc/
EOF

chmod +x debian/rules

# ---------------- BUILD ----------------
echo "[5] build..."

debuild -us -uc -b

# ---------------- FIND FILES SAFELY ----------------
echo "[6] artifacts..."

cd "$DEB_DIR"

DEB=$(find . -maxdepth 2 -name "*.deb" | head -n1)
CHG=$(find . -maxdepth 2 -name "*.changes" | head -n1)

echo "✔ deb: $DEB"
echo "✔ changes: $CHG"

# ---------------- SIGN ----------------
echo "[7] sign..."

debsign -k"$FPR" "$CHG"

gpg --detach-sign --armor "$DEB"

# ---------------- VERIFY (SAFE) ----------------
echo "[8] verify..."

if ls *.dsc 1>/dev/null 2>&1; then
    dscverify --keyring ~/.gnupg/pubring.kbx *.dsc || true
else
    echo "⚠ no .dsc file (binary-only build)"
fi

gpg --verify "$DEB.asc" "$DEB"

# ---------------- INSTALL ----------------
echo "[9] install..."

sudo apt install -y "$DEB"

echo "=================================================="
echo "DONE SUCCESS"
echo "=================================================="

cat /etc/myappliance-release || true