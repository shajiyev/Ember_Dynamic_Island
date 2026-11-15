#!/bin/bash
# Creates "Ember Code Signing", a self-signed code-signing certificate in your login
# keychain. Xcode signs Ember with it.
#
# macOS ties permissions such as Accessibility to an app's signature. Without a
# certificate, every build gets a new signature, so the permission is lost on each
# rebuild. Signed with this certificate, every build has the same signature and a
# permission granted once stays.
#
# Run once per Mac, from the repository root:
#     scripts/make-signing-certificate.sh
#
# The private key is made in a temporary folder, imported into your login keychain and
# deleted there. Nothing is written to the repository.

set -euo pipefail

NAME="Ember Code Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
    echo "\"$NAME\" is already in your login keychain. Nothing to do."
    exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/certificate.conf" <<EOF
[req]
distinguished_name = name
prompt = no
x509_extensions = extensions
[name]
CN = $NAME
[extensions]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

# Valid for 10 years. A password only protects the file on its way into the keychain.
PASSWORD=$(/usr/bin/openssl rand -hex 16)
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$WORK/certificate.conf" \
    -keyout "$WORK/key.pem" -out "$WORK/certificate.pem" 2>/dev/null
/usr/bin/openssl pkcs12 -export -name "$NAME" -inkey "$WORK/key.pem" -in "$WORK/certificate.pem" \
    -out "$WORK/identity.p12" -passout "pass:$PASSWORD"
security import "$WORK/identity.p12" -k "$KEYCHAIN" -P "$PASSWORD" -T /usr/bin/codesign >/dev/null

echo "Added \"$NAME\" to your login keychain."
echo "The first build may ask whether codesign may use the key: enter your Mac password"
echo "and click Always Allow."
