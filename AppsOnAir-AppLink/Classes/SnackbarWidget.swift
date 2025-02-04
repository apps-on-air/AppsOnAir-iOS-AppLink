import UIKit

public class Snackbar {

    public static func show(message: String, duration: TimeInterval = 2.0) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        let label = UILabel()
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textColor = .white
        label.textAlignment = .center // Center alignment
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = message
        label.numberOfLines = 0
        label.alpha = 1.0
        label.layer.cornerRadius = 8
        label.clipsToBounds = true

        let padding: CGFloat = 16
        let maxWidth = window.frame.width - 2 * padding
        let size = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))

        let labelWidth = min(maxWidth, size.width)
        let labelHeight = size.height
        let labelX = (window.frame.width - labelWidth) / 2
        if #available(iOS 11.0, *) {
            let labelY = window.frame.height - labelHeight - padding - window.safeAreaInsets.bottom
            label.frame = CGRect(x: labelX, y: labelY, width: labelWidth, height: labelHeight)
        }

        window.addSubview(label)

        UIView.animate(withDuration: 0.3, delay: duration, options: .curveEaseInOut, animations: {
            label.alpha = 0
        }, completion: { _ in
            label.removeFromSuperview()
        })
    }
}
