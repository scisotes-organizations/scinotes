//
//  SciNotesDocument.swift
//  SciNotes
//
//  Created by Takeru Ito on 2025/05/12.
//

import SwiftUI
import PencilKit
import UniformTypeIdentifiers

// ドキュメントタイプの定義
extension UTType {
    static var sciNotesDocument: UTType {
        UTType(exportedAs: "com.scinotes.document")
    }
}

// ノートデータの定義
struct NoteData: Identifiable, Codable {
    var id = UUID()
    var title: String
    var drawing: PKDrawing = PKDrawing()
    
    enum CodingKeys: String, CodingKey {
        case id, title, drawing
    }
    
    init(title: String) {
        self.title = title
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        // PKDrawingのデコード
        if let drawingData = try? container.decode(Data.self, forKey: .drawing) {
            drawing = try PKDrawing(data: drawingData)
        } else {
            drawing = PKDrawing()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        
        // PKDrawingのエンコード - dataRepresentation()を使用
        let drawingData = try drawing.dataRepresentation()
        try container.encode(drawingData, forKey: .drawing)
    }
}

// ドキュメントモデルクラス - FileDocumentプロトコルに準拠
struct SciNotesDocument: FileDocument {
    var notesData: [NoteData]
    
    // 初期化メソッド（新規ドキュメント作成用）
    init(notesData: [NoteData] = [NoteData(title: "Note 1")]) {
        self.notesData = notesData
    }
    
    // ファイルタイプを定義
    static var readableContentTypes: [UTType] { [.sciNotesDocument] }
    static var writableContentTypes: [UTType] { [.sciNotesDocument] }
    
    // 初期化メソッド（ファイルからの読み込み用）
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // JSONデコード処理
        do {
            let decoder = JSONDecoder()
            self.notesData = try decoder.decode([NoteData].self, from: data)
        } catch {
            print("デコードエラー: \(error.localizedDescription)")
            // デコードに失敗した場合は空のノートリストを作成
            self.notesData = [NoteData(title: "Note 1")]
        }
    }
    
    // ファイル保存メソッド
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        do {
            // JSONエンコード処理 - PKDrawingのデータも含めてエンコード
            let encoder = JSONEncoder()
            let data = try encoder.encode(notesData)
            return FileWrapper(regularFileWithContents: data)
        } catch {
            print("エンコードエラー: \(error.localizedDescription)")
            throw error
        }
    }
}
