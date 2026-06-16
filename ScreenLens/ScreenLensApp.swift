//
//  ScreenLensApp.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//

import SwiftUI

@main
struct ScreenLensApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject var appState = AppState()
    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        // 1. メニーバー常駐の設定
        MenuBarExtra("ScreenLens", systemImage: "camera") {
            Button("アプリを開く") {
                // 既存のウィンドウを探す
                    if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        // なければ開く
                        openWindow(id: "main")
                    }
                }
            Divider()
            Button("画像を解析する") {
                appDelegate.analyzeScreen(appState: appState) {
                    openWindow(id: "main")
                }
            }
        }
        
        // 2. 解析結果を表示するウインドウ
        WindowGroup(id: "main") {
            ContentView(appState: appState, appDelegate: appDelegate)
                .background(VisualEffectView().ignoresSafeArea())
                .onAppear {
                    configureMacWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    /// 開いたウインドウを検知して、最小＆半透明にする処理
    private func configureMacWindow() {
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) else { return }
            
            window.isMovableByWindowBackground = true
            window.ignoresMouseEvents = false
            window.level = .floating
            
            window.hidesOnDeactivate = false
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
            
            // 2. 座標計算
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let newWidth: CGFloat = 420
                let newHeight: CGFloat = 620
                
                let newX = screenRect.maxX - newWidth
                let newY = screenRect.maxY - newHeight
                
                // 3. サイズと位置を強制適用
                window.setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true, animate: true)
                
                // 4. ユーザーに勝手にリサイズさせないための最小サイズ制約をコードで強制
                window.minSize = NSSize(width: 420, height: 620)
            }
        }
    }
}

/// macOS特有の「すりガラス（半透明）背景」を作るためのパーツ
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow // ウインドウの背景にあるデスクトップを透けさせる
        view.material = .hudWindow       // HUD（映画のUIのような、黒みがかったモダンな半透明）
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
