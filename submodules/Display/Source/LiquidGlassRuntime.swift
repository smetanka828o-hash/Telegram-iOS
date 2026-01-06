import Foundation
import UIKit

public func applyGlassStyleIfSupported(object: AnyObject, isDark: Bool, tintColor: UIColor?) {
    guard let object = object as? NSObject else {
        return
    }

    let setIsDarkSelector = NSSelectorFromString("setGlassIsDark:")
    if object.responds(to: setIsDarkSelector) {
        _ = object.perform(setIsDarkSelector, with: NSNumber(value: isDark))
    }

    if let tintColor {
        let setTintSelector = NSSelectorFromString("setGlassTintColor:")
        if object.responds(to: setTintSelector) {
            _ = object.perform(setTintSelector, with: tintColor)
        }
    }
}
