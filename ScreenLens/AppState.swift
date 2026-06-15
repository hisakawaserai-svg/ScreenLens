//
//  AppState.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/11.
//
import Foundation
import Combine
import AppKit

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    // 💡 NSImage ではなく、ファイルが保存されている「URL」を持つように変更！
    let imageUrl: URL?
}

class AppState: ObservableObject {
    @Published var result: String = ""
    @Published var showWindow: Bool = false
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false
    
    // 💡 送信前のスクショも「URL」で保持
    @Published var pendingImageUrl: URL?
    
    /// セッション開始時の処理
    func startNewSession(imagePath: String) {
        // 文字列のパスをURLに変換してキープ
        self.pendingImageUrl = URL(fileURLWithPath: imagePath)
        self.showWindow = true
    }
    
    // 💡 アプリが完全に終了するとき、またはこのオブジェクトが破棄されるときに
    // 今回のセッションで生成した一時ファイルを根こそぎ自動削除する
    deinit {
        clearAllTemporaryFiles()
    }
    
    /// 生成した一時ファイルを完全に消し去る安全装置
    func clearAllTemporaryFiles() {
        let fileManager = FileManager.default
        
        // 送信待ちの画像を削除
        if let pendingUrl = pendingImageUrl {
            try? fileManager.removeItem(at: pendingUrl)
        }
        
        // チャット履歴の中にある画像をすべて削除
        for message in messages {
            if let url = message.imageUrl {
                try? fileManager.removeItem(at: url)
                print("🗑️ 一時ファイルを自動削除しました: \(url.lastPathComponent)")
            }
        }
        
        messages.removeAll()
        pendingImageUrl = nil
    }
}
