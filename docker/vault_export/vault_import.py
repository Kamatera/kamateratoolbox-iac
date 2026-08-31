#!/usr/bin/env python3
import argparse
import json
import os
import subprocess
import sys
import tempfile


def gpg_decrypt_file(source, target, password):
    subprocess.run(
        [
            "gpg",
            "--batch",
            "--yes",
            "--pinentry-mode", "loopback",
            "--passphrase-fd", "0",
            "--decrypt",
            "--output", target,
            source,
        ],
        input=password + "\n",
        text=True,
        check=True,
    )


def extract_secret(exported_value):
    """
    vault kv get -format=json on KV v2 produces:

      {
        "data": {
          "data": {...},
          "metadata": {...}
        }
      }

    The export script stores the outer .data, so exported_value is:

      {
        "data": {...},
        "metadata": {...}
      }

    Return:
      actual secret data,
      version metadata
    """

    if (
        isinstance(exported_value, dict)
        and "data" in exported_value
        and "metadata" in exported_value
        and isinstance(exported_value["metadata"], dict)
        and (
            "version" in exported_value["metadata"]
            or "created_time" in exported_value["metadata"]
        )
    ):
        return exported_value["data"], exported_value["metadata"]

    # Fallback for KV v1-style exports
    return exported_value, None


def relative_path(full_path, source_mount):
    source_mount = source_mount.strip("/")
    prefix = source_mount + "/"

    if not full_path.startswith(prefix):
        raise ValueError(
            f"Backup path {full_path!r} does not start with "
            f"source mount {source_mount!r}"
        )

    return full_path[len(prefix):]


def kv_put(mount, path, data):
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".json",
        encoding="utf-8",
    ) as f:
        json.dump(data, f)
        f.flush()

        subprocess.check_call([
            "vault",
            "kv",
            "put",
            f"-mount={mount}",
            path,
            f"@{f.name}",
        ])


def restore_custom_metadata(mount, path, metadata):
    if not metadata:
        return

    custom_metadata = metadata.get("custom_metadata")

    if not custom_metadata:
        return

    cmd = [
        "vault",
        "kv",
        "metadata",
        "put",
        f"-mount={mount}",
    ]

    for key, value in custom_metadata.items():
        cmd.append(f"-custom-metadata={key}={value}")

    cmd.append(path)

    subprocess.check_call(cmd)


def main():
    parser = argparse.ArgumentParser(
        description="Import a vault_export.py GPG-encrypted backup"
    )

    parser.add_argument(
        "filename",
        help="Encrypted export.json.gpg backup",
    )

    parser.add_argument(
        "--source-mount",
        default="kv",
        help="KV mount name stored in the backup (default: kv)",
    )

    parser.add_argument(
        "--target-mount",
        default=None,
        help="KV mount to restore into (default: same as source)",
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show paths without writing anything",
    )

    args = parser.parse_args()

    password = os.environ.get("VAULT_EXPORT_ENCRYPTION_PASSWORD")

    if not password:
        print(
            "VAULT_EXPORT_ENCRYPTION_PASSWORD is not set",
            file=sys.stderr,
        )
        sys.exit(1)

    target_mount = args.target_mount or args.source_mount

    with tempfile.TemporaryDirectory() as tmpdir:
        decrypted_filename = os.path.join(tmpdir, "vault.json")

        print("Decrypting backup...")
        gpg_decrypt_file(
            args.filename,
            decrypted_filename,
            password,
        )

        with open(decrypted_filename, encoding="utf-8") as f:
            backup = json.load(f)

        total = 0

        for item in backup:
            if not isinstance(item, dict):
                raise ValueError(
                    f"Invalid backup entry: expected object, got {type(item)}"
                )

            for full_path, exported_value in item.items():
                path = relative_path(
                    full_path,
                    args.source_mount,
                )

                secret, metadata = extract_secret(exported_value)

                if args.dry_run:
                    print(
                        f"{full_path} -> "
                        f"{target_mount}/{path}"
                    )
                    total += 1
                    continue

                print(
                    f"Restoring "
                    f"{target_mount}/{path}"
                )

                kv_put(
                    target_mount,
                    path,
                    secret,
                )

                restore_custom_metadata(
                    target_mount,
                    path,
                    metadata,
                )

                total += 1

        if args.dry_run:
            print(f"Would restore {total} secrets")
        else:
            print(f"Restored {total} secrets")


if __name__ == "__main__":
    main()
