import Foundation
import UIKit

struct PhotoStore {
    private let fileManager: FileManager
    private let rootDirectory: URL

    init(fileManager: FileManager = .default, rootDirectory: URL? = nil) {
        self.fileManager = fileManager
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) {
            self.rootDirectory = group.appending(path: "Photos", directoryHint: .isDirectory)
        } else {
            self.rootDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appending(path: "Photos", directoryHint: .isDirectory)
        }
    }

    func save(_ image: UIImage) throws -> String {
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        let url = url(for: fileName)
        guard let data = image.jpegData(compressionQuality: 0.86) else {
            throw PhotoStoreError.couldNotEncodeJPEG
        }
        try data.write(to: url, options: [.atomic])
        return fileName
    }

    func image(for fileName: String?) -> UIImage? {
        guard let fileName else { return nil }
        return UIImage(contentsOfFile: url(for: fileName).path())
    }

    func delete(fileName: String?) throws {
        guard let fileName else { return }
        try delete(fileName: fileName)
    }

    func delete(fileName: String) throws {
        let url = url(for: fileName)
        if fileManager.fileExists(atPath: url.path()) {
            try fileManager.removeItem(at: url)
        }
    }

    func url(for fileName: String) -> URL {
        rootDirectory.appending(path: fileName)
    }
}

enum PhotoStoreError: Error {
    case couldNotEncodeJPEG
}
