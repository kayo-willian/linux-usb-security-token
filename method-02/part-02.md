# Method 02 — Part 02: USB + password in GDM

[Português (Brasil)](part-02.pt-BR.md) · [Project overview](../README.md)

Device serials and volume UUIDs are represented by placeholders in the examples.

**Recorded status:** Applied to Debian 13 on a Lenovo IdeaPad 3i and validated by the original maintainer, including a new login after reboot. This English-language adaptation of the historical guide does **not** represent new physical testing.

[Overview](../README.md) · [Part 01 (historical)](part-01.md) · [Method 01](../method-01/README.md) · [Temporarily disable USB protection](../DISABLE_USB_TOKEN.md)

## 1. Goal and scope

Replace the earlier **USB or password** policy from Part 01 with **USB and password** for graphical login and unlock through the `gdm-password` PAM service.

Two independent mechanisms make up the recorded setup:

- **Method 01, partially active:** USB removal requests a GNOME session lock. The rule that requested automatic unlock when the USB was reinserted is **disabled**.
- **Method 02 — Part 02:** `gdm-password` requires both a recognized USB token (`pam_usb`) and the account password (`pam_unix` through `common-auth`).

TTY login and `sudo` continue using the system password. This is the intended recovery route if the flash drive is lost or damaged. The policy does **not** apply globally to all PAM services, boot, or the SSD.

## 2. Recorded environment

| Item | Recorded value |
| --- | --- |
| Computer | Lenovo IdeaPad 3i |
| OS | Debian GNU/Linux 13 (Trixie), installed on physical SSD |
| Display/login | GNOME with GDM |
| Registered user | `henrique` |
| USB drive | SanDisk Cruzer Blade, nominal 4 GB |
| Reported serial | `EXAMPLE_USB_SERIAL` |
| USB volume | FAT, UUID `EXAMPLE_VOLUME_UUID`; observed as `/dev/sda1` |
| SSD | `nvme0n1`, approximately 238.5 GB; ext4 root |
| pam_usb | Version 0.9.3, previously installed in Part 01 |

The project began in a VM. **This stage was carried out on the primary physical Debian installation**, after replacing Windows 11. Device paths, session IDs and mount points may differ on another machine; do not copy an observed device node as a permanent identifier.

### Configuration before Part 02

The original `/etc/pam.d/common-auth` included:

```text
auth sufficient pam_usb.so
auth [success=1 default=ignore] pam_unix.so nullok try_first_pass
```

The `/usr/share/pam-configs/libpam-usb` profile used `sufficient pam_usb.so` for both `Auth` and `Auth-Initial`. The `/etc/udev/rules.d/80-usb.rules` file still invoked `usb-lock.sh unlock` on USB connection.

Making the USB mandatory **without disabling automatic unlock** would leave a way to unlock the graphical session without a password. The final setup therefore disables the connection/unlock rule and moves the USB requirement to the **GDM-specific PAM service**.

## 3. Prepare a recovery TTY and backup

Before changing authentication, save your work, attach the registered USB device, and access a TTY using **Ctrl + Alt + F3** (or **Ctrl + Alt + Fn + F3** on the documented laptop). Log in with the normal account password and open an administrative shell:

```bash
sudo -i
```

Keep this TTY available throughout the changes. The following historical commands for sections 3–7 are executed **inside the root shell**, so they do not repeat `sudo`.

```bash
backup_usb=$(mktemp -d /root/usb-token-parte02.XXXXXX)
cp -a /etc/pam.d "$backup_usb/"
cp -a /usr/share/pam-configs/libpam-usb "$backup_usb/"
cp -a /etc/udev/rules.d/80-usb.rules "$backup_usb/"
cp -a /usr/local/bin/usb-lock.sh "$backup_usb/"
cp -a /etc/security/pam_usb.conf "$backup_usb/"
printf 'Backup: %s\n' "$backup_usb"
```

**Verify every copy succeeded before continuing.** The original maintainer recorded a backup at `/root/usb-token-parte02.qz3aVC`. On another host, use the **actual path** returned by `mktemp`; do not assume this example directory exists. The `backup_usb` variable exists only in the current shell and does not survive logout or reboot. Backups contain sensitive authentication configuration: keep them private.

