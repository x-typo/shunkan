import Foundation
import PDFKit
import UIKit

struct PDFParserService {
    struct ParseResult {
        let text: String
        let totalWords: Int
        let pageCount: Int
        let thumbnailData: Data?
    }

    static func parse(pdfURL: URL) async throws -> ParseResult {
        guard let document = PDFDocument(url: pdfURL) else {
            throw PDFParseError.cannotOpenDocument
        }

        let text = extractText(from: document)
        let totalWords = Tokenizer.wordCount(text)
        let pageCount = document.pageCount
        let thumbnailData = generateThumbnail(from: document)

        return ParseResult(
            text: text,
            totalWords: totalWords,
            pageCount: pageCount,
            thumbnailData: thumbnailData
        )
    }

    private static func extractText(from document: PDFDocument) -> String {
        var pages: [String] = []
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let text = page.string {
                pages.append(text)
            }
        }
        return pages.joined(separator: "\n\n")
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
