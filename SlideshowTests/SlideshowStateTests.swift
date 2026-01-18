// SPDX-License-Identifier: MIT

import Testing
import SwiftUI
@testable import Slideshow

@Suite("State Tests")
final class SlideshowStateTests {
    // Helper to create mock file URLs
    func mockFiles(_ names: [String]) -> [URL] {
        names.map { URL(fileURLWithPath: "/mock/\($0)") }
    }

    // Helper to provide a folder URL that satisfies internal assertions (exists on disk)
    var dummyFolder: URL {
        FileManager.default.temporaryDirectory
    }

    // MARK: - Navigation Tests

    @Test("Navigate next increments index")
    func navigateNextIncrementsIndex() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.currentIndex == 0)

        state.navigate(.next)
        #expect(state.currentIndex == 1)
    }

    @Test("Navigate previous decrements index")
    func navigatePreviousDecrementsIndex() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        state.navigate(.next)
        state.navigate(.next)
        #expect(state.currentIndex == 2)

        state.navigate(.previous)
        #expect(state.currentIndex == 1)
    }

    @Test("Navigate next wraps from last to first")
    func navigateNextWrapsToFirst() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        state.navigate(.next)
        state.navigate(.next)
        #expect(state.currentIndex == 2)

        state.navigate(.next)
        #expect(state.currentIndex == 0)
    }

    @Test("Navigate previous wraps from first to last")
    func navigatePreviousWrapsToLast() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.currentIndex == 0)

        state.navigate(.previous)
        #expect(state.currentIndex == 2)
    }

    @Test("Navigate with empty images does nothing")
    func navigateEmptyImagesDoesNothing() {
        let state = SlideshowState(fs: InMemoryFileSystemProvider([]))
        #expect(state.currentIndex == 0)

        state.navigate(.next)
        #expect(state.currentIndex == 0)

        state.navigate(.previous)
        #expect(state.currentIndex == 0)
    }

    // MARK: - Load Images Tests

    @Test("Load images populates imageFiles array")
    func loadImagesPopulatesArray() async throws {
        let files = mockFiles(["1.jpg", "2.jpg", "3.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.images.count == 3)
        #expect(state.currentIndex == 0)
        #expect(state.lastError == nil)
    }

    @Test("Load images sorts by filename")
    func loadImagesSortsByFilename() async throws {
        let files = mockFiles(["c.jpg", "a.jpg", "b.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.images.count == 3)
        #expect(state.images[0].lastPathComponent == "a.jpg")
        #expect(state.images[1].lastPathComponent == "b.jpg")
        #expect(state.images[2].lastPathComponent == "c.jpg")
    }

    @Test("Load images filters by extension")
    func loadImagesFiltersByExtension() async throws {
        let files = mockFiles(["image.jpg", "doc.txt", "photo.png"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.images.count == 2)
    }

    @Test("Current image returns nil when empty")
    func currentImageNilWhenEmpty() {
        let state = SlideshowState(fs: InMemoryFileSystemProvider([]))
        #expect(state.currentImage == nil)
    }

    @Test("Current image returns correct URL")
    func currentImageReturnsCorrectURL() async throws {
        let files = mockFiles(["a.jpg", "b.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.currentImage?.lastPathComponent == "a.jpg")

        state.navigate(.next)
        #expect(state.currentImage?.lastPathComponent == "b.jpg")
    }

    // MARK: - Display Content Tests

    @Test("Display content shows prompt when no folder selected")
    func displayContentShowsPrompt() {
        let state = SlideshowState(fs: InMemoryFileSystemProvider([]))
        #expect(state.displayContent == .noFolder)
    }

    @Test("Display content shows image URL when folder has images")
    func displayContentShowsImage() async throws {
        let files = mockFiles(["image0.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "image0.jpg")
        } else {
            Issue.record("Expected image, got message")
        }
    }

    @Test("Display content shows message when folder is empty")
    func displayContentShowsEmptyMessage() async throws {
        let state = SlideshowState(fs: InMemoryFileSystemProvider([]))

        await state.loadFolder(dummyFolder)
        #expect(state.displayContent == .emptyFolder)
    }

    @Test("Display content updates after navigation")
    func displayContentUpdatesAfterNavigation() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)

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
    func displayContentShowsFirstImageAfterReload() async throws {
        let dir1 = URL(fileURLWithPath: "/mock/dir1")
        let dir2 = URL(fileURLWithPath: "/mock/dir2")

        let fs = InMemoryFileSystemProvider(folders: [
            dir1: mockFiles(["x.jpg", "y.jpg"]),
            dir2: mockFiles(["p.jpg", "q.jpg"])
        ])

        let state = SlideshowState(fs: fs)

        await state.loadFolder(dir1)
        state.navigate(.next)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "y.jpg")
        }

        await state.loadFolder(dir2)
        if case .image(let url) = state.displayContent {
            #expect(url.lastPathComponent == "p.jpg")
        } else {
            Issue.record("Expected first image of new folder")
        }
    }

    // MARK: - Window Title Tests

    @Test("Window title is bundle name when no folder selected")
    func windowTitleDefaultWhenNoFolder() {
        let state = SlideshowState(fs: InMemoryFileSystemProvider([]))
        #expect(state.windowTitle == "Slideshow")
    }

    @Test("Window title shows folder name and index when images loaded")
    func windowTitleShowsFolderAndIndex() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.windowTitle.hasSuffix("[1/3]"))
        #expect(state.windowTitle.hasPrefix(dummyFolder.lastPathComponent))
    }

    @Test("Window title updates after navigation")
    func windowTitleUpdatesAfterNavigation() async throws {
        let files = mockFiles(["a.jpg", "b.jpg", "c.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.windowTitle.contains("[1/3]"))

        state.navigate(.next)
        #expect(state.windowTitle.contains("[2/3]"))

        state.navigate(.next)
        #expect(state.windowTitle.contains("[3/3]"))
    }

    @Test("Window title shows only folder name when no images")
    func windowTitleShowsFolderWhenEmpty() async throws {
        let state = SlideshowState(fs: InMemoryFileSystemProvider([]))

        await state.loadFolder(dummyFolder)
        #expect(state.windowTitle == dummyFolder.lastPathComponent)
    }

    // MARK: - Edge Cases

    @Test("Single image navigation stays at 0")
    func singleImageNavigationStaysAtZero() async throws {
        let files = mockFiles(["a.jpg"])
        let state = SlideshowState(fs: InMemoryFileSystemProvider(files))

        await state.loadFolder(dummyFolder)
        #expect(state.currentIndex == 0)
        state.navigate(.next)
        #expect(state.currentIndex == 0)
        state.navigate(.previous)
        #expect(state.currentIndex == 0)
    }
}
