import SwiftUI
import SwiftData
import UniformTypeIdentifiers

enum SortOption: String, CaseIterable {
    case recentlyRead = "Recently Read"
    case titleAZ = "Title A-Z"
    case dateAdded = "Date Added"
    case progress = "Progress"
}

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var books: [Book]
    @State private var selectedCollection: BookCollection?
    @State private var sortOption: SortOption = .recentlyRead
    @State private var showImporter = false
    @State private var showNewCollection = false
    @State private var newCollectionName = ""
    @State private var importError: String?
    @State private var isImporting = false
    @State private var navigateToBook: Book?
    @State private var showRename = false
    @State private var renameText = ""
    @State private var renameTarget: Book?
    @Query(sort: \BookCollection.name) private var allCollections: [BookCollection]

    private var filteredBooks: [Book] {
        var result = books
        if let collection = selectedCollection {
            result = result.filter { $0.collections.contains(collection) }
        }
        switch sortOption {
        case .recentlyRead:
            result.sort { ($0.lastReadDate ?? .distantPast) > ($1.lastReadDate ?? .distantPast) }
        case .titleAZ:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .progress:
            result.sort { $0.progress > $1.progress }
        }
        return result
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CollectionPillsView(
                        selected: $selectedCollection,
                        onCreateCollection: { showNewCollection = true },
                        onDeleteCollection: { collection in
                            modelContext.delete(collection)
                        }
                    )

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredBooks) { book in
                            BookCard(book: book)
                                .onTapGesture { navigateToBook = book }
                                .contextMenu {
                                    Button("Rename") {
                                        renameTarget = book
                                        renameText = book.title
                                        showRename = true
                                    }
                                    Menu("Move to Collection") {
                                        ForEach(allCollections) { collection in
                                            Button(collection.name) {
                                                if !book.collections.contains(collection) {
                                                    book.collections.append(collection)
                                                }
                                            }
                                        }
                                    }
                                    Button("Delete", role: .destructive) {
                                        try? ImportService.deleteBook(book, context: modelContext)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImporter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isImporting)
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleImport(result)
                }
            }
            .navigationDestination(item: $navigateToBook) { book in
                RSVPPlayerView(book: book)
            }
            .alert("Rename", isPresented: $showRename) {
                TextField("Title", text: $renameText)
                Button("Save") {
                    renameTarget?.title = renameText
                    renameTarget = nil
                }
                Button("Cancel", role: .cancel) { renameTarget = nil }
            }
            .alert("New Collection", isPresented: $showNewCollection) {
                TextField("Name", text: $newCollectionName)
                Button("Create") {
                    let collection = BookCollection(name: newCollectionName)
                    modelContext.insert(collection)
                    newCollectionName = ""
                }
                Button("Cancel", role: .cancel) { newCollectionName = "" }
            }
            .alert("Import Error", isPresented: .init(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
            .onReceive(NotificationCenter.default.publisher(for: .checkSharedInbox)) { _ in
                Task { await processSharedInbox() }
            }
        }
    }

    private func processSharedInbox() async {
        guard let inbox = FileManager.default.sharedInboxURL,
              FileManager.default.fileExists(atPath: inbox.path()) else { return }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: inbox, includingPropertiesForKeys: nil
        )) ?? []

        for file in files where file.pathExtension.lowercased() == "pdf" {
            do {
                _ = try await ImportService.importPDF(from: file, context: modelContext)
                try? FileManager.default.removeItem(at: file)
            } catch {
                // Leave file in inbox for retry on next foreground
            }
        }
    }

    private func handleImport(_ result: Result<[URL], Error>) async {
        isImporting = true
        defer { isImporting = false }
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            _ = try await ImportService.importPDF(from: url, context: modelContext)
        } catch {
            importError = error.localizedDescription
        }
    }
}
