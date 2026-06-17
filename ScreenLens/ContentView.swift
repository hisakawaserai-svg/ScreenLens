//
//  ContentView.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//
import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var appState: AppState
    var appDelegate: AppDelegate
    
    @State private var inputQuestion: String = ""
    @State private var isSending: Bool = false
    @State private var expandedMessageID: UUID? = nil
    
    @State private var toastVisible: Bool = false
    @State private var toastMessage: String = ""
    @State private var toastTimer: Timer? = nil
    
    @State private var isShowingSettings = false
    @State private var isResizing: Bool = false
    var body: some View {
        // 画面全体のサイズを監視して、全画面（リサイズ）を検知する
        GeometryReader { outerGeometry in
            // 横幅が 900px を超えたら「全画面（または最大化）」と判定するフラグ
            let isFullScreen = outerGeometry.size.width > 900
            
            ZStack {
                // サイズに応じて背景を動的に切り替える
                (isFullScreen ? Color(red: 0.1, green: 0.1, blue: 0.12) : Color.black.opacity(0.15))
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.5), value: isFullScreen)
                
                VStack(spacing: 0) {
                    headerView
                        .background(ScreenLensVisualEffect(material: .hudWindow, blendingMode: .withinWindow))
                    
                    NeonLaserDivider()
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                if appState.messages.isEmpty {
                                    if appState.isProcessing { initialLoadingView } else { emptyStateView }
                                } else {
                                    ForEach(appState.messages) { message in
                                        messageRow(for: message)
                                            .id(message.id)
                                            .contextMenu { // 右クリックで削除メニューを出す
                                                Button("このメッセージを削除") {
                                                    if let index = appState.messages.firstIndex(where: { $0.id == message.id }) {
                                                        appState.deleteMessage(at: IndexSet(integer: index))
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                            .padding()
                            // 全画面の時はタイムラインが広がりすぎないように最大幅を制限して中央寄せする（UX向上）
                            .frame(maxWidth: isFullScreen ? 800 : .infinity)
                        }
                        // 中央寄せの配置
                        .frame(maxWidth: .infinity)
                        .onChange(of: appState.messages.count) { _ in
                            // メッセージが追加された直後のタイミング
                            if let lastId = appState.messages.last?.id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    NeonLaserDivider()
                    
                    inputAreaView
                        .background(ScreenLensVisualEffect(material: .hudWindow, blendingMode: .withinWindow))
                }
                
                // トースト表示
                if toastVisible {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text(toastMessage).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                        }
                        .padding(.vertical, 10).padding(.horizontal, 16)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 100)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    .zIndex(999)
                }
            }
                .padding(2)
                .background(Color.clear)
        }
        .frame(minWidth: 420, minHeight: 620)
        .contentShape(Rectangle())
        .sheet(isPresented: $isShowingSettings) {
            SettingsView(appState: appState)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResizeNotification)) { _ in
            isResizing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isResizing = false
            }
        }
    }
    
    // ーーー ヘッダー ーーー
    private var headerView: some View {
        HStack {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.title2)
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.5), radius: 5)
            Text("ScreenLens")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            
            if appState.isProcessing || isSending { ProgressView().scaleEffect(0.7) }
            
            HStack {
                Spacer()
                Menu {
                    Button("保存フォルダを開く", action: {
                        let tempDir = FileManager.default.temporaryDirectory
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: tempDir.path)
                    })
                    Button("キャッシュ削除", action: {
                        clearTempDirectory()
                        showToast(message: "キャッシュを削除しました")
                    })
                    Button("履歴をすべて削除", role: .destructive) {
                        withAnimation {
                            appState.deleteAllMessages()
                        }
                    }
                    Divider()
                    Button("APIキーを設定") {
                        isShowingSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
    
    // ーーー 初期画面 ーーー
    private var emptyStateView: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "sparkles").font(.system(size: 40)).foregroundColor(.white.opacity(0.2))
                Text("ここに解析結果が表示されます").font(.callout).foregroundColor(.white.opacity(0.3))
            }.padding(.top, 120)
            Spacer()
        }
    }
    
    // ーーー チャットの各行 ーーー
    private func messageRow(for message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isUser {
                Image(systemName: "sparkles").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(LinearGradient(colors: [.accentColor, Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .clipShape(Circle())
                    .padding(.top, 2)
            } else { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                if let imageUrl = message.imageUrl, let nsImage = NSImage(contentsOf: imageUrl) {
                    let isExpanded = expandedMessageID == message.id
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: isExpanded ? .infinity : 220).cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.3), radius: isExpanded ? 10 : 2)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { expandedMessageID = isExpanded ? nil : message.id }
                            }
                        if !isExpanded {
                            Button {
                                copyImageToPasteboard(image: nsImage)
                                showToast(message: "スクショをクリップボードにコピーしたよ")
                            } label: {
                                Label("画像をコピー", systemImage: "doc.on.clipboard.fill")
                                    .font(.caption2).foregroundColor(.white.opacity(0.6)).padding(.vertical, 4).padding(.horizontal, 8)
                                    .background(Color.white.opacity(0.08)).cornerRadius(4)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                if !message.text.isEmpty {
                    VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                        BoldTextParser(text: message.text)
                            .font(.system(.body, design: .rounded))
                            .font(.system(.body, design: .rounded))
                            .lineSpacing(5)
                            .textSelection(.enabled)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .foregroundColor(.white)
                            .background(
                                message.isUser ?
                                AnyView(Color.accentColor.opacity(0.9)) :
                                    AnyView(Color.black.opacity(0.4))
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(message.isUser ? 0.25 : 0.1), lineWidth: 1)
                            )
                            .drawingGroup()
                        
                        HStack(spacing: 12) {
                            if message.isUser { Spacer() }
                            
                            Button {
                                copyTextToPasteboard(text: message.text)
                                showToast(message: "返答をコピーしたよ")
                            } label: {
                                Image(systemName: "doc.on.doc").font(.caption2).foregroundColor(.white.opacity(0.3))
                            }.buttonStyle(.plain)
                            
                            Button {
                                if let index = appState.messages.firstIndex(where: { $0.id == message.id }) {
                                    withAnimation { appState.deleteMessage(at: IndexSet(integer: index)) }
                                    showToast(message: "メッセージを削除したよ")
                                }
                            } label: {
                                Image(systemName: "trash").font(.caption2).foregroundColor(.white.opacity(0.3))
                            }.buttonStyle(.plain)
                            
                            if !message.isUser { Spacer() }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            if message.isUser {
                Image(systemName: "person.fill").font(.system(size: 14)).foregroundColor(.white)
                    .frame(width: 32, height: 32).background(Color.white.opacity(0.15)).clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    .padding(.top, 2)
            }
        }
        .transition(.asymmetric(insertion: .move(edge: message.isUser ? .trailing : .leading).combined(with: .opacity), removal: .opacity))
    }

    // ーーー 入力エリア ーーー
    private var inputAreaView: some View {
        VStack(spacing: 16) {
            if let pendingUrl = appState.pendingImageUrl, let pendingImage = NSImage(contentsOf: pendingUrl) {
                HStack(spacing: 12) {
                    ZStack(alignment: .topTrailing) {
                        Image(nsImage: pendingImage).resizable().aspectRatio(contentMode: .fill).frame(width: 56, height: 56).cornerRadius(8).clipped()
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        Button {
                            try? FileManager.default.removeItem(at: pendingUrl)
                            appState.pendingImageUrl = nil
                        
                        } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.white).background(Color.black.clipShape(Circle())) }.buttonStyle(.plain).offset(x: 5, y: -5)
                    }
                    Spacer()
                    Button {
                        copyImageToPasteboard(image: pendingImage)
                        showToast(message: "画像をクリップボードにコピーしました")
                    } label: {
                        Label("コピー", systemImage: "doc.on.clipboard")
                    }
                }
                .padding(.horizontal, 16)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                Button { captureFromWindow() } label: {
                    Image(systemName: "camera.fill").font(.title3).foregroundColor(.white).padding(12)
                        .background(Color.white.opacity(0.1)).clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                }.buttonStyle(.plain)
                
                TextField("メッセージを入力...", text: $inputQuestion, axis: .vertical)
                    .textFieldStyle(.plain).lineLimit(1...5).padding(12)
                    .background(Color.black.opacity(0.6)).cornerRadius(12).foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .onSubmit { sendEverything() }
                
                Button { sendEverything() } label: {
                    Image(systemName: "paperplane.fill").font(.title3).foregroundColor(.white).padding(12)
                        .background(canSend ? Color.accentColor : Color.white.opacity(0.05)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(canSend ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1))
                }.buttonStyle(.plain).disabled(!canSend)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 16).padding(.bottom, 24)
    }
    
    private var canSend: Bool {
        // 「テキストが空ではない」 OR 「画像が存在する」
        let isInputNotEmpty = !inputQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isImagePresent = appState.pendingImageUrl != nil
        
        return (isInputNotEmpty || isImagePresent) && !isSending
    }
    
    private func captureFromWindow() {
        appDelegate.analyzeScreen(appState: appState) {
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
    private func sendEverything() {
        guard !inputQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.pendingImageUrl != nil else {
                return
            }
        let question = inputQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageUrl = appState.pendingImageUrl
        let imageToBackground = imageUrl != nil ? NSImage(contentsOf: imageUrl!) : nil
        guard canSend else { return }
        isSending = true
        inputQuestion = ""
        appState.pendingImageUrl = nil
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            appState.messages.append(ChatMessage(isUser: true, text: question, imageUrl: imageUrl))
            appState.isProcessing = true
        }
        
        Task {
            let service = GeminiService()
            do {
                let responseText = try await service.callGemini(textPrompt: question, image: imageToBackground)
                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        appState.messages.append(ChatMessage(isUser: false, text: responseText, imageUrl: nil))
                        isSending = false; appState.isProcessing = false
                    }
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        appState.messages.append(ChatMessage(isUser: false, text: "❌ エラー: \(error.localizedDescription)", imageUrl: nil))
                        isSending = false; appState.isProcessing = false
                    }
                }
            }
        }
    }
    
    private func showToast(message: String) {
        toastTimer?.invalidate()
        toastMessage = message
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { toastVisible = true }
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { toastVisible = false }
        }
    }
    
    private func copyTextToPasteboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func copyImageToPasteboard(image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    private var initialLoadingView: some View {
        HStack { Spacer(); VStack { ProgressView(); Text("解析中...") }.padding(.top, 40); Spacer() }
    }
}

