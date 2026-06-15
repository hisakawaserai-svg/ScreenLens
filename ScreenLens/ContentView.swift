//
//  ContentView.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/10.
//

import SwiftUI

struct ContentView: View {
    var appState: AppState
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("ScreenLens")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            ScrollView {
                Text(appState.result.isEmpty ? "ここに解析結果が表示されます" : appState.result)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity,  alignment: .leading)
            }
            
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(appState.result, forType: .string)
            } label: {
                Label("コピー", systemImage: "doc.on.doc")
            }
            .padding()
        }
    }
}

#Preview {
    ContentView(appState: AppState())
}
