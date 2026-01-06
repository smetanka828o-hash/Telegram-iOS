import Foundation
import UIKit
import Display
import ComponentFlow
import GlassBackgroundComponent

public final class LiquidGlassLensView: UIView {
    public struct Params: Equatable {
        public var size: CGSize
        public var selectionOrigin: CGPoint
        public var selectionSize: CGSize
        public var inset: CGFloat
        public var liftedInset: CGFloat
        public var isDark: Bool
        public var isLifted: Bool
        public var isCollapsed: Bool

        public init(size: CGSize, selectionOrigin: CGPoint, selectionSize: CGSize, inset: CGFloat, liftedInset: CGFloat, isDark: Bool, isLifted: Bool, isCollapsed: Bool) {
            self.size = size
            self.selectionOrigin = selectionOrigin
            self.selectionSize = selectionSize
            self.inset = inset
            self.liftedInset = liftedInset
            self.isDark = isDark
            self.isLifted = isLifted
            self.isCollapsed = isCollapsed
        }
    }

    public let contentView: UIView
    public let selectedContentView: UIView

    public weak var snapshotSourceView: UIView? {
        didSet {
            if self.snapshotSourceView !== oldValue {
                self.setNeedsSnapshotRefresh(immediate: true)
            }
        }
    }

    private let lensContainerView: UIView
    private let snapshotContainerView: UIView
    private let snapshotImageView: UIImageView
    private let blurView: UIVisualEffectView
    private let tintView: UIView
    private let highlightLayer: CAGradientLayer
    private let rimLayer: CAShapeLayer

    private var params: Params?
    private var lensFrame: CGRect = .zero
    private var snapshotSize: CGSize = .zero
    private var snapshotTimer: Timer?
    private var pendingSnapshotRefresh = false

    public override init(frame: CGRect) {
        self.contentView = UIView()
        self.selectedContentView = UIView()
        self.lensContainerView = UIView()
        self.snapshotContainerView = UIView()
        self.snapshotImageView = UIImageView()
        self.blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        self.tintView = UIView()
        self.highlightLayer = CAGradientLayer()
        self.rimLayer = CAShapeLayer()

        super.init(frame: frame)

        self.addSubview(self.contentView)
        self.addSubview(self.lensContainerView)

        self.lensContainerView.addSubview(self.snapshotContainerView)
        self.lensContainerView.addSubview(self.selectedContentView)

        self.snapshotContainerView.addSubview(self.snapshotImageView)
        self.snapshotContainerView.addSubview(self.blurView)
        self.snapshotContainerView.addSubview(self.tintView)

        self.lensContainerView.layer.addSublayer(self.highlightLayer)
        self.lensContainerView.layer.addSublayer(self.rimLayer)

        self.snapshotImageView.contentMode = .topLeft
        self.snapshotImageView.clipsToBounds = false
        self.snapshotContainerView.clipsToBounds = true
        self.lensContainerView.clipsToBounds = true
        self.selectedContentView.clipsToBounds = true

        self.highlightLayer.locations = [0.0, 1.0]
        self.rimLayer.fillColor = UIColor.clear.cgColor
        self.rimLayer.lineWidth = 1.0
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.snapshotTimer?.invalidate()
    }

