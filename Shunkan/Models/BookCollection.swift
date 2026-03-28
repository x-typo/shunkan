import Foundation
import SwiftData

@Model
final class BookCollection: Hashable {
    var name: String
    @Relationship(inverse: \Book.collections) var books: [Book]

    init(name: String, books: [Book] = []) {
        self.name = name
        self.books = books
    }

    static func == (lhs: BookCollection, rhs: BookCollection) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
}
