import Foundation
import PDFKit
import UIKit

struct PDFParserService {
    struct ParseResult {
        let text: String
        let totalWords: Int
        let pageCount: Int
        let thumbnailData: Data?
        let chapters: [Chapter]
        let pageWordOffsets: [Int]
    }

    struct Chapter: Codable {
        let title: String
        let wordIndex: Int
    }

    static func parse(pdfURL: URL) async throws -> ParseResult {
        guard let document = PDFDocument(url: pdfURL) else {
            throw PDFParseError.cannotOpenDocument
        }

        let (text, pageWordOffsets, totalWords) = extractTextWithOffsets(from: document)
        let pageCount = document.pageCount
        let thumbnailData = generateThumbnail(from: document)
        let chapters = extractChapters(from: document, pageWordOffsets: pageWordOffsets)

        return ParseResult(
            text: text,
            totalWords: totalWords,
            pageCount: pageCount,
            thumbnailData: thumbnailData,
            chapters: chapters,
            pageWordOffsets: pageWordOffsets
        )
    }

    private static func extractTextWithOffsets(from document: PDFDocument) -> (text: String, pageWordOffsets: [Int], totalWords: Int) {
        var pages: [String] = []
        var pageWordOffsets: [Int] = []
        var runningWordCount = 0

        for i in 0..<document.pageCount {
            pageWordOffsets.append(runningWordCount)
            if let page = document.page(at: i), let text = page.string {
                pages.append(text)
                let tokens = Tokenizer.tokenize(text)
                runningWordCount += tokens.count
            }
            if i < document.pageCount - 1 {
                runningWordCount += 1
            }
        }
        return (pages.joined(separator: "\n\n"), pageWordOffsets, runningWordCount)
    }

    private static func extractChapters(from document: PDFDocument, pageWordOffsets: [Int]) -> [Chapter] {
        guard let outline = document.outlineRoot else { return [] }

        var chapters: [Chapter] = []
        collectOutlineItems(outline, into: &chapters, document: document, pageWordOffsets: pageWordOffsets)
        return chapters
    }

    private static func collectOutlineItems(
        _ item: PDFOutline,
        into chapters: inout [Chapter],
        document: PDFDocument,
        pageWordOffsets: [Int]
    ) {
        for i in 0..<item.numberOfChildren {
            guard let child = item.child(at: i) else { continue }
            if let destination = child.destination,
               let page = destination.page,
               let pageIndex = document.index(for: page) as Int?,
               pageIndex < pageWordOffsets.count,
               let label = child.label, !label.isEmpty {
                chapters.append(Chapter(title: label, wordIndex: pageWordOffsets[pageIndex]))
            }
            collectOutlineItems(child, into: &chapters, document: document, pageWordOffsets: pageWordOffsets)
        }
    }

    private static func generateThumbnail(from document: PDFDocument) -> Data? {
        guard let page = document.page(at: 0) else { return nil }
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 300.0 / pageRect.width
        let thumbSize = CGSize(
            width: pageRect.width * scale,
            height: pageRect.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: thumbSize))
            ctx.cgContext.translateBy(x: 0, y: thumbSize.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
        return image.jpegData(compressionQuality: 0.7)
    }
}

enum PDFParseError: LocalizedError {
    case cannotOpenDocument

    var errorDescription: String? {
        switch self {
        case .cannotOpenDocument:
            return "Could not open the PDF file."
        }
    }
}
