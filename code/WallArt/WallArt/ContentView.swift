//
//  ContentView.swift
//  WallArt
//
//  Created by Wei Zheng on 2023/9/22.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        VStack(alignment: .leading) {
            Text("Welcome to CS11si in Vision Pro")
                .font(.extraLargeTitle2)
        }
        .padding(50)
        .glassBackgroundEffect()
        .onAppear {
            Task {
                await openImmersiveSpace(id: "ImmersiveSpace")
            }
        }
    }
}
