//
//  ImageHistoryStore.swift
//  DemonicImageGen
//
//  Speichert generierte Bilder lokal (Documents-Ordner) und hält ein
//  Manifest mit Metadaten als JSON.
//

import Foundation
import UIKit

@MainActor
final class ImageHistoryStore: ObservableObject {
    @Published private(set) var items: [GeneratedImage] = []

    private let maxItems = 60
    private let fileManager = FileManager.default

    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var manifestURL: URL {
        documentsURL.appendingPathComponent("history.json")
    }

    init() {
        load()
    }

    func add(prompt: String, style: StylePreset, imageData: Data, width: Int, height: Int, seed: Int) {
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = documentsURL.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
        } catch {
            return
        }

        let entry = GeneratedImage(
            prompt: prompt,
            style: style,
            fileName: fileName,
            width: width,
            height: height,
            seed: seed
        )

        items.insert(entry, at: 0)
        if items.count > maxItems {
            let overflow = items.suffix(from: maxItems)
            overflow.forEach { removeFile(for: $0) }
            items = Array(items.prefix(maxItems))
        }
        persist()
    }

    func delete(_ item: GeneratedImage) {
        removeFile(for: item)
        items.removeAll { $0.id == item.id }
        persist()
    }

    func imageURL(for item: GeneratedImage) -> URL {
        documentsURL.appendingPathComponent(item.fileName)
    }

    func uiImage(for item: GeneratedImage) -> UIImage? {
        UIImage(contentsOfFile: imageURL(for: item).path)
    }

    private func removeFile(for item: GeneratedImage) {
        try? fileManager.removeItem(at: imageURL(for: item))
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: manifestURL)
        } catch {
            // Verlust der Historie ist unkritisch, App bleibt funktionsfähig.
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: manifestURL) else { return }
        guard let decoded = try? JSONDecoder().decode([GeneratedImage].self, from: data) else { return }
        items = decoded
    }
}
