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
        MenuBarExtra("ScreenLens", systemImage: "camera") {
            Button("アプリを開く") {
                if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    openWindow(id: "main")
                }
            }
            Divider()
            Button("画像を解析する") {
                appDelegate.analyzeScreen(appState: appState) {
                    if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                        window.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    } else {
                        openWindow(id: "main")
                    }
                }
            }
        }
        
        WindowGroup(id: "main") {
            ContentView(appState: appState, appDelegate: appDelegate)
                // 🚀 最小サイズは保証しつつ、上限を無くして自由なリサイズを復活させる
                .frame(minWidth: 420, minHeight: 620)
                .background(VisualEffectView().ignoresSafeArea())
                .background(WindowAccessor { window in
                    guard let window = window else { return }
                    
                    window.identifier = NSUserInterfaceItemIdentifier("main")
                    
                    window.isOpaque = false
                    window.backgroundColor = .clear // ウィンドウ自体の背景は完全にクリアに
                    
                    window.isMovableByWindowBackground = true
                    window.ignoresMouseEvents = false
                    window.level = .floating
                    window.hidesOnDeactivate = false
                    window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
                    
                    
                    if let screen = NSScreen.main {
                        let screenRect = screen.visibleFrame
                        let newWidth: CGFloat = 420
                        let newHeight: CGFloat = 620
                        let newX = screenRect.maxX - newWidth
                        let newY = screenRect.maxY - newHeight
                        
                        window.setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true, animate: false)
                        window.minSize = NSSize(width: 420, height: 620)

                    }
                    
                    window.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                })
                .onAppear {
                    if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                        window.delegate = appDelegate
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        // 🚀 自由なサイズ変更を受け入れる設定
        .windowResizability(.contentSize)
    }
}

struct WindowAccessor: NSViewRepresentable {
    var onWindowFound: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onWindowFound(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            onWindowFound(nsView.window)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
