Fedora Rawhide for WSL
======================

This project provides a ready-to-use Fedora Rawhide root filesystem packaged as a `.wsl` archive for use with Windows Subsystem for Linux (WSL). It allows you to install and run Fedora Rawhide on Windows without needing the Microsoft Store.

Because Rawhide is Fedora's rolling release, this package never needs a version bump — rebuilding always produces the latest Rawhide snapshot.

The package is designed to help users get started quickly with a minimal, working Fedora environment on WSL 2.
**This release supports systemd** out-of-the-box.

-------------------------------------------------------
How to Get Started
-------------------------------------------------------

1. Download the Fedora Rawhide `.wsl` package:
   - From the GitHub Releases section

2. Install the distro into WSL:

   PowerShell or Windows Terminal from a normal Windows path such as `Downloads` or `C:\WSL`:

   ```
   wsl --install --from-file C:\path\to\Fedora-Rawhide-WSL.wsl
   ```

   You can also install it by double-clicking the `.wsl` file in File Explorer.
   If you want to override the default registration name, use:

   ```
   wsl --install --from-file C:\path\to\Fedora-Rawhide-WSL.wsl --name fedora-rawhide
   ```

   Avoid launching the installer from a `\\wsl.localhost\...` path. WSL may try to inherit that UNC working directory when it auto-launches the new distro after installation, which can produce a harmless `Failed to translate '\\wsl.localhost\...'` warning.

3. Launch Fedora:

   ```
   wsl -d fedora-rawhide
   ```

4. Complete the first-run setup:
   - Enter the username you want to use.
   - Set the password for that account.
   - Fedora will use that account as the default user for later launches.

5. Open VS Code and connect to your Fedora instance through WSL:
   - Install the "Remote - WSL" extension in VS Code.
   - Click on the green >< icon in the lower-left corner and select "Remote-WSL: New Window".
   - From there, you can open the Fedora filesystem and start developing with all the conveniences of VS Code.

6. Verify your WSL version if you still see systemd warnings:

   ```
   wsl --version
   ```

   The `.wsl` package flow requires WSL 2.4.4 or newer. If you still see `Failed to start the systemd user session`, update WSL before troubleshooting the distro further.

-------------------------------------------------------
First-Run User Setup
-------------------------------------------------------

The image uses WSL's supported out-of-box experience (OOBE) flow:

- No fixed non-root user is baked into the image.
- The first launch prompts you to create your own default user.
- The created user gets `sudo` access through the `wheel` group.

### Important Note :
>The legacy `wsl --import` flow bypasses the OOBE experience and can still launch the distro as `root`. Use the `.wsl` installer flow shown above if you want the first-run user creation to work correctly.

-------------------------------------------------------
Plans for Future Improvements
-------------------------------------------------------

- Provide multiple flavor options (minimal, developer-ready, etc.)
- Make installation even easier via a script

-------------------------------------------------------
Transparency and Build Steps
-------------------------------------------------------

This repository also includes the build script used to generate the release artifact:

```bash
./rawhide/build-rawhide.sh
```

The script builds the root filesystem from Fedora Rawhide's rolling repository, applies the WSL overlay, and emits `rawhide/Fedora-Rawhide-WSL.wsl`.

-------------------------------------------------------
License
-------------------------------------------------------

This project is licensed under the MIT License.

Fedora® is a registered trademark of Red Hat, Inc., and is used here in a community capacity for educational and practical purposes. This project is not affiliated with or endorsed by Red Hat.
