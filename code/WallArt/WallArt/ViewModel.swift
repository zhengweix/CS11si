//
//  ViewModel.swift
//  WallArt
//
//  Created by Wei Zheng on 2023/9/23.
//

import Foundation

enum FlowState {
    case idle
    case intro
    case projectileFlying
    case updateWallArt
}

@Observable
class ViewModel {
    
    var flowState = FlowState.idle
    
}
