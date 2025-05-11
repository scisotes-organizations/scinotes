//
//  ContentView.swift
//  SciNotes
//
//  Created by Takeru Ito on 2025/04/26.
//

import SwiftUI
import PencilKit

struct NoteData: Identifiable {
    var id = UUID()
    var title: String
    var drawing: PKDrawing = PKDrawing()
}

class NotesViewModel: ObservableObject {
    @Published var notes: [NoteData]
    @Published var selectedNoteIndex: Int
    
    init() {
        self.notes = [NoteData(title: "Note 1")]
        self.selectedNoteIndex = 0
    }
    
    func addNewNote() {
        let newNote = NoteData(title: "Note \(notes.count + 1)")
        notes.append(newNote)
        selectedNoteIndex = notes.count - 1
    }
    
    func deleteNote(atIndex index: Int) {
        guard notes.count > 1 else { return }
        notes.remove(at: index)
        if selectedNoteIndex >= notes.count {
            selectedNoteIndex = notes.count - 1
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var isErasing: Bool = false
    @State private var inkColor: Color = .black
    @State private var inkWidth: CGFloat = 5.0
    @State private var currentTool: PKInkingTool.InkType = .pen
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(0..<viewModel.notes.count, id: \.self) { index in
                    HStack {
                        Text(viewModel.notes[index].title)
                            .fontWeight(viewModel.selectedNoteIndex == index ? .bold : .regular)
                        
                        Spacer()
                        
                        if viewModel.notes.count > 1 {
                            Button(action: {
                                viewModel.deleteNote(atIndex: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedNoteIndex = index
                    }
                    .padding(.vertical, 4)
                }
                
                Button(action: {
                    viewModel.addNewNote()
                }) {
                    Label("Add New Note", systemImage: "plus")
                }
                .padding(.top)
            }
            .navigationTitle("SciNotes")
        } detail: {
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
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                
                // Drawing Canvas
                DrawingView(drawing: $viewModel.notes[viewModel.selectedNoteIndex].drawing, 
                           isErasing: isErasing,
                           inkType: currentTool,
                           inkColor: inkColor,
                           inkWidth: inkWidth,
                           viewModel: viewModel) // viewModelを渡す
                .background(Color.white)
            }
            .navigationTitle(viewModel.notes[viewModel.selectedNoteIndex].title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // This would typically save or export the drawing
                        print("Save/Export functionality would go here")
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
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
    
    // viewModel プロパティを追加
    @ObservedObject var viewModel: NotesViewModel
    
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
                    
                    // 親ビューモデルから選択中のノートIDを取得
                    let noteId = parent.viewModel.notes[parent.viewModel.selectedNoteIndex].id
                    
                    // サーバーに座標を送信
                    APIService.sendCoordinate(
                        x: topRightPoint.x,
                        y: topRightPoint.y,
                        noteId: noteId
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
