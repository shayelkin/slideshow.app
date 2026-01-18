# Slideshow

A basic macOS app that displays images in a folder as a full-screen slideshow.

[![CI](https://github.com/shayelkin/slideshow/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/shayelkin/slideshow/actions/workflows/CI.yml)

## Installation

Download the source code, and build using Xcode, or `xcodebuild`.

If you've never built a macOS application before, the following command will
build the app, placing the app package in the `./build/Release/` directory:

```sh
xcodebuild clean build -scheme Slideshow -configuration Release SYMROOT="$(pwd)/build"
```

## In-App Keyboard Shortcuts

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
