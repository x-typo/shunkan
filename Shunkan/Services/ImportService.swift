import Foundation
import SwiftData

struct ImportService {
    @MainActor
    static func importPDF(from sourceURL: URL, context: ModelContext) async throws -> Book {
        let fileName = uniqueFileName(for: sourceURL.lastPathComponent)
        let destURL = FileManager.default.bookPDFURL(fileName: fileName)
        let cacheURL = FileManager.default.bookTextCacheURL(fileName: fileName)

        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessing { sourceURL.stopAccessingSecurityScopedResource() }
        }

        try FileManager.default.copyItem(at: sourceURL, to: destURL)

        let result = try await PDFParserService.parse(pdfURL: destURL)

        try result.text.write(to: cacheURL, atomically: true, encoding: .utf8)

        let chaptersURL = FileManager.default.bookChaptersCacheURL(fileName: fileName)
        if let chaptersData = try? JSONEncoder().encode(result.chapters) {
            try? chaptersData.write(to: chaptersURL)
        }

        let title = titleFromFileName(sourceURL.lastPathComponent)
        let book = Book(
            title: title,
            fileName: fileName,
            totalWords: result.totalWords,
            pageCount: result.pageCount,
            thumbnailData: result.thumbnailData
        )
        context.insert(book)
        try context.save()

        return book
    }

    @MainActor
    static func deleteBook(_ book: Book, context: ModelContext) throws {
        let pdfURL = FileManager.default.bookPDFURL(fileName: book.fileName)
        let cacheURL = FileManager.default.bookTextCacheURL(fileName: book.fileName)
        let chaptersURL = FileManager.default.bookChaptersCacheURL(fileName: book.fileName)
        try? FileManager.default.removeItem(at: pdfURL)
        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.removeItem(at: chaptersURL)
        context.delete(book)
        try context.save()
    }

    static func loadText(fileName: String) async throws -> String {
        let cacheURL = FileManager.default.bookTextCacheURL(fileName: fileName)
        if FileManager.default.fileExists(atPath: cacheURL.path()) {
            return try String(contentsOf: cacheURL, encoding: .utf8)
        }
        let pdfURL = FileManager.default.bookPDFURL(fileName: fileName)
        let result = try await PDFParserService.parse(pdfURL: pdfURL)
        try result.text.write(to: cacheURL, atomically: true, encoding: .utf8)
        return result.text
    }

    static func loadChapters(fileName: String) -> [PDFParserService.Chapter] {
        let chaptersURL = FileManager.default.bookChaptersCacheURL(fileName: fileName)
        guard let data = try? Data(contentsOf: chaptersURL),
              let chapters = try? JSONDecoder().decode([PDFParserService.Chapter].self, from: data)
        else { return [] }
        return chapters
    }

    private static func uniqueFileName(for original: String) -> String {
        let dest = FileManager.default.bookPDFURL(fileName: original)
        if !FileManager.default.fileExists(atPath: dest.path()) {
            return original
        }
        let base = (original as NSString).deletingPathExtension
        let ext = (original as NSString).pathExtension
        var counter = 1
        while true {
            let candidate = "\(base)-\(counter).\(ext)"
            let candidateURL = FileManager.default.bookPDFURL(fileName: candidate)
            if !FileManager.default.fileExists(atPath: candidateURL.path()) {
                return candidate
            }
            counter += 1
        }
    }

    private static func titleFromFileName(_ fileName: String) -> String {
        let base = (fileName as NSString).deletingPathExtension
        return base
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }
}
