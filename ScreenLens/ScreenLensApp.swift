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
    // 💡 元のコード通り、StateObjectとして管理
    @StateObject var appState = AppState()
    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        // 1. メニーバー常駐の設定（元の綺麗な設計をキープ！）
        MenuBarExtra("ScreenLens", systemImage: "camera") {
            Button("画像を解析する") {
                appDelegate.analyzeScreen(appState: appState) {
                    openWindow(id: "main")
                }
            }
        }
        
        // 2. 解析結果を表示するウインドウ（ここをおしゃれに大改造）
        WindowGroup(id: "main") {
            ContentView(appState: appState, appDelegate: appDelegate)
                .background(VisualEffectView().ignoresSafeArea())
                .onAppear {
                    configureMacWindow()
                }
        }
        // 👇 タイトルバーを非表示にして、SafariやFinderみたいな「ただの四角いダサい枠」を消し去る
        .windowStyle(.hiddenTitleBar)
    }
    
    /// 開いたウインドウを検知して、右縦半分＆半透明にする処理
    private func configureMacWindow() {
        // 💡 画面上に今開いた「main」ウインドウを探し出す
        // タイトルバーを隠しているため、一工夫して取得します
        DispatchQueue.main.async {
            guard let window = NSApplication.shared.windows.first(where: { $0.isVisible && $0.titleVisibility == .hidden }) else { return }
            
            // ウインドウの枠線を消し、透明なキャンバスにする設定
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            // アプリが非アクティブになっても、他のウインドウの手前に常に表示させたい場合はこれを有効に（お好みで）
            // window.level = .floating
            
            // 💡 ディスプレイのサイズを取得して「作業の邪魔にならない右端の特等席」を計算
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                
                // 💡 半分ではなく、チャットや画像が綺麗に見える最小の「420ポイント」に固定！
                let newWidth: CGFloat = 420
                let newHeight = screenRect.height
                
                // 画面の右端にぴったり吸着させる座標計算
                let newX = screenRect.origin.x + screenRect.width - newWidth
                let newY = screenRect.origin.y
                
                // 計算した座標にフィットさせる
                window.setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true, animate: true)
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
