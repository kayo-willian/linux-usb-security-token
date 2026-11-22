#!/usr/bin/env python3
"""Comment only the mandatory pam_usb rule; preserve all other PAM lines."""
import argparse
import os
from pathlib import Path
import re
import stat
import sys
import tempfile

ACTIVE = re.compile(rb"^[ \t]*auth[ \t]+required[ \t]+pam_usb\.so(?:[ \t]+[^\r\n]*)?[ \t]*$")
COMMENTED = re.compile(rb"^[ \t]*#[ \t]*auth[ \t]+required[ \t]+pam_usb\.so(?:[ \t]+[^\r\n]*)?[ \t]*$")
USB_AUTH = re.compile(rb"^[ \t]*auth[ \t]+.*\bpam_usb\.so\b")


def prepare(data):
    lines = data.splitlines(keepends=True)
    indices = [i for i, line in enumerate(lines) if ACTIVE.fullmatch(line.rstrip(b"\r\n"))]
    others = [line for line in lines if USB_AUTH.match(line) and not ACTIVE.fullmatch(line.rstrip(b"\r\n"))]
    if others:
        raise ValueError("Another pam_usb auth rule exists in GDM. Review manually; no change was made.")
    if not indices:
        if any(COMMENTED.fullmatch(line.rstrip(b"\r\n")) for line in lines):
            return None
        raise ValueError("Mandatory 'auth required pam_usb.so' rule not found; no change was made.")
    if len(indices) != 1:
        raise ValueError("Multiple mandatory USB rules found; review manually. No change was made.")
    lines[indices[0]] = b"# " + lines[indices[0]]
    return b"".join(lines)


def process(path, check=False):
    path = Path(path)
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError("The target must be a regular file, not a symbolic link.")
    data = path.read_bytes()
    updated = prepare(data)
    if updated is None:
        print("The mandatory GDM USB rule is already commented. No change was made.")
        return 3
    if check:
        print("Proposed change: comment only 'auth required pam_usb.so' in gdm-password.")
        return 0
    temp = None
    try:
        fd, temp = tempfile.mkstemp(prefix=".gdm-password-usb-", dir=path.parent)
        with os.fdopen(fd, "wb") as stream:
            stream.write(updated)
            stream.flush()
            if os.geteuid() == 0:
                os.fchown(stream.fileno(), info.st_uid, info.st_gid)
            os.fchmod(stream.fileno(), stat.S_IMODE(info.st_mode))
            # Replacing the inode would otherwise drop ACLs and other xattrs.
            # Abort without replacing the original if any attribute cannot be copied.
            for name in os.listxattr(path, follow_symlinks=False):
                value = os.getxattr(path, name, follow_symlinks=False)
                os.setxattr(temp, name, value, follow_symlinks=False)
            os.fsync(stream.fileno())
        current = path.lstat()
        if (current.st_dev, current.st_ino, current.st_mtime_ns, current.st_size) != (info.st_dev, info.st_ino, info.st_mtime_ns, info.st_size) or path.read_bytes() != data:
            raise ValueError("The file changed during recovery. Nothing was replaced; retry after review.")
        os.replace(temp, path)
        temp = None
    finally:
        if temp is not None:
            os.unlink(temp)
    print("Mandatory GDM USB rule commented. All other PAM lines were preserved.")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    parser.add_argument("--check", action="store_true", help="read-only check")
    args = parser.parse_args()
    try:
        return process(args.file, args.check)
    except (OSError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
