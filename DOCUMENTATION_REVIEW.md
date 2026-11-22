# Documentation review — October 1, 2026 (historical record)

This record describes the original documentation effort preceding the
English-language fork revision. It was based on the existing repository
and the commands and test results reported by the original maintainer.
It is a **historical note**, not a claim that the English fork ran the
original physical tests again.

## Original scope

| Document | Original review |
| --- | --- |
| \`README.md\` | Clarified the real Debian 13 hardware, repository structure, method status, GDM/TTY boundaries and recovery procedure |
| \`method-01/README.md\` | Preserved the session-lock experiment and its screenshots; distinguished historical automatic unlock from the final configuration |
| \`method-02/part-01.md\` | Marked USB-or-password as historical; explained shared PAM scope, pads, FAT/UUID cautions and the transition to Part 02 |
| \`method-02/part-02.md\` | Documented the final USB + password policy, backups, GDM-only PAM rule, removal-lock behavior, TTY recovery, tests and rollback |

## Accuracy limits of the original review

- The original logs recorded changes to udev, \`common-auth\`, \`gdm-password\` and successful \`pamtester\` authentications.
- Rejected logins, physical behavior and reboot persistence were reported by the original user. Negative \`pamtester\` transcripts or missing screenshots were **not invented**.
- The earlier pad-checking error was preserved as a historical result, not proof that removal caused corruption.
- The Method 01 automatic unlock scenario was retained only as history; the final Part 02 setup leaves that feature disabled.
- Other users, services, automatic login, fingerprint authentication and SSH were **not validated** in the original scope.

## Initial delivery and subsequent helper scripts

The original documentation was prepared as a standalone file package,
not as an immediate change to the upstream live host. The physical
authentication tests belong to the original maintainer's evidence.

The project later added a menu, helper scripts and offline tests.
The recovery helper disables only the mandatory GDM USB rule after
confirmation and a backup; it does not automatically restore an
entire PAM stack.

The later English fork translation updates names and cross-links.
It does **not** introduce new evidence of hardware validation or
change the original method's underlying authentication design.
