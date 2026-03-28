import SwiftUI
import SwiftData

struct RSVPPlayerView: View {
    @Bindable var book: Book
    @Environment(\.modelContext) private var modelContext
    @State private var engine = RSVPEngine()
    @State private var hasLoaded = false
    @State private var loadError: String?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .onTapGesture {
                    if engine.isPlaying {
                        engine.pause()
                    } else if hasLoaded {
                        engine.play()
                    }
                }

            VStack {
                ProgressView(value: engine.progress)
                    .tint(.blue)
                    .scaleEffect(y: 0.5)
                    .padding(.horizontal)

                Text("Page \(engine.currentPageEstimate) of \(engine.pageCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

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
                    Button { engine.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        if engine.isPlaying {
                            engine.pause()
                        } else {
                            engine.play()
                        }
                    } label: {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                            .frame(width: 48, height: 48)
                            .overlay(Circle().stroke(.blue, lineWidth: 2))
                    }

                    Button { engine.skipForward() } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
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

    private func loadBook() async {
        do {
            let text = try await ImportService.loadText(fileName: book.fileName)
            engine.load(
                text: text,
                startIndex: book.currentWordIndex,
                pageCount: book.pageCount
            )
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
