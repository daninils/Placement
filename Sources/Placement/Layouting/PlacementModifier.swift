import Foundation
import SwiftUI

struct PlacementEffect: GeometryEffect {
    var positionX: CGFloat
    var positionY: CGFloat
    var anchorX: CGFloat
    var anchorY: CGFloat
    
    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
           AnimatablePair(AnimatablePair(positionX, positionY), AnimatablePair(anchorX, anchorY))
        }

        set {
            positionX = newValue.first.first
            positionY = newValue.first.second
            anchorX = newValue.second.first
            anchorY = newValue.second.second
        }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let anchorPointY = size.height * anchorY
        let translationY = positionY - anchorPointY
        let anchorPointX = size.width * anchorX
        let translationX = positionX - anchorPointX
                                                                
        return ProjectionTransform(CGAffineTransform(
            translationX: translationX,
            y: translationY
        ))
    }
}

struct PlaceHostingController<L: PlacementLayout>: UIViewRepresentable {
    @EnvironmentObject var coordinator: Coordinator<L>
    var id: AnyHashable
    var placement: LayoutPlacement?
    
    func makeUIView(context: Context) -> UIView {
        coordinator.makeHostingController(id: id).view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.isHidden = true
    }
    
    func _overrideSizeThatFits(
        _ size: inout CoreGraphics.CGSize,
        in proposedSize: SwiftUI._ProposedSize,
        uiView: UIView
    ) {
        size = placement?.proposal.replacingUnspecifiedDimensions(by: .zero) ?? .zero
    }
}

struct PlacementIntrinsicSizesPreferenceKey: PreferenceKey {
    typealias Value = [AnyHashable: CGSize]

    static var defaultValue: Value = [:]

    static func reduce(
        value: inout Value,
        nextValue: () -> Value
    ) {
        value = value.merging(nextValue()) { _, rhs in
            rhs
        }
    }
}

struct PlacementModifier<L: PlacementLayout>: ViewModifier {
    @EnvironmentObject var coordinator: Coordinator<L>
    @EnvironmentObject var placementsCoordinator: PlacementsCoordinator
    var id: AnyHashable
    var layout: L
    var children: _VariadicView.Children
    
    func body(content: Content) -> some View {
        let placement = placementsCoordinator.placements[id]
        
        LayoutChildSizingView(
            layout: layout,
            id: id,
            children: children
        )
        .overlay(
                content
                .background(
                    GeometryReader(content: { proxy in
                        Color.clear.preference(
                            key: PlacementIntrinsicSizesPreferenceKey.self,
                            value: [id: proxy.size]
                        )
                    }).animation(nil)
                )
                .transaction { transaction in
                    coordinator.transaction = transaction
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
        )
        .overlay(
            PlaceHostingController<L>(
                id: id,
                placement: placement
            )
            .opacity(0)
            .allowsHitTesting(false)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        )
        .modifier(
            PlacementEffect(
                positionX: (placement?.position.x ?? 0) - (coordinator.globalFrame?.origin.x ?? 0),
                positionY: (placement?.position.y ?? 0) - (coordinator.globalFrame?.origin.y ?? 0),
                anchorX: placement?.anchor.x ?? 0,
                anchorY: placement?.anchor.y ?? 0
            )
        )
    }
}
