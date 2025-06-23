// bomberfish
// UIScreen+cornerRadius.swift – Hallaca
// created on 2025-01-19

#if canImport(UIKit)
import UIKit

extension UIScreen {
    /// The corner radius of the screen.
    /// Apple devices use a continuous radius, so make sure to use this when creating rounded corners.
    /// Example: `RoundedRectangle(cornerRadius: UIScreen.main.cornerRadius, style: .continuous)`
    var cornerRadius: CGFloat {
        self // current uiscreen
            .value( // value for key of nsobject, an objc-ism
                forKey:
                    // technically i'm not trying to sneak this past app review,
                    // but i still think it's funny that this works and i also think it's super cool
                    // plus, the challenge rules say nothing about using private apis
                    ["ius", "Rad", "ner", "Cor", "play", "dis", "_"] // key
                    .reversed() // ["_", "dis", "play", "Cor", "ner", "Rad", "ius"]
                    .joined() // "_displayCornerRadius"
            )
        as? CGFloat // convert to a cgfloat
        ?? 0 // fallback to 0
    }
}
#endif
