# systemd-manager

Linux desktop app for managing systemd units, browsing journal logs, and inspecting boot performance. Built with Flutter/Dart using Ubuntu's Yaru theme.

## What it does

- Switch between `system` and `user` modes
- List units with search and filters (state and type)
- Run unit actions: start, stop, restart, enable, disable, reset failed, daemon reload
- Open unit details with status, dependencies, unit file content, and unit logs
- Browse `journalctl` logs with search, priority, boot, and unit filters
- Analyze boot timing (`time`, `blame`, `critical-chain`)

## Installation

### Build and Install as Snap (recommended)

```bash
snapcraft pack
sudo snap install --dangerous --classic systemd-manager_1.0.0_amd64.snap
```

### From Source

#### Development

```bash
flutter pub get
flutter run
```

#### Release Build

```bash
flutter pub get
flutter build linux
```

The built app will be located in `build/linux/x64/release/bundle/`. You can run it directly with:

```bash
./build/linux/x64/release/bundle/systemd-manager
```

## Runtime requirements

- Linux desktop running systemd
- D-Bus access to `org.freedesktop.systemd1` for unit management
- `journalctl` available for log queries
- `systemd-analyze` available for boot analysis

## Screenshots

| Feature | Preview |
|------|------|
| Overview | ![Overview](https://raw.githubusercontent.com/nooreldeensalah/systemd-manager/main/images/overview.jpg) |
| Units | ![Units](https://raw.githubusercontent.com/nooreldeensalah/systemd-manager/main/images/units.jpg) |
| Journal | ![Journal](https://raw.githubusercontent.com/nooreldeensalah/systemd-manager/main/images/journal.jpg) |
| Analyze | ![Analyze](https://raw.githubusercontent.com/nooreldeensalah/systemd-manager/main/images/analysis.jpg) |

## License

GPL-3.0