struct NeonLaserDivider: View {
    var body: some View {
        // SwiftUIの再描画の罠を抜けるため、NSView（AppKit）の世界にエスケープする
        NSGradientLayerViewWrapper()
            .frame(height: 1.5)
            .shadow(color: Color(red: 0.26, green: 0.52, blue: 0.96).opacity(0.4), radius: 3, y: 0)
    }
}

// AppKitのビューをSwiftUIで使えるようにするラッパー
struct NSGradientLayerViewWrapper: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.colors = [
            NSColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0).cgColor, // 青
            NSColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1.0).cgColor, // 赤
            NSColor(red: 0.98, green: 0.74, blue: 0.02, alpha: 1.0).cgColor, // 黄
            NSColor(red: 0.20, green: 0.66, blue: 0.33, alpha: 1.0).cgColor, // 緑
            NSColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0).cgColor, // 青（2周目）
            NSColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1.0).cgColor, // 赤
            NSColor(red: 0.98, green: 0.74, blue: 0.02, alpha: 1.0).cgColor, // 黄
            NSColor(red: 0.20, green: 0.66, blue: 0.33, alpha: 1.0).cgColor, // 緑
            NSColor(red: 0.26, green: 0.52, blue: 0.96, alpha: 1.0).cgColor  // 終着点
        ]
        
        // 真横に流れるように設定
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 2.0, y: 0.5) // 横幅を2倍分持たせる
        
        // 2. GPUで直接ループ動かす最強のアニメーション（CABasicAnimation）
        let animation = CABasicAnimation(keyPath: "locations")
        
        // グラデーションの色の位置（0.0 〜 1.0）を少しずつ左にずらしていく
        animation.fromValue = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
        animation.toValue = [-0.5, -0.375, -0.25, -0.125, 0.0, 0.125, 0.25, 0.375, 0.5]
        
        animation.duration = 4.0 // 4秒かけて1ループ
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut) // なめらかに
        animation.repeatCount = .infinity // 無限ループ
        animation.isRemovedOnCompletion = false // 画面が切り替わっても破棄しない
        
        gradientLayer.locations = [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
        // レイヤーにアニメーションを追加
        gradientLayer.add(animation, forKey: "smoothGoogleScroll")
        
        // コンテナにレイヤーをセット
        containerView.wantsLayer = true
        containerView.layer = gradientLayer
        
        return containerView
    }
    
    // リサイズされた時に、グラデーションの幅も自動で追従させる
    func updateNSView(_ nsView: NSView, context: Context) {
        CATransaction.begin()
        CATransaction.setDisableActions(true) // リサイズ時のカクツキを防止
        nsView.layer?.frame = nsView.bounds
        CATransaction.commit()
    }
}

