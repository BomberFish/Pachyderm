//
//  GlassPolyfill.swift
//  Pachyderm
//
//  Created by Hariz Shirazi on 2025-07-25.
//

import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder func glassButton() -> some View {
        if #available(iOS 19.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
    
    @ViewBuilder func glassProminentButton() -> some View {
        if #available(iOS 19.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder func glass(isEnabled: Bool = true) -> some View {
        if isEnabled {
            if #available(iOS 19.0, *) {
                self.glassEffect()
            } else {
                self.background(.thinMaterial)
            }
        } else {
            self
        }
    }
    
    @ViewBuilder func glassCapsule(isEnabled: Bool = true) -> some View {
        if isEnabled {
            if #available(iOS 19.0, *) {
                self.glassEffect(in: .capsule)
            } else {
                self.background(.thinMaterial, in: .capsule)
            }
        } else {
            self
        }
    }
}

extension ToolbarContent {
    func noSharedBackground() -> ToolbarContent {
        if #available(iOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self as ToolbarContent
        }
    }
}

