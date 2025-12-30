import Testing
import SwiftUI
@testable import Slideshow

@Suite("State Tests")
final class StateTests {
    lazy var tempDir: URL = {
        try! createTempDirectoryWithImages(count: 3)
    }()

    deinit {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - Navigation Tests

    @Test("Navigate next increments index")
    func navigateNextIncrementsIndex() throws {
        let state = SlideshowState()

        state.folder = tempDir
        #expect(state.currentIndex == 0)

        state.navigate(.next)
        #expect(state.currentIndex == 1)
    }

    @Test("Navigate previous decrements index")
    func navigatePreviousDecrementsIndex() throws {
        let state = SlideshowState()

        state.folder = tempDir
        state.navigate(.next)
        state.navigate(.next)
        #expect(state.currentIndex == 2)

        state.navigate(.previous)
        #expect(state.currentIndex == 1)
    }

    @Test("Navigate next wraps from last to first")
    func navigateNextWrapsToFirst() throws {
        let state = SlideshowState()

        state.folder = tempDir
        state.navigate(.next)
        state.navigate(.next)
        #expect(state.currentIndex == 2)

        state.navigate(.next)
        #expect(state.currentIndex == 0)
    }

    @Test("Navigate previous wraps from first to last")
    func navigatePreviousWrapsToLast() throws {
        let state = SlideshowState()

        state.folder = tempDir
        #expect(state.currentIndex == 0)

        state.navigate(.previous)
        #expect(state.currentIndex == 2)
    }

    @Test("Navigate with empty images does nothing")
    func navigateEmptyImagesDoesNothing() {
        let state = SlideshowState()
        #expect(state.currentIndex == 0)

        state.navigate(.next)
        #expect(state.currentIndex == 0)

        state.navigate(.previous)
        #expect(state.currentIndex == 0)
    }

    // MARK: - Load Images Tests

    @Test("Load images populates imageFiles array")
    func loadImagesPopulatesArray() throws {
        let state = SlideshowState()

        state.folder = tempDir
        #expect(state.images.count == 3)
        #expect(state.currentIndex == 0)
        #expect(state.lastError == nil)
    }

    @Test("Load images sorts by filename")
    func loadImagesSortsByFilename() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(names: ["c.jpg", "a.jpg", "b.jpg"])
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir
        #expect(state.images.count == 3)
        #expect(state.images[0].lastPathComponent == "a.jpg")
        #expect(state.images[1].lastPathComponent == "b.jpg")
        #expect(state.images[2].lastPathComponent == "c.jpg")
    }

    @Test("Load images filters by extension")
    func loadImagesFiltersByExtension() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(names: ["image.jpg", "doc.txt", "photo.png"])
        defer { try? FileManager.default.removeItem(at: tempDir) }
        state.folder = tempDir
        #expect(state.images.count == 2)
    }

    @Test("Current image returns nil when empty")
    func currentImageNilWhenEmpty() {
        let state = SlideshowState()
        #expect(state.currentImage == nil)
    }

    @Test("Current image returns correct URL")
    func currentImageReturnsCorrectURL() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(names: ["a.jpg", "b.jpg"])
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir
        #expect(state.currentImage?.lastPathComponent == "a.jpg")

        state.navigate(.next)
        #expect(state.currentImage?.lastPathComponent == "b.jpg")
    }

    // MARK: - Display Content Tests

    @Test("Display content shows prompt when no folder selected")
    func displayContentShowsPrompt() {
        let state = SlideshowState()
        if case .message(let text) = state.displayContent {
            #expect(text.contains("open a folder"))
        } else {
            Issue.record("Expected message, got image")
        }
    }

    @Test("Display content shows image URL when folder has images")
    func displayContentShowsImage() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "image0.jpg")
        } else {
            Issue.record("Expected image, got message")
        }
    }

    @Test("Display content shows message when folder is empty")
    func displayContentShowsEmptyMessage() throws {
        let state = SlideshowState()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir
        if case .message(let text) = state.displayContent {
            #expect(text.contains("No images"))
        } else {
            Issue.record("Expected message, got image")
        }
    }

    @Test("Display content updates after navigation")
    func displayContentUpdatesAfterNavigation() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(names: ["a.jpg", "b.jpg", "c.jpg"])
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir

        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "a.jpg")
        } else {
            Issue.record("Expected image")
        }

        state.navigate(.next)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "b.jpg")
        } else {
            Issue.record("Expected image")
        }

        state.navigate(.next)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "c.jpg")
        } else {
            Issue.record("Expected image")
        }

        state.navigate(.next)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "a.jpg")
        } else {
            Issue.record("Expected image after wrap")
        }
    }

    @Test("Display content shows first image after loading new folder")
    func displayContentShowsFirstImageAfterReload() throws {
        let state = SlideshowState()
        let tempDir1 = try createTempDirectoryWithImages(names: ["x.jpg", "y.jpg"])
        let tempDir2 = try createTempDirectoryWithImages(names: ["p.jpg", "q.jpg"])
        defer {
            try? FileManager.default.removeItem(at: tempDir1)
            try? FileManager.default.removeItem(at: tempDir2)
        }

        state.folder = tempDir1
        state.navigate(.next)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "y.jpg")
        }

        state.folder = tempDir2
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "p.jpg")
        } else {
            Issue.record("Expected first image of new folder")
        }
    }

    // MARK: - Window Title Tests

    @Test("Window title is bundle name when no folder selected")
    func windowTitleDefaultWhenNoFolder() {
        let state = SlideshowState()
        #expect(state.windowTitle == "Slideshow")
    }

    @Test("Window title shows folder name and index when images loaded")
    func windowTitleShowsFolderAndIndex() throws {
        let state = SlideshowState()

        state.folder = tempDir
        #expect(state.windowTitle.hasSuffix("[1/3]"))
        #expect(state.windowTitle.hasPrefix(tempDir.lastPathComponent))
    }

    @Test("Window title updates after navigation")
    func windowTitleUpdatesAfterNavigation() throws {
        let state = SlideshowState()

        state.folder = tempDir
        #expect(state.windowTitle.contains("[1/3]"))

        state.navigate(.next)
        #expect(state.windowTitle.contains("[2/3]"))

        state.navigate(.next)
        #expect(state.windowTitle.contains("[3/3]"))
    }

    @Test("Window title shows only folder name when no images")
    func windowTitleShowsFolderWhenEmpty() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(count: 0)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir
        #expect(state.windowTitle == tempDir.lastPathComponent)
    }

    // MARK: - Unit Test Detection

    @Test("inTestCase returns true when running tests")
    func inTestCaseReturnsTrue() {
        let state = SlideshowState()
        #expect(state.inTestCase == true)
    }

    // MARK: - Edge Cases

    @Test("Single image navigation stays at 0")
    func singleImageNavigationStaysAtZero() throws {
        let state = SlideshowState()
        let tempDir = try createTempDirectoryWithImages(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        state.folder = tempDir
        #expect(state.currentIndex == 0)
        state.navigate(.next)
        #expect(state.currentIndex == 0)
        state.navigate(.previous)
        #expect(state.currentIndex == 0)
    }
}

private func createTempDirectoryWithImages(count: Int) throws -> URL {
    let names = (0..<count).map { "image\($0).jpg" }
    return try createTempDirectoryWithImages(names: names)
}

private func createTempDirectoryWithImages(names: [String]) throws -> URL {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    for name in names {
        try Data().write(to: tempDir.appendingPathComponent(name))
    }

    return tempDir
}
