# Contribution guidelines for this fork

This fork preserves the original project's educational architecture:
GNOME/GDM, PAM with pam_usb, udev session locking, and Bash/Python helper
scripts. The code is not copied from or coupled to a different USB
security project.

## Language policy

- **English** for source code, identifiers, comments, filenames,
  terminal messages, tests, main README, technical guides and commits.
- **Brazilian Portuguese is permitted for pull request titles and
  descriptions** to make human review easier.
- Development prompts to AI assistants may be written in Portuguese,
  but generated source and documentation should follow the English
  policy above.
- A separate Portuguese documentation tree may be added later, with
  English as the canonical technical reference until then.
- Do **not** rename Linux/system service interfaces such as
  `gdm-password`, `pam_usb.so`, `common-auth` or
  `/etc/udev/rules.d/80-usb.rules`; these are fixed external names.

## Safety and validation

Authentication changes can lock users out. Do not change a live PAM
stack or lock a desktop just to validate a pull request. Prefer
reproducible tests with temporary files, Bash syntax checks and
read-only inspection. The project's recovery scripts intentionally
require a real interactive terminal and an explicit confirmation.

Before opening a PR, run:

```bash
python3 -m unittest discover -s tests -v
```

These offline tests do not prove that USB authentication behaves
correctly on a physical host. New live tests require an independent
TTY/console recovery path, backups, and explicit human authorization.

Keep upstream contributions narrow. Large fork-specific style changes
should be presented separately from targeted bug fixes intended for the
original maintainer.
