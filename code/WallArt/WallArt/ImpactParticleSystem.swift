//
//  ImpactParticleSystem.swift
//  WallArt
//
//  Created by Wei Zheng on 2023/9/25.
//

import Foundation
import RealityKit

struct ProjectileComponent: Component, Codable {
    public var bursted = false
    public var canBurst = false
}

struct ImpactParticleSystem: System {
    static let projectileQuery = EntityQuery(where: .has(ProjectileComponent.self))
    static let particleQuery = EntityQuery(where: .has(ParticleEmitterComponent.self))
    
    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        var iter = context.entities(matching: Self.projectileQuery, updatingSystemWhen: .rendering).makeIterator()
        guard let projectile = iter.next() else { return }
        guard var projectileComponent = projectile.components[ProjectileComponent.self] else { return }

        if !projectileComponent.bursted && projectileComponent.canBurst {
            for p in context.entities(matching: Self.particleQuery, updatingSystemWhen: .rendering) {
                if p.name == "ImpactParticle" {
                    p.components[ParticleEmitterComponent.self]?.burst()
                }
            }
            
            projectileComponent.bursted = true
            projectile.components[ProjectileComponent.self] = projectileComponent
        }
    }
}
