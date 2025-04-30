//
//  APIService.swift
//  SciNotes
//
//  Created by Takeru Ito on 2025/04/30.
//

import Foundation
import SwiftUI

class APIService {
    // サーバーのエンドポイント - 実際のIPアドレスに変更してください
    static let baseURL = "http://127.0.0.1:8000"
    
    // 座標情報を送信する関数
    static func sendCoordinate(x: CGFloat, y: CGFloat, noteId: UUID) {
        // URLを作成
        guard let url = URL(string: "\(baseURL)") else {
            print("Invalid URL")
            return
        }
        
        // リクエストを設定
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSONデータを作成
        let coordinateData: [String: Any] = [
            "x": x,
            "y": y,
            "noteId": noteId.uuidString
        ]
        
        do {
            // JSONデータをエンコード
            let jsonData = try JSONSerialization.data(withJSONObject: coordinateData)
            request.httpBody = jsonData
            
            // URLSessionを使用して非同期にデータを送信
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending coordinate data: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("No HTTP response")
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    print("Coordinate sent successfully: x=\(x), y=\(y)")
                } else {
                    print("Error: HTTP Status code: \(httpResponse.statusCode)")
                    
                    if let data = data,
                       let errorResponse = String(data: data, encoding: .utf8) {
                        print("Server response: \(errorResponse)")
                    }
                }
            }.resume()
            
        } catch {
            print("Error encoding coordinate data: \(error.localizedDescription)")
        }
    }
}