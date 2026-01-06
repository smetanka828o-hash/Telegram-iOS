import Foundation
import UIKit

public final class LiquidGlassInteractionAnimator {
    public weak var glassView: LiquidGlassView?
    public weak var scaleTargetView: UIView?
    public weak var stretchTargetView: UIView?

    public var allowsScale: Bool = true
    public var allowsStretch: Bool = true
    public var highlightScale: CGFloat = 1.06
    public var stretchAmount: CGFloat = 0.12

    private var isHighlighted: Bool = false

    public init() {
    }

    public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if self.isHighlighted == highlighted {
            return
        }
        self.isHighlighted = highlighted

        self.glassView?.setHighlighted(highlighted, animated: animated)

        guard let scaleTargetView = self.scaleTargetView, self.allowsScale else {
            return
        }

        let targetScale: CGFloat = highlighted ? self.highlightScale : 1.0
        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: highlighted ? 0.16 : 0.22, delay: 0.0, usingSpringWithDamping: highlighted ? 0.8 : 0.9, initialSpringVelocity: 0.0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                scaleTargetView.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
            }
        } else {
            scaleTargetView.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
        }
    }

    public func updateStretch(location: CGPoint, in bounds: CGRect, animated: Bool = false) {
        guard let stretchTargetView = self.stretchTargetView, self.allowsStretch else {
            return
        }
        guard bounds.width > 0.0, bounds.height > 0.0 else {
            return
        }

        let dx = (location.x - bounds.midX) / (bounds.width * 0.5)
        let dy = (location.y - bounds.midY) / (bounds.height * 0.5)
        let magnitude = min(1.0, sqrt(dx * dx + dy * dy))
        let stretch = self.stretchAmount * magnitude

        let scaleX = 1.0 + stretch * abs(dx)
        let scaleY = 1.0 + stretch * abs(dy)
        let translateX = dx * 2.0
        let translateY = dy * 2.0

        let transform = CGAffineTransform(translationX: translateX, y: translateY).scaledBy(x: scaleX, y: scaleY)

        self.glassView?.setHighlightShift(CGPoint(x: dx, y: dy))

        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.12, delay: 0.0, options: [.allowUserInteraction, .curveEaseOut]) {
                stretchTargetView.transform = transform
            }
        } else {
            stretchTargetView.transform = transform
        }
    }

    public func resetStretch(animated: Bool) {
        guard let stretchTargetView = self.stretchTargetView else {
            return
        }

        self.glassView?.setHighlightShift(.zero)

        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                stretchTargetView.transform = .identity
            }
        } else {
            stretchTargetView.transform = .identity
        }
    }

    public func bounce() {
        guard let scaleTargetView = self.scaleTargetView, self.allowsScale else {
            return
        }
        if UIAccessibility.isReduceMotionEnabled {
            scaleTargetView.transform = .identity
            return
        }

        let overshoot: CGFloat = 1.12
        UIView.animate(withDuration: 0.12, delay: 0.0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            scaleTargetView.transform = CGAffineTransform(scaleX: overshoot, y: overshoot)
        } completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: [.allowUserInteraction, .beginFromCurrentState]) {
                scaleTargetView.transform = .identity
            }
        }
    }
}
