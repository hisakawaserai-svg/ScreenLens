//
//  GeminiService.swift
//  AIAssistant
//
//  Created by h S. on 2026/05/08.
//

// MARK: - GeminiService
// 役割: Gemini APIとの通信を行うサービスクラス
// 使い方： GeminiService().GeminiResponse(prompt: "質問")で呼び出す

import Foundation
import ScreenCaptureKit

class GeminiService {
    struct GeminiResponse: Codable {
        let candidates: [Candidate]
    }

    struct Candidate: Codable {
        let content: Content
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String
    }
    
    func callGemini(prompt: NSImage) async throws -> String{
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // NSImage -> cgImage -> pngDataに変換
        guard let cgImage = prompt.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let pngData = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) else {
            throw NSError()
        }
        
        // pngData -> base64 に変換
        let base64String = pngData.base64EncodedString()
        
        // 送信データ定義
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/png",
                                "data": base64String
                            ]
                        ]
                    ]
                ]
            ],
            "systemInstruction": [
                "parts": [
                    // プロンプト
                    ["text": "画像の内容を日本語で詳しく解説してください。"]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 4096
            ],
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 {
                    return "リクエスト上限に達しました\nしばらく待ってから試してください"
                } else if httpResponse.statusCode == 503 {
                    return "現在サーバが混み合っております\nしばらく待ってからもう一度試してみてください"
                }
            }
            
            let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
            
            if let rawString = String(data: data, encoding: .utf8) {
                print(rawString)
            }
            
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return decoded.candidates.first?.content.parts.first?.text ?? "空"
        } catch {
            return "エラー: \(error.localizedDescription)"
        }
    }
}
