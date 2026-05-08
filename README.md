# Bouncing DVD Screensaver

The classic bouncing DVD logo screensaver for macOS. The logo bounces around the screen and changes color every time it hits an edge.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)

## Features

- Authentic DVD logo bouncing off screen edges
- Color changes on every edge hit
- 60fps smooth animation with delta-time interpolation
- Configurable logo size (0.5x–3.0x) and speed (0.5x–4.0x) via System Settings
- Settings persist across sessions
- Scales properly in preview thumbnails

## Requirements

- macOS 14.0+
- Xcode Command Line Tools (`xcode-select --install`)

## Build & Install

```bash
git clone <repo-url> && cd BouncingDVD
./build.sh
sudo cp -R build/BouncingDVD.saver /Library/Screen\ Savers/
```

Then open **System Settings → Screen Saver** and select **Bouncing DVD**.

## Configure

Click the **Options** button in Screen Saver settings to adjust:

| Option | Range | Default |
|--------|-------|---------|
| Logo Size | 0.5x – 3.0x | 1.0x |
| Speed | 0.5x – 4.0x | 1.0x |

## Uninstall

```bash
sudo rm -rf /Library/Screen\ Savers/BouncingDVD.saver
defaults delete com.kshitijsubedi.BouncingDVD
```

## Project Structure

```
BouncingDVD/
├── BouncingDVDView.swift   # ScreenSaverView subclass
├── DVD_logo.png            # DVD logo (transparent background)
├── Info.plist              # Bundle metadata
├── build.sh                # Build + ad-hoc codesign script
└── README.md
```

## License

MIT
