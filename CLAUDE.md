# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app (from project root)
xcodebuild clean build analyze
```
or
```bash
# Build with prettier output (if xcpretty is installed)
xcodebuild clean build analyze | xcpretty && exit ${PIPESTATUS[0]}
```

The project can also be opened and built in Xcode directly.

## Project Overview

Slideshow is a minimal macOS SwiftUI app that displays images from a selected folder as a full-screen slideshow. The app requires macOS 14.0+ and uses Swift 5.

### Architecture

- **SlideshowApp.swift**: App entry point with `@main`. Contains an `AppDelegate` that forces full-screen mode on launch and handles window lifecycle.
- **Controller.swift**: `@Observable` class holding all slideshow state and logic:
  - Image list, current index, folder selection state
  - Key press handling and navigation (arrows/space/delete for navigation, Cmd+Return for folder selection, Esc to quit)
  - Folder selection via `NSOpenPanel` and image loading (supports jpg, jpeg, png, gif, bmp, tiff, heic, webp)
- **ContentView.swift**: SwiftUI view that binds to `Controller` and renders the UI using `AsyncImage`.

### Key Implementation Details

- Images are sorted by filename using `localizedStandardCompare`
- Navigation wraps around (last image → first, first → last)
- No external dependencies; pure SwiftUI + AppKit integration

## Testing

```bash
# Run tests
xcodebuild test -scheme Slideshow -destination 'platform=macOS'
```

Tests are in `SlideshowTests/ControllerTests.swift` and cover key handling, navigation, and image loading.

CI runs both build and tests on push/PR to main (see `.github/workflows/xcodebuild.yml`).
