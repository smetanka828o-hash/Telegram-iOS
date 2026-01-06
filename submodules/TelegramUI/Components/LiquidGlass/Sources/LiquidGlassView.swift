import Foundation
import UIKit
import Display
import ComponentFlow
import GlassBackgroundComponent

public final class LiquidGlassView: UIView {
    public struct Params: Equatable {
        public var size: CGSize
        public var cornerRadius: CGFloat
        public var isDark: Bool
        public var tintColor: GlassBackgroundView.TintColor
        public var isInteractive: Bool
        public var isVisible: Bool

        public init(size: CGSize, cornerRadius: CGFloat, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool, isVisible: Bool) {
            self.size = size
            self.cornerRadius = cornerRadius
            self.isDark = isDark
            self.tintColor = tintColor
            self.isInteractive = isInteractive
            self.isVisible = isVisible
        }
    }

    public let contentView: UIView
    private let backgroundView: GlassBackgroundView
    private let fallbackView: UIView
    private let highlightView: UIView
    private let highlightLayer: CAGradientLayer
    private let rimLayer: CAShapeLayer

    private var highlightShift: CGPoint = .zero
    private var params: Params?
    private var isHighlighted: Bool = false

    public override init(frame: CGRect) {
        self.contentView = UIView()
        self.backgroundView = GlassBackgroundView()
        self.fallbackView = UIView()
        self.highlightView = UIView()
        self.highlightLayer = CAGradientLayer()
        self.rimLayer = CAShapeLayer()

        super.init(frame: frame)

        self.addSubview(self.backgroundView)
        self.addSubview(self.fallbackView)
        self.addSubview(self.highlightView)
        self.addSubview(self.contentView)

        self.fallbackView.isHidden = true
        self.highlightView.isUserInteractionEnabled = false

        self.highlightView.layer.addSublayer(self.highlightLayer)

        self.rimLayer.fillColor = UIColor.clear.cgColor
        self.rimLayer.lineWidth = 1.0
        self.layer.addSublayer(self.rimLayer)

        self.clipsToBounds = false
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(size: CGSize, cornerRadius: CGFloat, isDark: Bool, tintColor: GlassBackgroundView.TintColor, isInteractive: Bool = false, isVisible: Bool = true, transition: ComponentTransition) {
        let params = Params(size: size, cornerRadius: cornerRadius, isDark: isDark, tintColor: tintColor, isInteractive: isInteractive, isVisible: isVisible)
        if self.params == params {
            return
        }
        self.params = params

        transition.setFrame(view: self.backgroundView, frame: CGRect(origin: .zero, size: size))
        transition.setFrame(view: self.fallbackView, frame: CGRect(origin: .zero, size: size))
        transition.setFrame(view: self.highlightView, frame: CGRect(origin: .zero, size: size))
        transition.setFrame(view: self.contentView, frame: CGRect(origin: .zero, size: size))
        transition.setCornerRadius(layer: self.backgroundView.layer, cornerRadius: cornerRadius)
        transition.setCornerRadius(layer: self.fallbackView.layer, cornerRadius: cornerRadius)
        transition.setCornerRadius(layer: self.highlightView.layer, cornerRadius: cornerRadius)
        transition.setCornerRadius(layer: self.contentView.layer, cornerRadius: cornerRadius)

        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
        let effectiveVisible = isVisible && !reduceTransparency

        self.backgroundView.update(
            size: size,
            cornerRadius: cornerRadius,
            isDark: isDark,
            tintColor: tintColor,
            isInteractive: isInteractive,
            isVisible: effectiveVisible,
            transition: transition
        )

        self.fallbackView.isHidden = effectiveVisible
        self.fallbackView.backgroundColor = tintColor.color.withMultipliedAlpha(isDark ? 0.6 : 0.75)

        self.updateHighlightLayer(size: size, cornerRadius: cornerRadius, isDark: isDark)
        self.applyHighlightShift()
        self.updateRim(size: size, cornerRadius: cornerRadius, isDark: isDark)

        self.updateHighlightAppearance(animated: !transition.animation.isImmediate)
    }

    public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if self.isHighlighted == highlighted {
            return
        }
        self.isHighlighted = highlighted
        self.updateHighlightAppearance(animated: animated)
    }

    public func setHighlightShift(_ shift: CGPoint) {
        let clamped = CGPoint(
            x: max(-1.0, min(1.0, shift.x)),
            y: max(-1.0, min(1.0, shift.y))
        )
        if self.highlightShift == clamped {
            return
        }
        self.highlightShift = clamped
        self.applyHighlightShift()
    }

    private func updateHighlightAppearance(animated: Bool) {
        let targetAlpha: CGFloat
        if self.isHighlighted {
            targetAlpha = 0.7
        } else {
            targetAlpha = 0.2
        }

        if animated && !UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseInOut, .allowUserInteraction]) {
                self.highlightView.alpha = targetAlpha
            }
        } else {
            self.highlightView.alpha = targetAlpha
        }
    }

    private func updateHighlightLayer(size: CGSize, cornerRadius: CGFloat, isDark: Bool) {
        let highlightColor = UIColor(white: 1.0, alpha: isDark ? 0.45 : 0.35)
        let clearColor = UIColor(white: 1.0, alpha: 0.0)

        self.highlightLayer.colors = [highlightColor.cgColor, clearColor.cgColor]
        self.highlightLayer.locations = [0.0, 1.0]
        self.highlightLayer.frame = CGRect(origin: .zero, size: size)
        self.highlightLayer.cornerRadius = cornerRadius
    }

    private func applyHighlightShift() {
        let baseStart = CGPoint(x: 0.2, y: 0.0)
        let baseEnd = CGPoint(x: 0.8, y: 1.0)
        let shiftX = self.highlightShift.x * 0.15
        let shiftY = self.highlightShift.y * 0.15

        self.highlightLayer.startPoint = CGPoint(x: baseStart.x + shiftX, y: baseStart.y + shiftY)
        self.highlightLayer.endPoint = CGPoint(x: baseEnd.x + shiftX, y: baseEnd.y + shiftY)
    }

    private func updateRim(size: CGSize, cornerRadius: CGFloat, isDark: Bool) {
        let rimColor = isDark ? UIColor(white: 1.0, alpha: 0.18) : UIColor(white: 1.0, alpha: 0.12)
        self.rimLayer.strokeColor = rimColor.cgColor
        self.rimLayer.frame = CGRect(origin: .zero, size: size)
        self.rimLayer.path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5), cornerRadius: cornerRadius).cgPath
    }
}
