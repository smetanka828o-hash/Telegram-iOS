import Foundation
import UIKit
import GlassBackgroundComponent

public final class LiquidGlassSliderView: UISlider {
    @objc public dynamic var glassIsDark: Bool = false {
        didSet {
            if self.glassIsDark != oldValue {
                self.updateGlassAppearance()
            }
        }
    }

    @objc public dynamic var glassTintColor: UIColor? {
        didSet {
            if self.glassTintColor !== oldValue {
                self.updateGlassAppearance()
            }
        }
    }

    private let glassView = LiquidGlassView()
    private weak var thumbView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.glassView.isUserInteractionEnabled = false
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updateThumbView()
    }

    private func updateGlassAppearance() {
        self.updateThumbView()
    }

    private func updateThumbView() {
        if let thumbView = self.thumbView, thumbView.superview == nil {
            self.thumbView = nil
        }
        if self.thumbView == nil {
            self.thumbView = self.resolveThumbView()
        }
        guard let thumbView = self.thumbView else {
            return
        }

        if self.glassView.superview !== thumbView {
            thumbView.addSubview(self.glassView)
        }
        self.glassView.frame = thumbView.bounds

        let tint = self.glassTintColor ?? self.minimumTrackTintColor ?? UIColor(white: 1.0, alpha: 0.8)
        let cornerRadius = min(thumbView.bounds.width, thumbView.bounds.height) * 0.5
        self.glassView.update(
            size: thumbView.bounds.size,
            cornerRadius: cornerRadius,
            isDark: self.glassIsDark,
            tintColor: .init(kind: .custom, color: tint),
            isInteractive: false,
            transition: .immediate
        )
    }

    private func resolveThumbView() -> UIView? {
        let candidates = self.subviews.flatMap { $0.subviews } + self.subviews
        let desired = max(10.0, min(self.bounds.width, self.bounds.height) - 4.0)

        var best: UIView?
        var bestScore: CGFloat = .greatestFiniteMagnitude

        for view in candidates {
            let size = view.bounds.size
            guard size.width > 1.0, size.height > 1.0 else {
                continue
            }
            guard size.width < self.bounds.width, size.height < self.bounds.height else {
                continue
            }
            let score = abs(size.height - desired) + abs(size.width - desired)
            if score < bestScore {
                bestScore = score
                best = view
            }
        }
        return best
    }
}
