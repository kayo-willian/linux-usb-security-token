# Method 02 — Part 01: USB or password with pam_usb

> **Historical configuration.** This experiment was validated and later
> replaced by [Part 02 — USB **and** password](part-02.md).
> Do not re-enable its system-wide USB profile over the final policy.

## Environment and evidence

The project began in a Debian VM and was subsequently exercised on
Debian 13 installed directly on the SSD of a Lenovo IdeaPad 3i.
This stage records the earlier configuration in which the flash drive
could act as an alternative to a traditional password.

Existing screenshots were retained at their original relative location.
No new screenshots or repeat tests of this historical stage were claimed
during the documentation review.

## Goal and expected result

This stage treated possession of the configured USB drive as one possible
authentication method, while leaving the normal account password as an
alternative:

- **USB connected:** authenticate without entering the password.
- **USB absent:** authenticate with the password as usual.

The USB device was **not mandatory** in this stage. The subsequent
[Part 02](part-02.md) changes the policy to require **both** the USB
device and the password for the tested GDM flow.
