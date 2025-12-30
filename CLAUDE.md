# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app (from project root)
xcodebuild clean build analyze -scheme Slideshow
```
or
```bash
# Build with prettier output (if xcpretty is installed)
xcodebuild clean build analyze -scheme Slideshow | xcpretty && exit ${PIPESTATUS[0]}
```

The project can also be opened and built in Xcode directly.

## Project Overview

Slideshow is a minimal macOS SwiftUI app that displays images from a selected folder as a full-screen slideshow. The app requires macOS 14.0+ and uses Swift 5.

### Architecture

- **SlideshowApp.swift**: App entry point with `@main`. Contains an `AppDelegate` that disables window tabbing (for multi-screen full-screen support) and handles window lifecycle.
- **SlideshowState.swift**: `@Observable` class holding slideshow state:
  - Image list, current index, current folder URL
  - Image loading (supports jpg, jpeg, png, gif, bmp, tiff, heic, webp)
  - `navigate(_:)` method for `.previous`/`.next` navigation
  - Window title with folder name and image index (e.g., "Photos [3/10]")
- **ContentView.swift**: SwiftUI view that binds to `SlideshowState` and renders the UI using `AsyncImage`. Handles key presses (arrows/space/delete for navigation, Cmd+Return for folder selection, Esc to close window), folder selection via `NSOpenPanel`, and sets window title via `navigationTitle` and proxy icon via `navigationDocument`.

### Key Implementation Details

- Images are sorted by filename using `localizedStandardCompare`
- Navigation wraps around (last image → first, first → last)
- Uses NSViewProxy package for window access (full-screen toggle)
- Window tabbing is disabled to allow separate full-screen spaces per window

## Testing

```bash
# Run tests
xcodebuild test -scheme Slideshow -destination 'platform=macOS'
```

Tests are in `SlideshowTests/StateTests.swift` using Swift Testing framework (`@Test`, `#expect`) and cover navigation, image loading, display content, and window title.

CI runs both build and tests on push/PR to main (see `.github/workflows/xcodebuild.yml`).
