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
        MenuBarExtra("ScreenLens", systemImage: "camera"){
            Button("画像を解析する"){
                appDelegate.analyzeScreen(appState: appState) {
                    openWindow(id: "main")
                }
            }
        }
        WindowGroup(id: "main") {
            ContentView(appState: appState)
        }
    }
}
