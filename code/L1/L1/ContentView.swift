//
//  ContentView.swift
//  L1
//
//  Created by Wei Zheng on 2023/9/20.
//

import SwiftUI
import RealityKit

struct ContentView: View {

    private var url = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
    
    var body: some View {
        NavigationStack {
//            Text("Hello, VisionOS")
            VStack {
                Text("Show Teapot")
                
                Model3D(url: url) { model in
                    model
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
