//
//  CenterLayout.swift
//  PlacementDemo
//
//  Created by Sam Pettersson on 2022-09-17.
//

import Foundation
import SwiftUI
import Placement

public struct CenterLayout: PlacementLayout {
    var nativeImplementation: Bool
    
    public func sizeThatFits(
        proposal: PlacementProposedViewSize,
        subviews: PlacementLayoutSubviews,
        cache: inout ()
    ) -> CGSize {
        return CGSize(
            width: proposal.width ?? 0,
            height: proposal.height ?? 0
        )
    }
    
    public func placeSubviews(
        in bounds: CGRect,
        proposal: PlacementProposedViewSize,
        subviews: PlacementLayoutSubviews,
        cache: inout ()
    ) {        
        for index in subviews.indices {
            let subview = subviews[index]
            let dimension = subview.dimensions(in: proposal)

            subview.place(
                at: CGPoint(x: bounds.midX, y: bounds.midY),
                anchor: .center,
                proposal: PlacementProposedViewSize(width: dimension.width, height: dimension.height)
            )
        }
    }
    
    public var prefersLayoutProtocol: Bool {
        nativeImplementation
    }
}

struct NativeAnchorPreference: PreferenceKey {
  static var defaultValue: Anchor<CGRect>?

  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    if let nextValue = nextValue() {
      print("Native reduce new value")
      value = nextValue
    }
  }
}

struct PlacementAnchorPreference: PreferenceKey {
  static var defaultValue: Anchor<CGRect>?

  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    // Using the following will use wrong position:
//    value = nextValue()
    if value == nil, let newValue = nextValue() {
      print("Placement reduce new value")
      value = newValue
    }
  }
}

struct CenterLayoutDemo: View {
    @State var changeLayout = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Layout below uses SwiftUI.Layout (on iOS 16)")
                
                CenterLayout(nativeImplementation: true) {
                    Text("View 1")
                        .padding(changeLayout ? 10 : 20)
                        .border(.red)
                        .anchorPreference(key: NativeAnchorPreference.self, value: .bounds) { $0 }
                }
                .overlayPreferenceValue(NativeAnchorPreference.self, { value in
                  GeometryReader { proxy in
                    if let value {
                      let rect = proxy[value]
                      let _ = print("Native rect: \(rect)")
                      Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .offset(x: rect.origin.x, y: rect.origin.y)
                        .frame(width: rect.width, height: rect.height)
                    }
                  }
                })
                .border(.blue)
                .padding()
                .frame(width: 300, height: 200)
                
                Text("Layout below uses Placement")
                
                CenterLayout(nativeImplementation: false) {
                    Text("View 1")
                        .padding(changeLayout ? 10 : 20)
                        .border(.red)
                        .anchorPreference(key: PlacementAnchorPreference.self, value: .bounds) { $0 }
                }
                .overlayPreferenceValue(PlacementAnchorPreference.self, { value in
                  GeometryReader { proxy in
                    if let value {
                      let rect = proxy[value]
                      let _ = print("Placement rect: \(rect)")
                      Rectangle()
                        .fill(Color.green.opacity(0.5))
                        .offset(x: rect.origin.x, y: rect.origin.y)
                        .frame(width: rect.width, height: rect.height)
                    }
                    Text("Overlay")
                  }
                })
                .border(.blue)
                .padding()
                .frame(width: 300, height: changeLayout ? 150 : 200)
                
                Button("Change layout") {
                    withAnimation(.spring()) {
                        changeLayout.toggle()
                    }
                }
            }
        }
    }
}
