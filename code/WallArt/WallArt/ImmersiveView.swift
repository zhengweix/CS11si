//
//  ImmersiveView.swift
//  WallArt
//
//  Created by Wei Zheng on 2023/9/22.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine

struct ImmersiveView: View {
    
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow
    
    private static let planeX: Float = 1.43
    private static let planeZ: Float = 1.0
    
    @State private var inputText = ""
    @State public var showTextField = false
    
    @State private var assistant: Entity? = nil
    @State private var waveAnimation: AnimationResource? = nil
    @State private var jumpAnimation: AnimationResource? = nil
    
    @State private var projectile: Entity? = nil
    
    @State public var showAttachmentButtons = false
    
    let tapSubject = PassthroughSubject<Void, Never>()
    @State var cancellable: AnyCancellable?
    
    @State var characterEntity: Entity = {
        let headAnchor = AnchorEntity(.head)
        headAnchor.position = [0.70, -0.35, -1]
        let radians = -30 * Float.pi / 180
        ImmersiveView.rotateEntityAroundYAxis(entity: headAnchor, angle: radians)
        return headAnchor
    }()
    
    @State var planeEntity: Entity = {
        let wallAnchor = AnchorEntity(.plane(.vertical, classification: .wall, minimumBounds: SIMD2<Float>(0.6, 0.6)))
        let planeMesh = MeshResource.generatePlane(width: planeX, depth: planeZ, cornerRadius: 0.1)
        let material = ImmersiveView.loadImageMaterial(imageUrl: "think_different")
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [material])
        planeEntity.name = "canvas"
        wallAnchor.addChild(planeEntity)
        return wallAnchor
    }()
    
    var body: some View {
        RealityView { content, attachments in
            do {
                let immersiveEntity = try await Entity(named: "Immersive", in: realityKitContentBundle)
                characterEntity.addChild(immersiveEntity)
                content.add(characterEntity)
                content.add(planeEntity)
                
                guard let attachmentEntity = attachments.entity(for: "attachment") else { return }
                attachmentEntity.position = SIMD3<Float>(0, 0.62, 0)
                let radians = 30 * Float.pi / 180
                ImmersiveView.rotateEntityAroundYAxis(entity: attachmentEntity, angle: radians)
                characterEntity.addChild(attachmentEntity)
                
                let characterAnimationSceneEntity = try await Entity(named: "CharacterAnimations", in: realityKitContentBundle)
                guard let waveModel = characterAnimationSceneEntity.findEntity(named: "wave_model") else { return }
                guard let jumpUpModel = characterAnimationSceneEntity.findEntity(named: "jump_up_model") else { return }
                guard let jumpFloatModel = characterAnimationSceneEntity.findEntity(named: "jump_float_model") else { return }
                guard let jumpDownModel = characterAnimationSceneEntity.findEntity(named: "jump_down_model") else { return }
                guard let assistant = characterEntity.findEntity(named: "assistant") else { return }
                guard let idleAnimationResource = assistant.availableAnimations.first else { return }
                guard let waveAnimationResource = waveModel.availableAnimations.first else { return }
                let waveAnimation = try AnimationResource.sequence(with: [waveAnimationResource, idleAnimationResource.repeat()])
                assistant.playAnimation(idleAnimationResource.repeat())
                
                let projectileSceneEntity = try await Entity(named: "MainParticle", in: realityKitContentBundle)
                guard let projectile = projectileSceneEntity.findEntity(named: "ParticleRoot") else { return }
                projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = false
                projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = false
                projectile.components.set(ProjectileComponent())
                characterEntity.addChild(projectile)
                
                let impactParticleSceneEntity = try await Entity(named: "ImpactParticle", in: realityKitContentBundle)
                guard let impactParticle = impactParticleSceneEntity.findEntity(named: "ImpactParticle") else { return }
                impactParticle.position = [0, 0, 0]
                impactParticle.components[ParticleEmitterComponent.self]?.burstCount = 500
                impactParticle.components[ParticleEmitterComponent.self]?.emitterShapeSize.x = Self.planeX / 2.0
                impactParticle.components[ParticleEmitterComponent.self]?.emitterShapeSize.z = Self.planeZ / 2.0
                planeEntity.addChild(impactParticle)
                
                guard let jumpUpAnimationResource = jumpUpModel.availableAnimations.first else { return }
                guard let jumpFloatAnimationResource = jumpFloatModel.availableAnimations.first else { return }
                guard let jumpDownAnimationResource = jumpDownModel.availableAnimations.first else { return }
                let jumpAnimation = try AnimationResource.sequence(with: [jumpUpAnimationResource, jumpFloatAnimationResource, jumpDownAnimationResource, idleAnimationResource.repeat()])
                assistant.playAnimation(idleAnimationResource.repeat())
                
                Task {
                    self.assistant = assistant
                    self.waveAnimation = waveAnimation
                    self.jumpAnimation = jumpAnimation
                    self.projectile = projectile
                }
            } catch {
                print("Error in RealityView's make: \(error)")
            }
        } attachments: {
            Attachment(id: "attachment") {
                VStack {
                    Text(inputText)
                        .frame(maxWidth: 600, alignment: .leading)
                        .font(.extraLargeTitle2)
                        .fontWeight(.regular)
                        .padding(40)
                        .glassBackgroundEffect()
                }
                .opacity(showTextField ? 1 : 0)
                
                if showAttachmentButtons {
                    HStack(spacing: 20) {
                        Button(action: {
                            tapSubject.send()
                        }) {
                            Text("Yes, let's go!")
                                .font(.largeTitle)
                                .fontWeight(.regular)
                                .padding()
                                .cornerRadius(8)
                        }
                        .padding()
                        .buttonStyle(.bordered)

                        Button(action: {
                            // Action for No button
                        }) {
                            Text("No")
                                .font(.largeTitle)
                                .fontWeight(.regular)
                                .padding()
                                .cornerRadius(8)
                        }
                        .padding()
                        .buttonStyle(.bordered)
                    }
                    .glassBackgroundEffect()
                    .opacity(showAttachmentButtons ? 1 : 0)
                }
            }
        }
        .gesture(SpatialTapGesture().targetedToAnyEntity().onEnded { _ in
            viewModel.flowState = .intro
        })
        .onChange(of: viewModel.flowState) { _, newValue in
            switch newValue {
            case .idle:
                break
            case .intro:
                playIntroSequence()
            case .projectileFlying:
                if let projectile = self.projectile {
                    let dest = Transform(scale: projectile.transform.scale, rotation: projectile.transform.rotation,
                                         translation: [-0.7, 0.15, -0.5] * 2)
                    Task {
                        let duration = 3.0
                        projectile.position = [0, 0.1, 0]
                        projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = true
                        projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = true
                        projectile.move(to: dest, relativeTo: self.characterEntity, duration: duration, timingFunction: .easeInOut)
                        try? await Task.sleep(for: .seconds(duration))
                        projectile.children[0].components[ParticleEmitterComponent.self]?.isEmitting = false
                        projectile.children[1].components[ParticleEmitterComponent.self]?.isEmitting = false
                        viewModel.flowState = .updateWallArt
                    }
                }
            case .updateWallArt:
                self.projectile?.components[ProjectileComponent.self]?.canBurst = true
                
                if let plane = planeEntity.findEntity(named: "canvas") as? ModelEntity {
                    plane.model?.materials = [ImmersiveView.loadImageMaterial(imageUrl: "sketch")]
                }
                if let assistant = self.assistant, let jumpAnimation = self.jumpAnimation {
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        assistant.playAnimation(jumpAnimation)
                        await animatePromptText(text: "Awesome!")
                        try? await Task.sleep(for: .milliseconds(500))
                        await animatePromptText(text: "What else do you want to see us\n build in Vision Pro?")
                    }
                }
                break
            }
        }
    }
    
    func waitForButtonTap(using buttonTapPublisher: PassthroughSubject<Void, Never>) async {
        await withCheckedContinuation { continuation in
            let cancellable = tapSubject.first().sink(receiveValue: { _ in
                continuation.resume()
            })
            self.cancellable = cancellable
        }
    }
    
    func animatePromptText(text: String) async {
        // Type out the title.
        inputText = ""
        let words = text.split(separator: " ")
        for word in words {
            inputText.append(word + " ")
            let milliseconds = (1 + UInt64.random(in: 0 ... 1)) * 100
            try? await Task.sleep(for: .milliseconds(milliseconds))
        }
    }
    
    func playIntroSequence() {
        Task {
            // show dialog box
            if !showTextField {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTextField.toggle()
                }
            }
            
            if let assistant = self.assistant, let waveAnimation = self.waveAnimation {
                await assistant.playAnimation(waveAnimation.repeat(count: 1))
            }
            
            let texts = [
                "Hey :) Let’s create some doodle art\n with the Vision Pro. Are you ready?",
                "Awesome. Draw something and\n watch it come alive.",
            ]
            
            await animatePromptText(text: texts[0])
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showAttachmentButtons = true
            }
            
            await waitForButtonTap(using: tapSubject)
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showAttachmentButtons = false
            }
            
            Task {
                await animatePromptText(text: texts[1])
            }
            
            DispatchQueue.main.async {
                openWindow(id: "doodle_canvas")
            }
        }
    }
    
    static func rotateEntityAroundYAxis(entity: Entity, angle: Float) {
        var currentTransform = entity.transform

        let rotation = simd_quatf(angle: angle, axis: [0, 1, 0])

        currentTransform.rotation = rotation * currentTransform.rotation

        entity.transform = currentTransform
    }
    static func loadImageMaterial(imageUrl: String) -> SimpleMaterial {
        do {
            let texture = try TextureResource.load(named: imageUrl)
            var material = SimpleMaterial()
            let color = SimpleMaterial.BaseColor(texture: MaterialParameters.Texture(texture))
            material.color = color
            return material
        } catch {
            fatalError(String(describing: error))
        }
    }
}
