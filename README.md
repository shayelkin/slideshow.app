# Slideshow

A basic macOS app that displays images in a folder as a full-screen slideshow.

[![CI](https://github.com/shayelkin/slideshow/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/shayelkin/slideshow/actions/workflows/CI.yml)

## Installation

Build using Xcode, or `xcodebuild` from the command line.

Not having an Apple Developer Account, I am unable to
[notarize a release for binary distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

If you've never built a macOS application before, the following command will
build the app, placing the app package in the `build/Release/` directory:

```sh
xcodebuild clean build -scheme Slideshow -configuration Release SYMROOT="$(pwd)/build"
```

## Keyboard Shortcuts (In-App)

 Key              | Action
 -----------------|-------------
 ⌘+⏎              | Open folder
 space or → or ↓  | Next photo
 ⌫ or ← or ↑      | Previous photo
 ⎋                | Exit

## AI Notice

Development of this software was assisted by AI models from Anthropic and Google.

## License

This software is made available under the terms of the [MIT license](LICENSE).