### Check the agent and USB registration

The historical diagnostic commands were:

```bash
sed -n '30,115p' /etc/security/pam_usb.conf
pgrep -af '[p]amusb-agent'
```

The correct file is `/etc/security/pam_usb.conf`, not `/etc/pamusb.conf`. The example `scox`/`MyDevice` agent lock/unlock actions were inside XML comments; no live `pamusb-agent` process was found in the recorded inspection.

The original configuration had a duplicate reference to `SanDisk` for `henrique`. The maintainer edited the XML to retain only one device entry:

```xml
<user id="henrique">
    <device>SanDisk</device>
</user>
```

Do **not** overwrite an existing XML file with only this snippet. Preserve the surrounding configuration and check whether active agent actions exist on a different installation. Avoid publishing real pads or secret file contents.

## 4. Disable only udev automatic unlock

The historical procedure for the registered host was:

```bash
sed -i '/^ACTION=="add".*usb-lock\.sh unlock/s/^/# Disabled in Part 02: /' \
  /etc/udev/rules.d/80-usb.rules
udevadm control --reload-rules
cat /etc/udev/rules.d/80-usb.rules
```

The following is the **same rule structure with English explanatory comments**, not a new physical test transcript:

```udev
# Disabled in Part 02: ACTION=="add", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", ENV{ID_SERIAL_SHORT}=="EXAMPLE_USB_SERIAL", RUN+="/usr/local/bin/usb-lock.sh unlock"
ACTION=="remove", SUBSYSTEM=="block", ENV{DEVTYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="0781", ENV{ID_MODEL_ID}=="5567", ENV{ID_SERIAL_SHORT}=="EXAMPLE_USB_SERIAL", RUN+="/usr/local/bin/usb-lock.sh lock"
```

The script remains installed and accepts `lock` and `unlock`, but **only the removal rule** is active in the final setup. Reloading udev rules affects future events; do not use `udevadm trigger` to manufacture system-wide USB events. A different flash drive needs its **own reviewed identifiers**; the values above are historical.

## 5. Remove the USB profile from shared PAM authentication

The recorded root-shell commands were:

```bash
pam-auth-update --disable libpam-usb
cat /etc/pam.d/common-auth
```

If a selection interface appears, keep **Unix authentication** enabled and **USB Authentication** disabled. Do **not** use `--force` to overwrite local customizations without inspecting them.

The relevant active block observed afterwards was:

```text
auth [success=1 default=ignore] pam_unix.so nullok
auth requisite pam_deny.so
auth required pam_permit.so
```

There should be **no active `pam_usb.so`** line in `common-auth`. Do not replace an entire PAM file with the snippet above; other installations may have different modules and comments. The `nullok` option was generated by Debian and was not the subject of a separate policy audit. `pam_permit.so` appears only after prior failure controls; it is not a standalone grant of access.

## 6. Require USB in GDM

Open the GDM PAM service:

```bash
nano /etc/pam.d/gdm-password
```

Insert **one** line immediately before `@include common-auth`:

```text
auth required pam_usb.so
```

The start of the original observed configuration was:

```text
#%PAM-1.0
auth requisite pam_nologin.so
auth required pam_succeed_if.so user != root quiet_success
auth required pam_usb.so
@include common-auth
auth optional pam_gnome_keyring.so
@include common-account
```

Preserve all other PAM lines, especially account, session and password modules. Check the top of the file:

```bash
head -n 8 /etc/pam.d/gdm-password
```

### Why both factors are required

`pam_usb.so` verifies the registered USB and its pads. With the `required` control, failure prevents the **overall** authentication from succeeding, but processing can continue to later modules; a password prompt might still appear when the USB is absent.

`common-auth` performs password verification via `pam_unix.so`. An incorrect password reaches `pam_deny.so`. A correct password does **not** erase an earlier USB failure.

This requirement is confined to the tested `gdm-password` service and registered account. Other users, automatic login, fingerprint methods, SSH, and other PAM services need separate analysis.

## 7. Test authentication from the TTY

```bash
apt update
apt install -y pamtester
pamtester gdm-password henrique authenticate
```

