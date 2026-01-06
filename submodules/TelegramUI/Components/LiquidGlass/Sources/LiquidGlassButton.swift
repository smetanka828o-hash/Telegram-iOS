import Foundation
import UIKit
import Display
import ComponentFlow
import GlassBackgroundComponent

public final class LiquidGlassButton: UIControl, UIGestureRecognizerDelegate {
    public let glassView: LiquidGlassView
    public let contentView: UIView
    public let interactionAnimator: LiquidGlassInteractionAnimator

    public var allowsScale: Bool {
        didSet {
            self.interactionAnimator.allowsScale = self.allowsScale
        }
    }

    public var allowsStretch: Bool {
        didSet {
            self.interactionAnimator.allowsStretch = self.allowsStretch
        }
    }

    public var scaleTargetView: UIView? {
        didSet {
            self.interactionAnimator.scaleTargetView = self.scaleTargetView
        }
    }

    public var stretchTargetView: UIView? {
        didSet {
            self.interactionAnimator.stretchTargetView = self.stretchTargetView
        }
    }

    private var boundGesture: UIPanGestureRecognizer?

    public override init(frame: CGRect) {
        self.glassView = LiquidGlassView()
        self.contentView = UIView()
        self.interactionAnimator = LiquidGlassInteractionAnimator()
        self.allowsScale = true
        self.allowsStretch = true

        super.init(frame: frame)

        self.addSubview(self.glassView)
        self.addSubview(self.contentView)

        self.interactionAnimator.glassView = self.glassView
        self.interactionAnimator.scaleTargetView = self
        self.interactionAnimator.stretchTargetView = self.glassView

        self.clipsToBounds = false
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(size: CGSize, cornerRadius: CGFloat, isDark: Bool, tintColor: GlassBackgroundView.TintColor, transition: ComponentTransition) {
        transition.setFrame(view: self.glassView, frame: CGRect(origin: .zero, size: size))
        transition.setFrame(view: self.contentView, frame: CGRect(origin: .zero, size: size))
        self.glassView.update(size: size, cornerRadius: cornerRadius, isDark: isDark, tintColor: tintColor, isInteractive: false, transition: transition)
    }

    public func setHighlighted(_ highlighted: Bool, animated: Bool) {
        self.interactionAnimator.setHighlighted(highlighted, animated: animated)
    }

    public func bounce() {
        self.interactionAnimator.bounce()
    }

    public func bindStretch(to view: UIView) {
        if let boundGesture = self.boundGesture {
            view.removeGestureRecognizer(boundGesture)
        }
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.handleBoundGesture(_:)))
        gesture.maximumNumberOfTouches = 1
        gesture.cancelsTouchesInView = false
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
        self.boundGesture = gesture
    }

    public func unbindStretch(from view: UIView) {
        if let boundGesture = self.boundGesture {
            view.removeGestureRecognizer(boundGesture)
            self.boundGesture = nil
        }
    }

    @objc private func handleBoundGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        switch gesture.state {
        case .began:
            self.interactionAnimator.setHighlighted(true, animated: true)
            self.interactionAnimator.updateStretch(location: location, in: self.bounds)
        case .changed:
            self.interactionAnimator.updateStretch(location: location, in: self.bounds)
        case .ended, .cancelled, .failed:
            self.interactionAnimator.setHighlighted(false, animated: true)
            self.interactionAnimator.resetStretch(animated: true)
        default:
            break
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
