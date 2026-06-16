//
//  GeminiService.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/08.
//

// MARK: - GeminiService
// 役割: Gemini APIとの通信を行うサービスクラス
// 使い方： GeminiService().GeminiResponse(prompt: "質問" + image: NSImage)で呼び出す

import Foundation
import ScreenCaptureKit
import AppKit

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
    
    /// 画像（image）をオプション（あってもなくても良い）にし、テキストの質問（textPrompt）を受け取る
    func callGemini(textPrompt: String, image: NSImage?) async throws -> String {
        // この部分を自分のgeminiAPIキーに変更してください
        let apiKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String ?? ""
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 1. まずはテキスト用のパーツを作成
        var partsArray: [[String: Any]] = [
            ["text": textPrompt.isEmpty ? "画像の内容を日本語で詳しく解説してください。" : textPrompt]
        ]
        
        // 2. もし画像がある場合は、画像をbase64に変換してパーツに追加する（なければスキップ！）
        if let inputImage = image {
            if let cgImage = inputImage.cgImage(forProposedRect: nil, context: nil, hints: nil),
               let pngData = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:]) {
                let base64String = pngData.base64EncodedString()
                let imagePart: [String: Any] = [
                    "inline_data": [
                        "mime_type": "image/png",
                        "data": base64String
                    ]
                ]
                partsArray.append(imagePart) // 配列に合流させる
            }
        }
        
        // 送信データの組み立て
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": partsArray
                ]
            ],
            "systemInstruction": [
                "parts": [
                    ["text": "あなたはMacの画面解析をサポートする有能なAIアシスタントです。質問に対して簡潔かつ正確に日本語で答えてください。"]
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
            
            let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
            return decoded.candidates.first?.content.parts.first?.text ?? "返答が空でした"
        } catch {
            return "エラー: \(error.localizedDescription)"
        }
    }
}
