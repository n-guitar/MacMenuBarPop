# MacMenuBarPop

[日本語 READMEはこちら](README.ja.md)

MacMenuBarPop is a macOS menu bar utility that lists right-side menu bar icons
via Accessibility and lets you trigger their actions even when they are hidden
by a notch or overflow.

![Screenshot](docs/images/screenshot.png)

## Features
- Status item in the menu bar.
- Popover list of right-side menu bar items (third-party first).
- Click a list item to perform the same action as clicking the menu bar icon.
- Start at Login toggle and Quit button.

## Requirements
- macOS 13 or later
- Accessibility permission for this app

## Permissions
This app uses the Accessibility API to read the system UI tree and invoke
AXPress on menu bar items. If permission is missing, the app will explain how
to enable it.

## Build and Run (SwiftPM)
```sh
swift run
```

## Package as .app
```sh
./scripts/package_app.sh
```
Output: `build/MacMenuBarPop.app`

## Start at Login Notes
Start at Login uses `SMAppService`. Unsigned apps may fail to register on some
systems. If it does not toggle, build and sign the app bundle.

## Troubleshooting
- If the list is empty, ensure Accessibility permission is granted for the app.
- For debug output, run with `AX_DEBUG=1 swift run`.
