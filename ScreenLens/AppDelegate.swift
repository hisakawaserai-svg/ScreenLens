//
//  AppDelegate.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?

    @objc func analyzeScreenWrapper() {
        guard let state = self.appState else { return }
        analyzeScreen(appState: state) { }
    }

    func analyzeScreen(appState: AppState, openWindow: @escaping () -> Void) {
        self.appState = appState
        let screenshot = ScreenshotService()
        
        // 1. スクショを撮影（tempフォルダ内に保存される）
        let path = screenshot.takeScreenshot()
        
        DispatchQueue.main.async {
            // 2. パスをそのまま受け渡す
            appState.startNewSession(imagePath: path)
            openWindow()
        }
    }
}