    public func setNeedsSnapshotRefresh(immediate: Bool = false) {
        if immediate {
            self.snapshotTimer?.invalidate()
            self.snapshotTimer = nil
            self.refreshSnapshot()
            return
        }
        if self.pendingSnapshotRefresh {
            return
        }
        self.pendingSnapshotRefresh = true
        self.snapshotTimer?.invalidate()
        self.snapshotTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: false, block: { [weak self] _ in
            self?.refreshSnapshot()
        })
    }

    private func refreshSnapshot() {
        self.pendingSnapshotRefresh = false
        guard let sourceView = self.snapshotSourceView ?? self.contentView else {
            return
        }
        let sourceSize = sourceView.bounds.size
        guard sourceSize.width > 1.0, sourceSize.height > 1.0 else {
            return
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreenScale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(bounds: sourceView.bounds, format: format)
        let image = renderer.image { context in
            sourceView.layer.render(in: context.cgContext)
        }
        self.snapshotImageView.image = image
        self.snapshotSize = sourceSize
        self.updateSnapshotOffset()
    }

    public func update(size: CGSize, selectionOrigin: CGPoint, selectionSize: CGSize, inset: CGFloat, liftedInset: CGFloat = 4.0, isDark: Bool, isLifted: Bool, isCollapsed: Bool, transition: ComponentTransition) {
        let params = Params(size: size, selectionOrigin: selectionOrigin, selectionSize: selectionSize, inset: inset, liftedInset: liftedInset, isDark: isDark, isLifted: isLifted, isCollapsed: isCollapsed)
        if self.params == params {
            return
        }
        self.params = params

        transition.setFrame(view: self.contentView, frame: CGRect(origin: .zero, size: size))

        var lensFrame = CGRect(origin: selectionOrigin, size: selectionSize).insetBy(dx: -inset, dy: -inset)
        if isLifted && !UIAccessibility.isReduceMotionEnabled {
            lensFrame = lensFrame.insetBy(dx: -liftedInset, dy: -liftedInset)
        }
        lensFrame.origin.x = max(0.0, min(lensFrame.origin.x, size.width - lensFrame.size.width))
        lensFrame.origin.y = max(0.0, min(lensFrame.origin.y, size.height - lensFrame.size.height))
        self.lensFrame = lensFrame

        transition.setFrame(view: self.lensContainerView, frame: lensFrame)
        transition.setFrame(view: self.snapshotContainerView, frame: CGRect(origin: .zero, size: lensFrame.size))
        transition.setFrame(view: self.selectedContentView, frame: CGRect(origin: .zero, size: lensFrame.size))
        transition.setFrame(view: self.blurView, frame: CGRect(origin: .zero, size: lensFrame.size))
        transition.setFrame(view: self.tintView, frame: CGRect(origin: .zero, size: lensFrame.size))

        let cornerRadius = lensFrame.height * 0.5
        transition.setCornerRadius(layer: self.lensContainerView.layer, cornerRadius: cornerRadius)
        transition.setCornerRadius(layer: self.snapshotContainerView.layer, cornerRadius: cornerRadius)
        transition.setCornerRadius(layer: self.tintView.layer, cornerRadius: cornerRadius)
        transition.setCornerRadius(layer: self.selectedContentView.layer, cornerRadius: cornerRadius)

        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled
        self.blurView.isHidden = reduceTransparency

        let tintBase = UIColor(white: isDark ? 0.0 : 1.0, alpha: isDark ? 0.32 : 0.45)
        self.tintView.backgroundColor = tintBase

        self.updateHighlight(isDark: isDark, cornerRadius: cornerRadius, size: lensFrame.size)
        self.updateRim(isDark: isDark, cornerRadius: cornerRadius, size: lensFrame.size)

        self.updateSnapshotOffset()
    }

    private func updateSnapshotOffset() {
        guard self.snapshotSize.width > 0.0, self.snapshotSize.height > 0.0 else {
            return
        }
        let origin = CGPoint(x: -self.lensFrame.minX, y: -self.lensFrame.minY)
        self.snapshotImageView.frame = CGRect(origin: origin, size: self.snapshotSize)
    }

    private func updateHighlight(isDark: Bool, cornerRadius: CGFloat, size: CGSize) {
        let highlightColor = UIColor(white: 1.0, alpha: isDark ? 0.4 : 0.3)
        let clearColor = UIColor(white: 1.0, alpha: 0.0)
        self.highlightLayer.colors = [highlightColor.cgColor, clearColor.cgColor]
        self.highlightLayer.startPoint = CGPoint(x: 0.2, y: 0.0)
        self.highlightLayer.endPoint = CGPoint(x: 0.8, y: 1.0)
        self.highlightLayer.frame = CGRect(origin: .zero, size: size)
        self.highlightLayer.cornerRadius = cornerRadius
    }

    private func updateRim(isDark: Bool, cornerRadius: CGFloat, size: CGSize) {
        let rimColor = isDark ? UIColor(white: 1.0, alpha: 0.16) : UIColor(white: 1.0, alpha: 0.12)
        self.rimLayer.strokeColor = rimColor.cgColor
        self.rimLayer.frame = CGRect(origin: .zero, size: size)
        self.rimLayer.path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5), cornerRadius: cornerRadius).cgPath
    }
}