// エラー解消のために追加：macOS用のすりガラス（VisualEffect）のラッパー
struct ScreenLensVisualEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

func clearTempDirectory() {
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory
    
    do {
        let fileURLs = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        for url in fileURLs {
            // 「ScreenLens_2026...」のような名前のファイルだけが対象になる
            if url.lastPathComponent.hasPrefix("ScreenLens_") {
                try fileManager.removeItem(at: url)
            }
        }
    } catch {
        print("キャッシュ削除失敗: \(error)")
    }
}

// 設定用のViewパーツ
struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Gemini API 設定")) {
                SecureField("Gemini API Key", text: $appState.apiKey)
                Text("入力されたキーはローカルに安全に保存されます。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 400, height: 150)
        .toolbar {
            Button("閉じる") { dismiss() }
        }
    }
}

// Markdown風の太字（**text**）を解析して表示するコンポーネント
struct BoldTextParser: View {
    let text: String
    
    var body: some View {
        Text(parseToAttributedString(text))
    }
    
    private func parseToAttributedString(_ input: String) -> AttributedString {
        var fullString = AttributedString()
        let parts = input.components(separatedBy: "**")
        
        for (index, part) in parts.enumerated() {
            var attributedPart = AttributedString(part)
            
            // 奇数番目（**で囲まれた部分）を太字にする
            if index % 2 != 0 {
                attributedPart.font = .system(.body, design: .rounded).bold()
                attributedPart.underlineStyle = .single
            } else {
                attributedPart.font = .system(.body, design: .rounded)
            }
            
            fullString.append(attributedPart)
        }
        return fullString
    }
}