The original maintainer supplied a successful output similar to:

```text
* Authentication request for user "henrique" (gdm-password)
* Searching for "SanDisk" in the hardware database...
* Authentication device "SanDisk" is connected.
* Performing one time pad verification...
* Access granted.
Password:
pamtester: successfully authenticated
```

`Access granted` is the USB verification stage; only `pamtester: successfully authenticated` indicates overall PAM success. At `Password:` enter the **user account** password, not the root password. Input is not echoed.

The tests cover these conditions:

| USB | Password | Expected result |
| --- | --- | --- |
| Connected | Correct | Success |
| Connected | Incorrect | Rejected |
| Absent | Correct | Rejected |

The originally shared `pamtester` logs showed **two successes**, not terminal transcripts of the rejected cases. The **physical rejected logins were reported separately** by the original user; do not misrepresent missing logs as captured evidence.

Before unplugging the drive, finish writes and unmount its volume. Removing the USB may lock the graphical session or blank the screen; run the tests in a TTY so recovery remains available. A screen lock verifies the udev path, **not** that USB-free login was denied.

## 8. Validate in GDM and after reboot

Return to the graphical session **without closing the recovery root TTY**. GDM is often on VT 2, but may use VT 1:

```bash
chvt 2
```

Switching VTs does **not** unlock a session. Reconnecting the registered USB should **not** unlock it automatically either.

The original maintainer reported the following results on **October 1, 2026**:

| Physical test | Reported result |
| --- | --- |
| USB absent, correct password | Graphical access rejected |
| USB present, incorrect password | Access rejected |
| USB present, correct password | Access allowed |
| USB removed during the session | Session locked |
| USB reconnected | Session remained locked |
| New login after logout | Both requirements remained active |
| Reboot and subsequent login | Expected behavior persisted |

The Part 02 tests were **reported by the original user**. No additional Part 02 screenshots were supplied. Earlier Part 01 images document the **previous** USB-or-password policy and cannot be used as evidence of USB-and-password behavior.

Before rebooting, save work and exit the root shell and TTY session normally. Do not leave an unattended administrative session running after testing.

## 9. Recover access without the USB stick

### Enter a separate TTY session

1. Press **Ctrl + Alt + F3**, or **Ctrl + Alt + Fn + F3** on the documented laptop.
2. At the console login prompt, enter the registered account name.
3. Enter the regular account password.

If the shortcut fails, try a different available TTY, such as F4. The TTY does **not** unlock the graphical session, and the recorded configuration does **not** require USB to log into the TTY. Recovery assumes the administrator still has password and `sudo` access.

### Temporarily remove the GDM USB requirement

```bash
sudo nano /etc/pam.d/gdm-password
```

Comment **only** the matching mandatory USB rule:

```text
# auth required pam_usb.so
```

Save and return to GDM, using the correct VT for the computer:

```bash
sudo chvt 2
```

Cancel any previous authentication attempt and start a **new** one. The new attempt should accept the account password without the USB drive, provided no other policy rejects it. **Do not restart GDM** simply to apply this change: restarting GDM would end the graphical session.

This temporarily disables the USB requirement **for GDM only**. It does not disable udev lock-on-removal or modify `common-auth`. The TTY and password-based administration are intentional recovery channels.

The [interactive recovery helper](../scripts/README.md) can perform this narrow GDM-only comment operation after backup and confirmation, if its preconditions match the installed configuration.

### Re-enable the final policy

Once the replacement/registered USB and pads have been checked, remove the comment marker from **one** `auth required pam_usb.so` line immediately before `@include common-auth`. Repeat the positive/negative checks before treating the protection as restored. **Do not re-enable** the obsolete global `libpam-usb` profile from Part 01.

### Full rollback to the *previous* USB-or-password setup

The earlier guide also recorded a **separate, broader rollback** that restores the state captured before Part 02. It re-enables the **historical** USB-or-password model and may restore the original automatic-unlock rule; **it does not restore the final Part 02 policy**.

Only for administrators intentionally returning to that earlier setup, from a recovery root TTY:

```bash
sudo -i
backup_usb=/root/usb-token-parte02.qz3aVC
ls -la "$backup_usb"
```

