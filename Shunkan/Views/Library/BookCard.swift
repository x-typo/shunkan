import SwiftUI
import SwiftData

struct BookCard: View {
    let book: Book

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                if let data = book.thumbnailData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(
                            hue: Double(book.title.utf8.reduce(0 as UInt) { ($0 &+ UInt($1)) &* 31 } % 360) / 360.0,
                            saturation: 0.3, brightness: 0.2))
                        .frame(height: 180)
                        .overlay {
                            Text(book.title)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(8)
                        }
                }

                GeometryReader { geo in
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(book.isComplete ? Color.green : Color.blue)
                            .frame(width: geo.size.width * book.progress, height: 3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Text(book.title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Group {
                if book.isComplete {
                    Text("Done")
                        .foregroundStyle(.green)
                } else if book.currentWordIndex == 0 {
                    Text("New")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(Int(book.progress * 100))%")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption2)
        }
    }
}
