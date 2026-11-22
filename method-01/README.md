# Method 01 — USB-based graphical session control

This historical method explores locking and requesting the unlock of a
graphical session on Debian 13 using \`udev\`, Bash and \`loginctl\`.

**Recorded status:** validated on Debian installed on the physical SSD,
including a reboot test. The final **Method 02 — Part 02** setup **disables
the USB connection rule that requested automatic unlock**. Only removal-
triggered locking is kept. Do not re-enable the old automatic unlock rule
on top of the final USB + password configuration.

Used alone, Method 01 controls an existing session. It does **not**
authenticate a first login or make the USB mandatory: a password can
still be used for login or manual unlock.

## Recorded environment

| Item | Environment |
| --- | --- |
| System | Debian GNU/Linux 13 (Trixie), installed directly on the SSD |
| Desktop and session | GNOME, Wayland |
| Login manager | GDM |
| Registered account | \`henrique\` |
| USB flash drive | SanDisk Cruzer Blade |
| USB vendor/product identifiers | \`0781:5567\` |
| Reported USB serial | \`4C530101421215115090\` |

## Behavior of the historical experiment

| Event | Historical expected behavior |
| --- | --- |
| Registered USB removed | Lock the graphical session of \`henrique\` |
| Registered USB connected | Request an unlock (historical only; disabled in final setup) |
| Boot without USB | Traditional password login remains available |

The udev rule detects a USB event and invokes a root-owned script that
locates the user's graphical session and calls \`loginctl\`. The desktop
must honor the lock/unlock request; it is not a standalone login policy.

**Current project behavior:** the connection/unlock rule is disabled;
the removal/lock rule remains active. The actual USB + password
authentication policy is documented in
[Method 02 — Part 02](../method-02/part-02.md).

Historical screenshots remain in [images](images/). The files are
preserved as original visual evidence. Their existence does not establish
new tests beyond those reported in the original project.
