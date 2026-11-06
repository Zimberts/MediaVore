#!/usr/bin/env bash
# Checks the iOS signing files locally, then stores them as the Actions secrets used by the
# `ios` job of release.yml (DOCS/ios-release.md). Run on a Mac, by a repository admin.
#
#   tool/setup_ios_signing_secrets.sh DIST.p12 PROFILE.mobileprovision AuthKey_XXXXXXXXXX.p8 ISSUER_ID
#
# The .p12 password is asked without echo. Key ID = the XXXXXXXXXX of the .p8 file name.
# Nothing is written to disk; the files can be deleted (or moved to a password manager) after.
set -euo pipefail

REPO="${REPO:-Zimberts/MediaVore}"
BUNDLE_ID="fr.zimberts.mediavore"
here="$(cd "$(dirname "$0")" && pwd)"

if [[ $# -ne 4 ]]; then
  sed -n '2,8p' "$0" >&2
  exit 1
fi
p12="$1" profile="$2" p8="$3" issuer="$4"
for f in "$p12" "$profile" "$p8"; do [[ -f $f ]] || { echo "No such file: $f" >&2; exit 1; }; done

key_id="$(basename "$p8" .p8)"
key_id="${key_id#AuthKey_}"
[[ $key_id =~ ^[A-Z0-9]{10}$ ]] || { echo "Cannot read the key ID from '$p8' (expected AuthKey_<10 chars>.p8)." >&2; exit 1; }
[[ $issuer =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$ ]] || { echo "Issuer ID '$issuer' is not a UUID." >&2; exit 1; }
grep -q -- '-----BEGIN PRIVATE KEY-----' "$p8" || { echo "$p8 is not a PEM private key." >&2; exit 1; }

command -v gh > /dev/null || { echo "gh is not installed." >&2; exit 1; }
gh auth status > /dev/null 2>&1 || { echo "Run 'gh auth login' first." >&2; exit 1; }
if [[ $(gh api "repos/$REPO" --jq '.permissions.admin') != "true" ]]; then
  echo "Your gh account is not admin of $REPO: it cannot add secrets." >&2
  exit 1
fi

read -rsp "Password of $p12: " p12_password; echo

# 1. Certificate: SHA-1 and common name, in the format of `security find-identity`.
#    -legacy is needed by OpenSSL 3 for .p12 files exported by older Keychain Access versions.
cert_pem=""
for legacy in "" "-legacy"; do
  # shellcheck disable=SC2086 # $legacy is empty or one flag
  if cert_pem=$(openssl pkcs12 $legacy -in "$p12" -nokeys -clcerts -passin fd:3 3<<< "$p12_password" 2> /dev/null) \
     && [[ -n $cert_pem ]]; then
    break
  fi
done
[[ -n $cert_pem ]] || { echo "Cannot open $p12: wrong password, or openssl too old (brew install openssl)." >&2; exit 1; }
sha1=$(openssl x509 -noout -fingerprint -sha1 <<< "$cert_pem" | sed 's/.*=//; s/://g' | tr 'a-f' 'A-F')
cn=$(openssl x509 -noout -subject -nameopt multiline <<< "$cert_pem" | sed -n 's/^ *commonName *= *//p')
echo "Certificate: $cn ($sha1)"

# 2. Profile: same checks as CI (App Store profile for $BUNDLE_ID, not expired, contains the certificate).
profile_plist=$(mktemp)
trap 'rm -f "$profile_plist"' EXIT
security cms -D -i "$profile" > "$profile_plist"
printf '  1) %s "%s"\n' "$sha1" "$cn" \
  | python3 "$here/ios_signing.py" check-profile "$profile_plist" --bundle-id "$BUNDLE_ID"

# 3. Secrets.
read -rp "Store these 6 secrets in $REPO? [y/N] " answer
[[ $answer == [yY] ]] || exit 1
base64 < "$p12" | tr -d '\n' | gh secret set IOS_DIST_CERT_P12_BASE64 -R "$REPO"
printf '%s' "$p12_password" | gh secret set IOS_DIST_CERT_PASSWORD -R "$REPO"
base64 < "$profile" | tr -d '\n' | gh secret set IOS_PROVISIONING_PROFILE_BASE64 -R "$REPO"
gh secret set ASC_PRIVATE_KEY -R "$REPO" < "$p8"
printf '%s' "$key_id" | gh secret set ASC_KEY_ID -R "$REPO"
printf '%s' "$issuer" | gh secret set ASC_ISSUER_ID -R "$REPO"
unset p12_password
gh secret list -R "$REPO" | grep -E '^(IOS_|ASC_)'
echo "Done. Test with Actions -> Release -> Run workflow (testflight unchecked: build + signing only)."
