import Testing
import SwiftUI
@testable import Slideshow

@Suite("Controller Tests")
struct ControllerTests {

    // MARK: - Key Handling Tests

    @Test("Left arrow navigates to previous")
    func leftArrowNavigatesPrevious() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 3)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        controller.navigate(.next)
        #expect(controller.currentIndex == 1)

        let handled = controller.handleKeyPress(key: .leftArrow, modifiers: [])
        #expect(handled == true)
        #expect(controller.currentIndex == 0)
    }

    @Test("Right arrow navigates to next")
    func rightArrowNavigatesNext() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 3)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.currentIndex == 0)

        let handled = controller.handleKeyPress(key: .rightArrow, modifiers: [])
        #expect(handled == true)
        #expect(controller.currentIndex == 1)
    }

    @Test("Unknown key is not handled")
    func unknownKeyNotHandled() {
        let controller = Controller()
        let handled = controller.handleKeyPress(key: "a", modifiers: [])
        #expect(handled == false)
    }

    // MARK: - Navigation Tests

    @Test("Navigate next increments index")
    func navigateNextIncrementsIndex() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 5)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.currentIndex == 0)

        controller.navigate(.next)
        #expect(controller.currentIndex == 1)
    }

    @Test("Navigate previous decrements index")
    func navigatePreviousDecrementsIndex() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 5)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        controller.navigate(.next)
        controller.navigate(.next)
        #expect(controller.currentIndex == 2)

        controller.navigate(.previous)
        #expect(controller.currentIndex == 1)
    }

    @Test("Navigate next wraps from last to first")
    func navigateNextWrapsToFirst() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 3)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        controller.navigate(.next)
        controller.navigate(.next)
        #expect(controller.currentIndex == 2)

        controller.navigate(.next)
        #expect(controller.currentIndex == 0)
    }

    @Test("Navigate previous wraps from first to last")
    func navigatePreviousWrapsToLast() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 5)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.currentIndex == 0)

        controller.navigate(.previous)
        #expect(controller.currentIndex == 4)
    }

    @Test("Navigate with empty images does nothing")
    func navigateEmptyImagesDoesNothing() {
        let controller = Controller()
        #expect(controller.currentIndex == 0)

        controller.navigate(.next)
        #expect(controller.currentIndex == 0)

        controller.navigate(.previous)
        #expect(controller.currentIndex == 0)
    }

    // MARK: - Load Images Tests

    @Test("Load images populates imageFiles array")
    func loadImagesPopulatesArray() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 3)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.imageFiles.count == 3)
        #expect(controller.currentIndex == 0)
        #expect(controller.lastError == nil)
    }

    @Test("Load images sorts by filename")
    func loadImagesSortsByFilename() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(names: ["c.jpg", "a.jpg", "b.jpg"])
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.imageFiles.count == 3)
        #expect(controller.imageFiles[0].lastPathComponent == "a.jpg")
        #expect(controller.imageFiles[1].lastPathComponent == "b.jpg")
        #expect(controller.imageFiles[2].lastPathComponent == "c.jpg")
    }

    @Test("Load images filters by extension")
    func loadImagesFiltersByExtension() throws {
        let controller = Controller()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try Data().write(to: tempDir.appendingPathComponent("image.jpg"))
        try Data().write(to: tempDir.appendingPathComponent("document.txt"))
        try Data().write(to: tempDir.appendingPathComponent("photo.png"))

        controller.loadImages(from: tempDir)
        #expect(controller.imageFiles.count == 2)
    }

    @Test("Current image returns nil when empty")
    func currentImageNilWhenEmpty() {
        let controller = Controller()
        #expect(controller.currentImage == nil)
    }

    @Test("Current image returns correct URL")
    func currentImageReturnsCorrectURL() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(names: ["a.jpg", "b.jpg"])
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.currentImage?.lastPathComponent == "a.jpg")

        controller.navigate(.next)
        #expect(controller.currentImage?.lastPathComponent == "b.jpg")
    }

    // MARK: - Display Content Tests

    @Test("Display content shows prompt when no folder selected")
    func displayContentShowsPrompt() {
        let controller = Controller()
        if case .message(let text) = controller.displayContent {
            #expect(text.contains("open a folder"))
        } else {
            Issue.record("Expected message, got image")
        }
    }

    @Test("Display content shows image URL when folder has images")
    func displayContentShowsImage() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "image0.jpg")
        } else {
            Issue.record("Expected image, got message")
        }
    }

    @Test("Display content shows message when folder is empty")
    func displayContentShowsEmptyMessage() throws {
        let controller = Controller()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        if case .message(let text) = controller.displayContent {
            #expect(text.contains("No images"))
        } else {
            Issue.record("Expected message, got image")
        }
    }

    @Test("Display content updates after navigation")
    func displayContentUpdatesAfterNavigation() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(names: ["a.jpg", "b.jpg", "c.jpg"])
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)

        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "a.jpg")
        } else {
            Issue.record("Expected image")
        }

        controller.navigate(.next)
        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "b.jpg")
        } else {
            Issue.record("Expected image")
        }

        controller.navigate(.next)
        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "c.jpg")
        } else {
            Issue.record("Expected image")
        }

        controller.navigate(.next)
        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "a.jpg")
        } else {
            Issue.record("Expected image after wrap")
        }
    }

    @Test("Display content shows first image after loading new folder")
    func displayContentShowsFirstImageAfterReload() throws {
        let controller = Controller()
        let tempDir1 = try createTempDirectoryWithImages(names: ["x.jpg", "y.jpg"])
        let tempDir2 = try createTempDirectoryWithImages(names: ["p.jpg", "q.jpg"])
        defer {
            try? FileManager.default.removeItem(at: tempDir1)
            try? FileManager.default.removeItem(at: tempDir2)
        }

        controller.loadImages(from: tempDir1)
        controller.navigate(.next)
        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "y.jpg")
        }

        controller.loadImages(from: tempDir2)
        if case .image(let url) = controller.displayContent {
            #expect(url.lastPathComponent == "p.jpg")
        } else {
            Issue.record("Expected first image of new folder")
        }
    }

    // MARK: - Unit Test Detection

    @Test("inUnitTest returns true when running tests")
    func inUnitTestReturnsTrue() {
        let controller = Controller()
        #expect(controller.inUnitTest == true)
    }

    // MARK: - Edge Cases

    @Test("Single image navigation stays at 0")
    func singleImageNavigationStaysAtZero() throws {
        let controller = Controller()
        let tempDir = try createTempDirectoryWithImages(count: 1)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        controller.loadImages(from: tempDir)
        #expect(controller.currentIndex == 0)

        controller.navigate(.next)
        #expect(controller.currentIndex == 0)

        controller.navigate(.previous)
        #expect(controller.currentIndex == 0)
    }

    // MARK: - Helpers

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
}
