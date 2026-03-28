import Foundation

extension FileManager {
    var booksDirectory: URL {
        let docs = urls(for: .documentDirectory, in: .userDomainMask)[0]
        let books = docs.appendingPathComponent("Books", isDirectory: true)
        if !fileExists(atPath: books.path()) {
            try? createDirectory(at: books, withIntermediateDirectories: true)
        }
        return books
    }

    func bookPDFURL(fileName: String) -> URL {
        booksDirectory.appendingPathComponent(fileName)
    }

    func bookTextCacheURL(fileName: String) -> URL {
        let base = (fileName as NSString).deletingPathExtension
        return booksDirectory.appendingPathComponent("\(base).txt")
    }

    var sharedInboxURL: URL? {
        containerURL(forSecurityApplicationGroupIdentifier: "group.xtypo.Shunkan")?
            .appendingPathComponent("Inbox", isDirectory: true)
    }
}
