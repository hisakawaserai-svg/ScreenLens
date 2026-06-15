//
//  AppDelegate.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//

import Cocoa
// MARK: - サービスメニューから呼ばれる関数
// 右クリック ->「画像を解析する」で起動
// スクショ -> Gemini送信 -> 削除の流れを管理する

class AppDelegate: NSObject, NSApplicationDelegate {
    func analyzeScreen(appState: AppState, openWindow: @escaping () -> Void) {
        let screenshot = ScreenshotService()
        let service = GeminiService()
        
        let path = screenshot.takeScreenshot()
        guard let image = screenshot.loadImage(path: path) else { return }
        defer {
            screenshot.deleteTemp(path: path)
        }
        
        Task{
            do {
                let result = try await service.callGemini(prompt: image)
                await MainActor.run{
                    appState.result = result
                    openWindow()
                }
            } catch {
                print("エラー：\(error)")
            }
        }
    }
}
