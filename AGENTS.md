# AGENTS.md

This file provides guidance to LLM coding agents when working with code in
this repository.

## Project Overview

Slideshow is a minimal macOS SwiftUI app that displays images from a selected
folder as a full-screen slideshow.

## Building

```bash
# Build the app (from project root)
xcodebuild clean build analyze -scheme Slideshow
```

The project can also be opened and built in Xcode directly.

## Testing

```bash
# Run tests
xcodebuild test -scheme Slideshow
```

Tests are in `SlideshowTests`, and use Swift's Testing framework (`@Test`,
`#expect`). They mostly cover business logic, but should aim for as full
coverage as possible.

This project uses GitHub actions for CI, that runs both build and tests on
push/PR to main (see `.github/workflows/xcodebuild.yml`).

## Key Implementation Details

- The minimum supported platform is macOS 14.0 and Swift 5.
- Uses NSViewProxy package to simplify accessing the NSWindow from the SwiftUI
  View.
- Images are sorted by filename using `localizedStandardCompare`.
- Navigation wraps around (last image → first, first → last).
- Window tabbing is disabled to allow separate full-screen spaces per window.
- File system access is abstracted via `FileSystemProvider` protocol, allowing
  tests to use `InMemoryFileSystemProvider` instead of real disk access.
- Folder selection dialogs are abstracted via `OpenPanelProvider` protocol.
- Only one open dialog can be active per window at a time (tracked via
  `isPickingFolder` state).

### Files

- **SlideshowApp.swift**: App entry point with `@main`. Contains an
  `AppDelegate` that disables window tabbing (for multi-screen full-screen
  support) and handles window lifecycle.
- **SlideshowState.swift**: `@Observable` class holding slideshow state:
  - Image list, current index, current folder URL
  - Image loading, supporting the files natively recognized by SwiftUI's
    AsyncImage: jpg, jpeg, png, gif, bmp, tiff, heic, webp.
  - `navigate(_:)` method for `.previous`/`.next` navigation
  - Window title with folder name and image index (e.g., "Photos [3/10]")
  - Takes a `FileSystemProvider` for dependency injection (defaults to
    `RealFileSystemProvider`).
- **ContentView.swift**: SwiftUI view that binds to `SlideshowState` and
  renders the UI using `AsyncImage`. Handles key presses (arrows/space/delete
  for navigation, Cmd+Return for folder selection, Esc to close window),
  folder selection via `OpenPanelProvider`, and sets window title via
  `navigationTitle` and proxy icon via `navigationDocument`.
- **FileSystemProvider.swift**: Protocol abstracting file system access.
  `RealFileSystemProvider` wraps `FileManager` for production use.
- **OpenPanelProvider.swift**: Protocol abstracting folder selection dialogs.
  `RealOpenPanelProvider` wraps `NSOpenPanel` with async/await support.

### Test Files

- **SlideshowStateTests.swift**: Unit tests for `SlideshowState` business logic.
- **InMemoryFileSystemProvider.swift**: Test double implementing
  `FileSystemProvider` with configurable in-memory file listings.
