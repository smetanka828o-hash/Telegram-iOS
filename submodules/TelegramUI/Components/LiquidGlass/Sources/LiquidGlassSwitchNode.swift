import Foundation
import UIKit
import Display
import AsyncDisplayKit
import GlassBackgroundComponent

public final class LiquidGlassSwitchNode: SwitchNode {
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

    public override init() {
        super.init()
        self.glassView.isUserInteractionEnabled = false
    }

    public override func didLoad() {
        super.didLoad()
        self.updateThumbView()
    }

    public override func layout() {
        super.layout()
        self.updateThumbView()
    }

    private func updateGlassAppearance() {
        self.updateThumbView()
    }

    private func updateThumbView() {
        guard let switchView = self.view as? UISwitch else {
            return
        }
        if let thumbView = self.thumbView, thumbView.superview == nil {
            self.thumbView = nil
        }
        if self.thumbView == nil {
            self.thumbView = self.resolveThumbView(in: switchView)
        }
        guard let thumbView = self.thumbView else {
            return
        }

        if self.glassView.superview !== thumbView {
            thumbView.addSubview(self.glassView)
        }
        self.glassView.frame = thumbView.bounds

        let tint = self.glassTintColor ?? self.contentColor
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

    private func resolveThumbView(in switchView: UISwitch) -> UIView? {
        let candidates = switchView.subviews.flatMap { $0.subviews } + switchView.subviews
        let desired = max(10.0, min(switchView.bounds.width, switchView.bounds.height) - 4.0)

        var best: UIView?
        var bestScore: CGFloat = .greatestFiniteMagnitude

        for view in candidates {
            let size = view.bounds.size
            guard size.width > 1.0, size.height > 1.0 else {
                continue
            }
            guard size.width < switchView.bounds.width, size.height < switchView.bounds.height else {
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
