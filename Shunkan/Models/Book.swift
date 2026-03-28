import Foundation
import SwiftData

@Model
final class Book: Hashable {
    var title: String
    var fileName: String
    var totalWords: Int
    var currentWordIndex: Int
    var pageCount: Int
    var lastReadDate: Date?
    var dateAdded: Date
    @Attribute(.externalStorage) var thumbnailData: Data?
    var collections: [BookCollection]

    init(
        title: String,
        fileName: String,
        totalWords: Int,
        pageCount: Int = 0,
        currentWordIndex: Int = 0,
        dateAdded: Date = .now,
        thumbnailData: Data? = nil,
        collections: [BookCollection] = []
    ) {
        self.title = title
        self.fileName = fileName
        self.totalWords = totalWords
        self.pageCount = pageCount
        self.currentWordIndex = currentWordIndex
        self.dateAdded = dateAdded
        self.thumbnailData = thumbnailData
        self.collections = collections
    }

    var progress: Double {
        guard totalWords > 0 else { return 0 }
        return min(1.0, Double(currentWordIndex) / Double(totalWords))
    }

    var isComplete: Bool {
        totalWords > 0 && currentWordIndex >= totalWords
    }

    static func == (lhs: Book, rhs: Book) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
}
