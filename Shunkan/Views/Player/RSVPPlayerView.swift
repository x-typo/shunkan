import SwiftUI
import SwiftData

struct RSVPPlayerView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var modelContext
    @State private var engine = RSVPEngine()
    @State private var hasLoaded = false
    @State private var loadError: String?
    @State private var chapters: [PDFParserService.Chapter] = []
    @State private var showChapterPicker = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture { togglePlayback() }

            VStack {
                ProgressView(value: engine.progress)
                    .tint(.blue)
                    .scaleEffect(y: 0.5)
                    .padding(.horizontal)

                Button {
                    if !engine.isPlaying && hasLoaded {
                        showChapterPicker = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Page \(engine.currentPageEstimate) of \(engine.pageCount)")
                        if !engine.isPlaying && hasLoaded {
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if let error = loadError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    WordDisplayView(
                        word: engine.currentWord,
                        dimmed: !engine.isPlaying
                    )
                }

                if !engine.isPlaying && hasLoaded {
                    WPMSliderView(wpm: $engine.wordsPerMinute)
                        .padding(.top, 32)
                        .transition(.opacity)
                }

                Spacer()

                HStack(spacing: 32) {
                    Button {
                        engine.wordsPerMinute = max(100, engine.wordsPerMinute - 10)
                    } label: {
                        Image(systemName: "minus")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }

                    Button { togglePlayback() } label: {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                            .frame(width: 48, height: 48)
                            .overlay(Circle().stroke(.blue, lineWidth: 2))
                    }

                    Button {
                        engine.wordsPerMinute = min(900, engine.wordsPerMinute + 10)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }

                Text("\(engine.wordsPerMinute) WPM")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
            }
            .animation(.easeInOut(duration: 0.2), value: engine.isPlaying)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    saveProgress()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showChapterPicker) {
            ChapterPickerView(
                chapters: chapters,
                pageCount: engine.pageCount,
                currentIndex: engine.currentIndex,
                totalWords: engine.words.count
            ) { wordIndex in
                engine.jumpTo(wordIndex: wordIndex)
                showChapterPicker = false
            }
            .presentationDetents([.medium, .large])
        }
        .task {
            await loadBook()
        }
        .onDisappear {
            engine.pause()
            saveProgress()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                engine.pause()
                saveProgress()
            }
        }
    }

    private func togglePlayback() {
        if engine.isPlaying {
            engine.pause()
        } else if hasLoaded {
            engine.play()
        }
    }

    private func loadBook() async {
        do {
            let text = try await ImportService.loadText(fileName: book.fileName)
            engine.load(
                text: text,
                startIndex: book.currentWordIndex,
                pageCount: book.pageCount
            )
            chapters = ImportService.loadChapters(fileName: book.fileName)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func saveProgress() {
        book.currentWordIndex = engine.currentIndex
        book.lastReadDate = .now
        try? modelContext.save()
    }
}
