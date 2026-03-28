import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0
        handleSharedItems()
    }

    private func handleSharedItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            close()
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.pdf.identifier) { [weak self] data, _ in
                        guard let url = data as? URL else {
                            self?.close()
                            return
                        }
                        self?.copyToAppGroup(url: url)
                        self?.close()
                    }
                    return
                }
            }
        }
        close()
    }

    private func copyToAppGroup(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.xtypo.Shunkan") else { return }

        let inbox = containerURL.appendingPathComponent("Inbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)

        var dest = inbox.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            let base = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            let suffix = "\(base)-\(UUID().uuidString.prefix(8))"
            dest = ext.isEmpty
                ? inbox.appendingPathComponent(suffix)
                : inbox.appendingPathComponent("\(suffix).\(ext)")
        }
        try? FileManager.default.copyItem(at: url, to: dest)
    }

    private func close() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
