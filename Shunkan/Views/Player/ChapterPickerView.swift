import SwiftUI

struct ChapterPickerView: View {
    let chapters: [PDFParserService.Chapter]
    let pageCount: Int
    let currentIndex: Int
    let totalWords: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss

    private var wordsPerPage: Int {
        guard pageCount > 0 && totalWords > 0 else { return 1 }
        return max(1, totalWords / pageCount)
    }

    var body: some View {
        NavigationStack {
            List {
                if chapters.isEmpty {
                    Section("Pages") {
                        ForEach(0..<pageCount, id: \.self) { page in
                            let wordIndex = page * wordsPerPage
                            Button {
                                onSelect(wordIndex)
                            } label: {
                                HStack {
                                    Text("Page \(page + 1)")
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if isCurrentPage(page) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Section("Chapters") {
                        ForEach(Array(chapters.enumerated()), id: \.offset) { index, chapter in
                            Button {
                                onSelect(chapter.wordIndex)
                            } label: {
                                HStack {
                                    Text(chapter.title)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if isCurrentChapter(index) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Jump to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func isCurrentPage(_ page: Int) -> Bool {
        let pageStart = page * wordsPerPage
        let pageEnd = (page + 1) * wordsPerPage
        return currentIndex >= pageStart && currentIndex < pageEnd
    }

    private func isCurrentChapter(_ index: Int) -> Bool {
        let chapterStart = chapters[index].wordIndex
        let chapterEnd = index + 1 < chapters.count ? chapters[index + 1].wordIndex : totalWords
        return currentIndex >= chapterStart && currentIndex < chapterEnd
    }
}