**Replace the example backup path** with your actual verified backup, and compare its contents with the live files first. If the backup is old, a full copy can overwrite legitimate subsequent PAM changes:

```bash
cp -a "$backup_usb/libpam-usb" /usr/share/pam-configs/libpam-usb
pam-auth-update --enable libpam-usb
cp -a "$backup_usb/pam.d/." /etc/pam.d/
cp -a "$backup_usb/pam_usb.conf" /etc/security/pam_usb.conf
cp -a "$backup_usb/80-usb.rules" /etc/udev/rules.d/80-usb.rules
cp -a "$backup_usb/usb-lock.sh" /usr/local/bin/usb-lock.sh
udevadm control --reload-rules
```

This is **historical rollback documentation**, not a recommended automatic script. The XML backup may restore the duplicate device registration that was corrected in Part 02. Do not perform this broad restore on an unrelated host or without reviewing the differences.

## 10. Troubleshooting and maintenance

| Symptom | What to inspect |
| --- | --- |
| USB succeeds without a password | Check whether shared `common-auth` contains a returned `sufficient pam_usb.so` rule |
| Correct password works in GDM without USB | Verify the mandatory rule is active in the actual `gdm-password` service and no alternative login flow bypasses it |
| USB reconnection unlocks automatically | Inspect udev connection rules and agent actions; `unlock` must remain disabled |
| `Pad checking failed!` | Check device identity, volume UUID/mount, filesystem integrity and pad access; consult the historical Part 01 notes |
| USB removal does not lock | Check the udev removal rule, lock script and graphical session detection |
| TTY works but GDM remains locked | Expected: they are separate sessions; use a new graphical login attempt or the documented recovery |
| GNOME Keyring asks for another password | Check whether the keyring password matches the login password; USB does not decrypt the keyring |

For host-specific diagnosis, inspect `/etc/pam.d/common-auth`, the start of `/etc/pam.d/gdm-password`, and recent journal messages:

```bash
cat /etc/pam.d/common-auth
head -n 8 /etc/pam.d/gdm-password
sudo journalctl -b --no-pager -n 100
```

Package updates or a `pam_usb` reinstall can alter PAM profiles. Repeat the manual checks after major configuration changes. Never publish passwords or USB pad contents; sanitize logs before sharing.

## 11. Security limitations

- USB pad files contain secrets. Do **not** publish `.pad` files or share their contents.
- `pam_usb` pad renewal is not a TOTP code or SSD encryption. See the original Part 01 method.
- Ordinary USB sticks do not protect secret material as dedicated hardware security tokens do. Reported USB serials and filesystem UUIDs are **not cryptographic identity proofs** on their own.
- FAT filesystems can be damaged by unplugging during writes; safely unmount before removal.
- The session lock is **event-triggered** by udev. It is not continuous surveillance for USB absence.
- The documented USB requirement applies to the tested GDM flow. TTY and `sudo` remain password-based for recovery, and administrators can modify policies.
- The project does not encrypt storage or apply USB controls to boot, SSH or every system service.

## Helper tools and references

The optional [menu and helper scripts](../scripts/README.md) provide diagnostics, configuration backups, guided tests and narrow GDM-only recovery:

```bash
bash scripts/menu.sh
```

They do not install the full policy and need not be rerun just to preserve the already-validated setup.

Reference material from the original project:

- [pam_usb 0.9.3](https://github.com/mcdope/pam_usb/tree/0.9.3)
- [Configuration source](https://github.com/mcdope/pam_usb/blob/0.9.3/src/conf.h)
- [USB pad implementation](https://github.com/mcdope/pam_usb/blob/0.9.3/src/pad.c)
- [Debian PAM syntax and controls](https://manpages.debian.org/trixie/libpam-runtime/pam.d.5.en.html)
- [pam-auth-update](https://manpages.debian.org/trixie/libpam-runtime/pam-auth-update.8.en.html)
- [pamtester](https://manpages.debian.org/trixie/pamtester/pamtester.1.en.html)
- [loginctl](https://manpages.debian.org/trixie/systemd/loginctl.1.en.html)
- [chvt](https://manpages.debian.org/trixie/kbd/chvt.1.en.html)
