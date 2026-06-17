//
//  AppDelegate.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var appState: AppState?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func analyzeScreen(appState: AppState, onComplete: @escaping () -> Void) {
        self.appState = appState
        let path = ScreenshotService().takeScreenshot()
        
        DispatchQueue.main.async {
            appState.startNewSession(imagePath: path)
            onComplete()
        }
    }
}
