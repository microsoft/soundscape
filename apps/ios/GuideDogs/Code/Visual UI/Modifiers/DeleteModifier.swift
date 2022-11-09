//
//  DeleteModifier.swift
//  Soundscape
//
//  Copyright (c) Microsoft Corporation.
//  Licensed under the MIT License.
//

import SwiftUI

struct Delete: ViewModifier {
    @ScaledMetric(relativeTo: .title) var iconSize: CGFloat = 24.0
    
    let action: () -> Void
    
    @State var offset: CGSize = .zero
    @State var initialOffset: CGSize = .zero
    @State var contentWidth: CGFloat = 0.0
    @State var deletionDistance: CGFloat = 80.0
    @State var waitingForMinGesture = true
    @State var willDeleteIfReleased = false
    
    // MARK: Constants
    
    let minGetureWidth: CGFloat = -40.0
    let tappableDeletionWidth: CGFloat = -80.0
    let deletionSkipLength: CGFloat = 60.0
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    ZStack(alignment: .trailing) {
                        Rectangle()
                            .foregroundColor(.red)
                        
                        Image(systemName: "trash")
                            .frame(height: iconSize)
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .accessibilityHidden(true)
                    .frame(width: -offset.width)
                    .offset(x: geometry.size.width)
                    .onAppear {
                        contentWidth = geometry.size.width
                        deletionDistance -= contentWidth
                    }
                    .gesture(TapGesture().onEnded { delete() })
                }
            )
            .offset(x: offset.width, y: 0)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if waitingForMinGesture && gesture.translation.width > minGetureWidth {
                            return
                        } else if waitingForMinGesture && gesture.translation.width < minGetureWidth {
                            waitingForMinGesture = false
                            offset.width = gesture.translation.width + initialOffset.width + minGetureWidth
                        } else if gesture.translation.width + initialOffset.width <= 0 {
                            offset.width = gesture.translation.width + initialOffset.width
                        }
                        
                        if self.offset.width < deletionDistance && !willDeleteIfReleased {
                            // Trigger haptic feedback and jump the offset further along
                            // to the left
                            hapticFeedback()
                            willDeleteIfReleased = true
                            initialOffset.width -= deletionSkipLength
                            offset.width -= deletionSkipLength
                        } else if offset.width > deletionDistance && willDeleteIfReleased {
                            hapticFeedback()
                            willDeleteIfReleased = false
                        }
                    }
                    .onEnded { _ in
                        if offset.width < deletionDistance {
                            delete()
                        } else if offset.width < tappableDeletionWidth {
                            offset.width = tappableDeletionWidth
                            initialOffset.width = tappableDeletionWidth
                        } else {
                            offset = .zero
                            initialOffset = .zero
                        }
                        waitingForMinGesture = true
                    }
            )
            .animation(.interactiveSpring())
    }
    
    private func delete() {
        offset.width = -contentWidth
        action()
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

extension View {
    
    func onDelete(perform action: @escaping () -> Void) -> some View {
        self.modifier(Delete(action: action))
    }
    
}
