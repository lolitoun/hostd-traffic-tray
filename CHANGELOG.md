# Changelog

All notable changes to hostd-traffic-tray. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR.MINOR.PATCH (breaking change . new feature . bug fix).

## v1.1.0 - 2026-11-13

### Added
- **Period choice** (suggested by larsfloe): right-click → *Period* → *Today (00:00 - 23:59)* (default) /
  *Last 24 hours* / *Last hour*. `$Period` sets the one used at startup. The tooltip shows the period.
- Version number at the top of the right-click menu.
- `$Api` can point to another host (e.g. a Docker container); the README explains the plain-HTTP trade-off.
- French README in its own file: `README.fr.md`.

### Changed
- **Bigger text in the tray icons**: the digits now fill the icon.
- **Plainer launcher** (after a report from NickJH): the `.bat` no longer uses `conhost.exe --headless`.
  PowerShell starts minimized and the script hides its own console window (`-HideConsole`), which
  antivirus products are less likely to flag as malware.
- Tooltips: `Sent today` / `Sent (last 24 h)` / `Sent (last hour)`.
- **Script in English only**, with a short header (the details are in the READMEs). Settings renamed:
  `$api` → `$Api`, `$intervalle` → `$Interval`, `$Langue` → `$Language`; the test switch `-TestRendu`
  → `-TestRender`. The French UI (`$Language = 'fr'`) is unchanged.
- README: two ways to start, **right-click → Run with PowerShell** (no `.bat` needed, with help when
  the menu entry is missing) or the `.bat`.

### Docs
- README: new *Known limitations* items about antivirus quarantine (0-byte, undeletable files) and
  Windows Terminal; the script never writes, deletes or locks files.

## v1.0.0 - 2026-11-13

First release: today's hostd traffic (since midnight) as two tray icons.
