//
//  FindMaimaiDXApp.swift
//  FindMaimaiDX
//
//  Created by Spasol Reisa on 2025/1/18.
//

import SwiftUI

@main
struct FindMaimaiDXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // 这里可以处理 URL 打开逻辑，但因为我们在 PaikaView 中处理了 onOpenURL，这里主要是返回 true
        return true
    }
}
