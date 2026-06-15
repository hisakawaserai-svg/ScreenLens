//
//  ScreenshotService.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/11.
//
//  選択範囲をスクリーンショット & 絶対パスからNSImage型に変換するクラス

import Foundation
import AppKit

//  MARK: - 選択範囲をスクリーンショットする関数
//  使い方：ScreenshotService().takeScreenshot で使う
//  引数：なし
//  戻り値：スクリーンショットしたpngの絶対パス: String型
class ScreenshotService{
    func takeScreenshot() -> String{
        // Foundationフレームワークの「Process = コマンド実行する道具」を取得
        let process = Process()
        // 実行するコマンドを選択 (screencapture)
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        // 保存する場所
        let tempPath = NSTemporaryDirectory() + "screenlens_temp.png"
        // 引数 -i と 保存パスを定義
        process.arguments = ["-i", tempPath]
        
        try? process.run()
        process.waitUntilExit()
        
        
        
        return tempPath
    }
    
    //  MARK: - 画像ファイルをNSImage型に変換する関数
    //  使い方：ScreenshotService().loadImage(path: 画像ファイルの絶対パス) で使う
    //  引数：path: 画像ファイルの絶対パス
    //  戻り値：NSImage? (読み込み失敗時はnil)
    func loadImage(path: String) -> NSImage?{
        return NSImage(contentsOfFile: path)
    }
    
    //  MARK: - 絶対パスからファイルを削除する関数
    //  使い方：ScreenshotService().deleteTemp(path: 削除したいファイルの絶対パス) で使う
    //  引数：path: 削除したいファイルの絶対パス
    //  戻り値：なし
    func deleteTemp(path: String){
        try? FileManager.default.removeItem(atPath: path)
    }
}
