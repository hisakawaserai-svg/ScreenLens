//
//  ScreenCaptureManager.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//
//  MARK: - スクリーンキャプチャーを管理するクラス
//  用途：選択範囲を選択 -> スクショ撮影 -> 画像を返す

import Foundation
import ScreenCaptureKit

class ScreenCaptureManager{
    func takeScreenshot(of: CGRect) async throws -> NSImage {
        // 画面に表示されてるウィンドウ一覧を取得する
        let shareableContent = try await SCShareableContent.current
        
        // 撮影対象のディスプレイを取得
        guard let display = shareableContent.displays.first else {
            throw NSError()
        }
        
        // 選択範囲を取得
        let filter = SCContentFilter(display: display, including: [])
        
        // 選択範囲の設定
        let config = SCStreamConfiguration()
        config.sourceRect = of
        
        // 撮影を実行
        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        
        // CGImage -> NSImage に変換
        let nsImage = NSImage(cgImage: cgImage, size: .zero)
        
        return nsImage
    }
}
