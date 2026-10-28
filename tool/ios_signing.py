#!/usr/bin/env python3
"""iOS release signing helpers for the `ios` job of release.yml (#241).

  check-profile PROFILE_PLIST --bundle-id ID < identities.txt
      PROFILE_PLIST = the decoded provisioning profile (`security cms -D -i x.mobileprovision`),
      stdin = `security find-identity -v -p codesigning <keychain>`.
      Checks that the profile is an App Store profile for ID, not expired, and contains the
      imported distribution certificate. Prints KEY=VALUE lines for $GITHUB_ENV.

  export-options SRC DST --profile NAME --identity NAME --team TEAM --bundle-id ID
      Copies ios/ExportOptions.plist (#240) to DST with manual signing (CI has no Apple ID
      for automatic signing); every other key (method, uploadSymbols, ...) is kept.

Standard library only: runs with the python3 of the macOS runner.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import plistlib
import re
import sys
from pathlib import Path

DISTRIBUTION_PREFIXES = ("Apple Distribution:", "iPhone Distribution:")
EXPIRY_WARNING_DAYS = 30
# `  1) 0123...ABCD "Apple Distribution: Name (TEAMID)"`
IDENTITY_LINE = re.compile(r'^\s*\d+\)\s+([0-9A-F]{40})\s+"(.+)"\s*$')


class SigningError(Exception):
    pass


def parse_identities(text: str) -> dict[str, str]:
    """SHA-1 (upper case) -> common name, from `security find-identity -v` output."""
    identities = {}
    for line in text.splitlines():
        match = IDENTITY_LINE.match(line)
        if match:
            identities[match.group(1)] = match.group(2)
    return identities


def check_profile(
    profile: dict,
    bundle_id: str,
    identities: dict[str, str],
    now: dt.datetime,
) -> tuple[dict[str, str], list[str]]:
    """Returns (variables for $GITHUB_ENV, warnings). Raises SigningError."""
    name = profile.get("Name")
    uuid = profile.get("UUID")
    teams = profile.get("TeamIdentifier") or []
    if not name or not uuid or len(teams) != 1:
        raise SigningError("Not a provisioning profile (Name, UUID or TeamIdentifier missing).")
    team = teams[0]

    entitlements = profile.get("Entitlements", {})
    app_id = entitlements.get("application-identifier")
    if app_id != f"{team}.{bundle_id}":
        raise SigningError(
            f"Profile '{name}' is for App ID '{app_id}', expected '{team}.{bundle_id}'."
        )
    # Development and ad hoc profiles list devices; enterprise ones provision all devices.
    if (
        profile.get("ProvisionedDevices")
        or profile.get("ProvisionsAllDevices")
        or entitlements.get("get-task-allow")
    ):
        raise SigningError(
            f"Profile '{name}' is not an App Store profile "
            "(it lists devices or allows debugging): create an 'App Store Connect' profile."
        )

    expiry = profile.get("ExpirationDate")
    if not isinstance(expiry, dt.datetime):
        raise SigningError(f"Profile '{name}' has no ExpirationDate.")
    expiry = expiry.replace(tzinfo=dt.timezone.utc)  # plistlib returns naive UTC dates
    if expiry <= now:
        raise SigningError(f"Profile '{name}' expired on {expiry:%Y-%m-%d}.")
    warnings = []
    if expiry - now < dt.timedelta(days=EXPIRY_WARNING_DAYS):
        warnings.append(f"Profile '{name}' expires on {expiry:%Y-%m-%d}: renew it.")

    profile_certs = {
        hashlib.sha1(der).hexdigest().upper() for der in profile.get("DeveloperCertificates", [])
    }
    matching = [
        identities[sha1]
        for sha1 in sorted(profile_certs & identities.keys())
        if identities[sha1].startswith(DISTRIBUTION_PREFIXES)
    ]
    if not matching:
        raise SigningError(
            f"The distribution certificate of IOS_DIST_CERT_P12_BASE64 ({sorted(identities.values())}) "
            f"is not in profile '{name}': regenerate the profile with this certificate."
        )

    variables = {
        "IOS_PROFILE_NAME": name,
        "IOS_PROFILE_UUID": uuid,
        "IOS_TEAM_ID": team,
        "IOS_SIGNING_IDENTITY": matching[0],
    }
    return variables, warnings


def export_options(
    options: dict, profile_name: str, identity: str, team: str, bundle_id: str
) -> dict:
    if not options.get("method"):
        raise SigningError("ios/ExportOptions.plist has no 'method'.")
    declared_team = options.get("teamID")
    if declared_team and declared_team != team:
        raise SigningError(
            f"ios/ExportOptions.plist teamID {declared_team} differs from the profile team {team}."
        )
    options = dict(options)
    options.update(
        signingStyle="manual",
        teamID=team,
        signingCertificate=identity,
        provisioningProfiles={bundle_id: profile_name},
        # The IPA is uploaded by a separate step (altool), so exportArchive must only export.
        destination="export",
    )
    return options


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)

    check = sub.add_parser("check-profile")
    check.add_argument("profile_plist", type=Path)
    check.add_argument("--bundle-id", required=True)

    export = sub.add_parser("export-options")
    export.add_argument("src", type=Path)
    export.add_argument("dst", type=Path)
    export.add_argument("--profile", required=True)
    export.add_argument("--identity", required=True)
    export.add_argument("--team", required=True)
    export.add_argument("--bundle-id", required=True)

    args = parser.parse_args(argv)
    try:
        if args.command == "check-profile":
            profile = plistlib.loads(args.profile_plist.read_bytes())
            variables, warnings = check_profile(
                profile,
                args.bundle_id,
                parse_identities(sys.stdin.read()),
                dt.datetime.now(dt.timezone.utc),
            )
            for warning in warnings:
                print(f"::warning::{warning}", file=sys.stderr)
            for key, value in variables.items():
                print(f"{key}={value}")
        else:
            options = export_options(
                plistlib.loads(args.src.read_bytes()),
                args.profile,
                args.identity,
                args.team,
                args.bundle_id,
            )
            args.dst.write_bytes(plistlib.dumps(options))
    except SigningError as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
