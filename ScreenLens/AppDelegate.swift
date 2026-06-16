//
//  AppDelegate.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var appState: AppState?

    func openWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    func analyzeScreen(appState: AppState, onComplete: @escaping () -> Void) {
        self.appState = appState
        let path = ScreenshotService().takeScreenshot()
        
        DispatchQueue.main.async {
            appState.startNewSession(imagePath: path)
            onComplete() // 完了したらApp側で開く
        }
    }
}
