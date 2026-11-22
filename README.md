
# Linux USB Security Token

Educational project demonstrating how to use a standard USB flash drive for session control and authentication on Linux.

**Fork note:** This repository is a language-standardized fork of [rique-decoder/linux-usb-security-token](https://github.com/rique-decoder/linux-usb-security-token). The original developer's GDM/PAM/udev design and hardware validation remain credited to the upstream project; renaming and translating helper files is not a redesign of that authentication system.

**Current status:** Method 02 — Part 02 validated on Debian 13 installed on a Lenovo IdeaPad 3i, including post-reboot testing. GDM requires USB flash drive + password; removing the USB drive locks the graphical session, and reconnecting it does not automatically unlock it.

## Documentation and Stage Order

| Stage | Objective | Status |
| --- | --- | --- |
| [Method 1](method-01/README.md) | Lock and request unlock with USB events via udev and loginctl | Validated as an experiment; in the final setup, only lock-on-removal remains active |
| [Method 02 — Part 01](method-02/part-01.md) | Authenticate via USB **or** password with pam_usb | Validated; policy replaced by Part 02 |
| [Method 02 — Part 02](method-02/part-02.md) | Require USB **and** password in GDM while preserving TTY recovery | Validated on the laptop, including physical tests and reboot |

Previous documents preserve project history. Do not reapply the unlock rules from Method 1 or the global USB profile from Part 01 over the final configuration.

## Environment

| Item | Recorded Environment |
| --- | --- |
| Laptop | Lenovo IdeaPad 3i |
| Primary OS | Debian GNU/Linux 13 (trixie), installed directly on the SSD |
| Desktop / login | GNOME / GDM; Wayland session recorded in Method 1 |
| Registered user | `henrique` |
| USB flash drive | SanDisk Cruzer Blade 4 GB nominal; 3.7 GB reported by the system |
| USB identifiers | `0781:5567`; serial `4C530101421215115090` |
| USB volume | FAT, UUID `9EE3-C03C` |
| USB authentication | pam_usb 0.9.3 |

The project started in a Debian VM on VirtualBox. The available guides for Method 1 and Part 01 also record later tests; Part 02 was applied to the primary system. Each recorded environment should be respected when reproducing the steps. `/dev/sda1` was the observed device node for the flash drive, not a permanent address.

## Final Behavior

| Action | Validated / Configured Result |
| --- | --- |
| Graphical login and unlock via GDM | Requires registered USB + correct password |
| Correct password without USB | Graphical authentication rejected |
| USB present with incorrect password | Graphical authentication rejected |
| Removing USB during session | udev rule requests session lock from GNOME |
| Reconnecting USB | Session remains locked; manual authentication is required |
| TTY terminal login | Uses password only, without requiring USB |
| Administration via sudo | Uses system password policy; USB is not required by this configuration |
| System reboot | Configuration persisted across tests confirmed by the user |

The USB requirement was placed in `/etc/pam.d/gdm-password`, right before `@include common-auth`. The `libpam-usb` profile was disabled in `pam-auth-update`, removing USB from shared authentication. TTY and sudo PAM services were not modified.

## Role of Each Mechanism

- **udev + Bash + loginctl:** detects removal and requests locking an existing session. It does not authenticate the user.
- **PAM + pam_usb + pam_unix:** validates the USB flash drive and password within the `gdm-password` service.
- **TTY + sudo:** allows recovering administrative access and temporarily disabling the USB requirement in GDM.

The Method 1 script still accepts `unlock`, though no active connection rule invokes it in the final setup. No running `pamusb-agent` instance was found during inspection.

## Scope and Limitations

The USB flash drive acts as a possession factor and the password acts as a knowledge factor. A standard storage device does not provide the same key-protection guarantees as a FIDO2/U2F hardware token. Pads are verifiable secret files, and USB identification also relies on device-reported properties.

This configuration protects the tested graphical login flow. It does not encrypt the SSD, lock the boot process, or require USB for all system services. Anyone with the password and sudo privileges can recover access via TTY; this is an explicit design decision of the project.

Other users, automatic login, fingerprint authentication, SSH, and other PAM services were not validated at this stage. Modifying `gdm-password` may affect other users relying on that service; this guide covers the registered account `henrique`.

Remove the USB drive only after writes finish and the volume is unmounted. `pam_usb` may renew pads during authentication, so filesystem integrity is part of the project's proper operation.

## Quick Recovery

Switch to a TTY using **Ctrl + Alt + F3** (on the IdeaPad, **Ctrl + Alt + Fn + F3** may be required), log in as `henrique`, and run:

```bash
sudo nano /etc/pam.d/gdm-password
```

Comment out only this line:

```text
# auth required pam_usb.so
```

Save the file, return to the graphical interface, and start a new authentication attempt. GDM will accept the password without the USB drive again. Restarting GDM is not required. The [Part 02 guide](method-02/part-02.md#9-recover-access-without-the-usb-stick) covers recovery and backup restoration. See also [temporarily disabling both USB mechanisms](DISABLE_USB_TOKEN.md).

## Actual Structure

* `README.md`: overview and final state.
* `method-01/README.md`: session control history.
* `method-01/images/`: existing screenshots from Method 1.
* `method-02/part-01.md`: USB-or-password history.
* `method-02/part-02.md`: USB + password implementation and recovery.
* `method-02/images/`: existing screenshots from Part 01.
* `DOCUMENTATION_REVIEW.md`: historical review record.
* `DISABLE_USB_TOKEN.md`: reversible USB authentication and session-lock disablement.
* `LICENSE`: existing repository license.

## Interactive Tools

The [helper scripts](scripts/README.md) provide diagnostics, backup, guided tests, and recovery. To open the menu from the repository root:

```bash
bash scripts/menu.sh
```

The menu prompts for `sudo` on administrative options. Recovery requires confirmation and creates a backup before commenting out the GDM USB rule. The scripts are not an automated installer; the udev rules and lock script remain documented in the guides.

The `scripts/` directory contains the tools, and `tests/` contains checks executed on temporary files without altering the live PAM configuration.

## Technical References

* [pam_usb, version used](https://github.com/mcdope/pam_usb/tree/0.9.3)
* [PAM: syntax and controls on Debian 13](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
* [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
* [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
* [udev](https://manpages.debian.org/trixie/udev/udev.7.en.html)

Authentication and reboot tests were performed and confirmed by the user on the laptop. This documentation revision does not perform remote changes on the machine.

## Working language in this fork

English is the canonical language for code, filenames, helper output and technical documentation. A separate Brazilian Portuguese translation may be added in the future; the original historical documents remain available through Git history. Pull request titles and descriptions may use Brazilian Portuguese for easier maintainer review.

Project helper files may be renamed, but Linux system interfaces such as `gdm-password`, `pam_usb.so`, `/etc/pam.d/common-auth` and `/etc/udev/rules.d/80-usb.rules` retain their real names. The educational GDM/TTY architecture is unchanged.
