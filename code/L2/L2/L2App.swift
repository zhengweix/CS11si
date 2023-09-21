//
//  L2App.swift
//  L2
//
//  Created by Wei Zheng on 2023/9/20.
//

import SwiftUI

@main
struct L2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}
