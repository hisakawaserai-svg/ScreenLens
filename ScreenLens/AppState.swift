//
//  AppState.swift
//  ScreenLens
//
//  Created by h S. on 2026/05/11.
//
import Foundation
import Combine

class AppState: ObservableObject {
    @Published var result: String = ""
    @Published var showWindow: Bool = false
}
