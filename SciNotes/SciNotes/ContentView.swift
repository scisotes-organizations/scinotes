//
//  ContentView.swift
//  SciNotes
//
//  Created by Takeru Ito on 2025/04/26.
//

import SwiftUI
import PencilKit

struct ContentView: View {
    @Binding var document: SciNotesDocument
    @State private var selectedNoteIndex = 0
    @State private var isErasing: Bool = false
    @State private var inkColor: Color = .black
    @State private var inkWidth: CGFloat = 5.0
    @State private var currentTool: PKInkingTool.InkType = .pen
    
    var body: some View {
        VStack(spacing: 0) {
            // Tool Bar
            HStack(spacing: 20) {
                // Pen/Marker/Eraser Tools
                HStack {
                    Button(action: {
                        currentTool = .pen
                        isErasing = false
                    }) {
                        Image(systemName: "pencil.tip")
                            .font(.system(size: 24))
                            .padding(8)
                            .background(currentTool == .pen && !isErasing ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(currentTool == .pen && !isErasing ? .blue : .primary)
                    }
                    
                    Button(action: {
                        currentTool = .marker
                        isErasing = false
                    }) {
                        Image(systemName: "highlighter")
                            .font(.system(size: 24))
                            .padding(8)
                            .background(currentTool == .marker && !isErasing ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(currentTool == .marker && !isErasing ? .blue : .primary)
                    }
                    
                    Button(action: {
                        isErasing = true
                    }) {
                        Image(systemName: "eraser")
                            .font(.system(size: 24))
                            .padding(8)
                            .background(isErasing ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                            .foregroundColor(isErasing ? .blue : .primary)
                    }
                }
                
                Divider()
                    .frame(height: 30)
                
                // Color Picker
                ColorPicker("", selection: $inkColor)
                    .labelsHidden()
                    .disabled(isErasing)
                
                // Preview of selected color
                Circle()
                    .fill(inkColor)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                
                Divider()
                    .frame(height: 30)
                
                // Width Slider
                HStack {
                    Text("Width:")
                    Slider(value: $inkWidth, in: 1...20, step: 0.5)
                        .frame(width: 150)
                        .disabled(isErasing)
                    Text(String(format: "%.1f", inkWidth))
                        .frame(width: 30)
                }
                
                Spacer()
                
                // ノート切り替えボタン - サイドバーの代わりにドロップダウンメニュー
                Menu {
                    // ForEach と「新規ノート追加」ボタンを削除
                    
                    if document.notesData.count > 1 {
                        Button(role: .destructive, action: {
                            document.notesData.remove(at: selectedNoteIndex)
                            if selectedNoteIndex >= document.notesData.count {
                                selectedNoteIndex = document.notesData.count - 1
                            }
                        }) {
                            Label("現在のノートを削除", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 24))
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            
            // Drawing Canvas
            if document.notesData.indices.contains(selectedNoteIndex) {
                DrawingView(
                    drawing: $document.notesData[selectedNoteIndex].drawing,
                    isErasing: isErasing,
                    inkType: currentTool,
                    inkColor: inkColor,
                    inkWidth: inkWidth,
                    noteId: document.notesData[selectedNoteIndex].id
                )
                .background(Color.white)
            }
        }
        .navigationTitle(document.notesData.indices.contains(selectedNoteIndex) ? document.notesData[selectedNoteIndex].title : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ノートタイトルのテキストフィールドを削除
            
            // 共有ボタン
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: "SciNotes Document", preview: SharePreview("SciNotes Document", image: Image(systemName: "doc")))
            }
        }
    }
}

struct DrawingView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var isErasing: Bool
    var inkType: PKInkingTool.InkType
    var inkColor: Color
    var inkWidth: CGFloat
    var noteId: UUID
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.tool = getTool()
        
        // 非推奨のallowsFingerDrawingを削除し、drawingPolicyだけを使用
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = getTool()
        
        // Only update the drawing if it was changed externally
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func getTool() -> PKTool {
        if isErasing {
            return PKEraserTool(.bitmap)
        } else {
            // Convert SwiftUI Color to UIKit UIColor
            let uiColor = UIColor(
                red: Double(inkColor.cgColor?.components?[0] ?? 0),
                green: Double(inkColor.cgColor?.components?[1] ?? 0),
                blue: Double(inkColor.cgColor?.components?[2] ?? 0),
                alpha: Double(inkColor.cgColor?.components?[3] ?? 1)
            )
            
            return PKInkingTool(inkType, color: uiColor, width: inkWidth)
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: DrawingView
        
        init(_ parent: DrawingView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            
            // 最新のストロークを取得
            if let latestStroke = canvasView.drawing.strokes.last {
                // PKStrokePath.interpolatedPoints の正しい使い方
                let interpolatedPoints = latestStroke.path.interpolatedPoints(by: .distance(5))
                
                // ポイント配列に変換して処理
                let points = Array(interpolatedPoints)
                
                if points.count > 0 {
                    // 最初のポイントを初期値として設定
                    var topRightPoint = points[0].location
                    
                    // 各ポイントを確認して最も右上にある点を見つける
                    for point in points {
                        let location = point.location
                        // x座標が大きく、y座標が小さいほど「右上」の点になる
                        if location.x > topRightPoint.x && location.y < topRightPoint.y {
                            topRightPoint = location
                        } else if location.x > topRightPoint.x {
                            // x座標が大きければ、とりあえず更新
                            topRightPoint = location
                        }
                    }
                    
                    // サーバーに座標を送信（noteIdを直接使用）
                    APIService.sendCoordinate(
                        x: topRightPoint.x,
                        y: topRightPoint.y,
                        noteId: parent.noteId
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView(document: .constant(SciNotesDocument()))
}