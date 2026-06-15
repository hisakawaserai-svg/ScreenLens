//
//  ScreenshotService.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/11.
//
//  選択範囲をスクリーンショット & 絶対パスからNSImage型に変換するクラス

import Foundation
import AppKit

class ScreenshotService {
    
    /// 💡 アプリ専用の一時キャッシュフォルダのURLを取得・作成する関数
    private var cacheDirectoryURL: URL {
        // Macの共通tempフォルダの場所を取得
        let systemTemp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        // その中に「ScreenLens_Cache」という専用フォルダのパスを作る
        let customCacheDir = systemTemp.appendingPathComponent("ScreenLens_Cache", isDirectory: true)
        
        // もしフォルダがまだ存在していなければ、物理的に自動作成する
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: customCacheDir.path) {
            try? fileManager.createDirectory(at: customCacheDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return customCacheDir
    }
    
    //  MARK: - 選択範囲をスクリーンショットする関数
    func takeScreenshot() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        
        // 💡 【バグ修正・プロ仕様化】
        // 専用フォルダの直下に、毎回絶対に被らないランダムなID（UUID）をファイル名にして指定する
        let uniqueFileName = "screenshot_\(UUID().uuidString).png"
        let tempFileURL = cacheDirectoryURL.appendingPathComponent(uniqueFileName)
        let tempPath = tempFileURL.path
        
        // 引数 -i と 保存パスを定義
        process.arguments = ["-i", tempPath]
        
        try? process.run()
        process.waitUntilExit()
        
        return tempPath
    }
    
    //  MARK: - 画像ファイルをNSImage型に変換する関数
    func loadImage(path: String) -> NSImage? {
        return NSImage(contentsOfFile: path)
    }
    
    //  MARK: - 絶対パスからファイルを削除する関数
    func deleteTemp(path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
}
