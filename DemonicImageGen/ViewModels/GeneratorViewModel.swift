//
//  GeneratorViewModel.swift
//  DemonicImageGen
//

import Foundation
import UIKit

@MainActor
final class GeneratorViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var selectedStyle: StylePreset = .shadowRealm
    @Published var selectedSize: GenerationSize = .square
    @Published var isGenerating: Bool = false
    @Published var resultImage: UIImage?
    @Published var errorMessage: String?

    private let settings: AppSettings
    private let historyStore: ImageHistoryStore

    init(settings: AppSettings, historyStore: ImageHistoryStore) {
        self.settings = settings
        self.historyStore = historyStore
    }

    var canGenerate: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    func generate() async {
        guard canGenerate else { return }
        errorMessage = nil
        isGenerating = true
        defer { isGenerating = false }

        let service = BackendService(settings: settings)
        let fullPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines) + selectedStyle.promptSuffix
        let (width, height) = selectedSize.dimensions
        let seed = Int.random(in: 0..<Int(UInt32.max))

        do {
            let data = try await service.generateImage(
                prompt: fullPrompt,
                width: width,
                height: height,
                seed: seed
            )
            guard let image = UIImage(data: data) else {
                throw BackendError.decoding
            }
            resultImage = image
            historyStore.add(
                prompt: prompt,
                style: selectedStyle,
                imageData: data,
                width: width,
                height: height,
                seed: seed
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
