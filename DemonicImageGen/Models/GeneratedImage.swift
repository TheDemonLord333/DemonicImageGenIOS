//
//  GeneratedImage.swift
//  DemonicImageGen
//

import Foundation

struct GeneratedImage: Identifiable, Codable, Equatable {
    let id: UUID
    let prompt: String
    let style: StylePreset
    let fileName: String
    let width: Int
    let height: Int
    let seed: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        prompt: String,
        style: StylePreset,
        fileName: String,
        width: Int,
        height: Int,
        seed: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prompt = prompt
        self.style = style
        self.fileName = fileName
        self.width = width
        self.height = height
        self.seed = seed
        self.createdAt = createdAt
    }
}
