// SPDX-License-Identifier: MIT

import Foundation
@testable import Slideshow

final class InMemoryFileSystemProvider: FileSystemProvider {
    private let files: [URL]?
    private let folderContents: [URL: [URL]]?

    // Mode 1: Always return the same files regardless of directory
    init(_ files: [URL]) {
        self.files = files
        self.folderContents = nil
    }

    // Mode 2: Return files based on the requested directory URL
    init(folders: [URL: [URL]]) {
        self.files = nil
        self.folderContents = folders
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        if let files = files {
            return files
        }
        if let contents = folderContents?[url] {
            return contents
        }
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError, userInfo: nil)
    }
}
