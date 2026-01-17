// SPDX-License-Identifier: MIT

import Foundation

protocol FileSystemProvider: Sendable {
    func contentsOfDirectory(at url: URL) throws -> [URL]
}

struct RealFileSystemProvider: FileSystemProvider {
    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.nameKey], options: [.skipsHiddenFiles])
    }
}
