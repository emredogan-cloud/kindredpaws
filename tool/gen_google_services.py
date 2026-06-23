#!/usr/bin/env python3
"""Ensure android/app/google-services.json exists for the Android build (P3-0).

The Android build's auto-applied google-services Gradle plugin requires this
file to exist, but the REAL Firebase config is a per-environment artifact that
is **gitignored and never committed** (no credentials in a public repo). So:

  * If a real google-services.json is already present (a developer/CI that
    placed the founder's real config, or a build that decoded it from a
    secret), we DO NOT touch it.
  * Otherwise we write a clearly-labelled BUILD-ONLY PLACEHOLDER with fake
    identifiers + the correct package name. It only satisfies the Gradle
    plugin so the APK compiles; the app never connects to it because the live
    Firebase connection is gated behind KP_FIREBASE_PROVISIONED (default off),
    so CI/tests stay offline. Real builds set the flag + supply the real
    config (see REQUIRED_ENVIRONMENTS.md).

No real key is ever committed or generated here.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "android" / "app" / "google-services.json"
PACKAGE = "com.kindredpaws.kindredpaws"

PLACEHOLDER = {
    "project_info": {
        "project_number": "000000000000",
        "project_id": "kindredpaws-ci-placeholder",
        "storage_bucket": "kindredpaws-ci-placeholder.appspot.com",
    },
    "client": [
        {
            "client_info": {
                "mobilesdk_app_id": "1:000000000000:android:cibuildplaceholder0000",
                "android_client_info": {"package_name": PACKAGE},
            },
            "oauth_client": [],
            # Build-only placeholder — NOT a real key (the app never connects to
            # it; live Firebase is gated behind KP_FIREBASE_PROVISIONED).
            "api_key": [{"current_key": "ci-build-placeholder-not-a-real-key"}],
            "services": {"appinvite_service": {"other_platform_oauth_client": []}},
        }
    ],
    "configuration_version": "1",
}


def main() -> None:
    if OUT.exists():
        print(f"gen_google_services: {OUT} already present — leaving it untouched")
        return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(PLACEHOLDER, indent=2) + "\n")
    print(f"gen_google_services: wrote BUILD-ONLY placeholder {OUT}")


if __name__ == "__main__":
    main()
