import SwiftUI
import SwiftData

struct CollectionPillsView: View {
    @Query(sort: \BookCollection.name) var collections: [BookCollection]
    @Binding var selected: BookCollection?
    let onCreateCollection: () -> Void
    let onDeleteCollection: (BookCollection) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PillButton(label: "All", isSelected: selected == nil) {
                    selected = nil
                }

                ForEach(collections) { collection in
                    PillButton(
                        label: collection.name,
                        isSelected: selected == collection
                    ) {
                        selected = collection
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            if selected == collection {
                                selected = nil
                            }
                            onDeleteCollection(collection)
                        }
                    }
                }

                PillButton(label: "+ New", isSelected: false) {
                    onCreateCollection()
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct PillButton: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .secondary)
                .clipShape(Capsule())
        }
    }
}
