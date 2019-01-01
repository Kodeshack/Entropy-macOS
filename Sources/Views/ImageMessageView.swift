import AppKit
import EntropyKit

class ImageMessageView: TextMessageView {
    private let imageView: NSImageView = {
        let imageView = NSImageView(frame: .zero)
        imageView.imageAlignment = .alignTopLeft
        imageView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 200).isActive = true
        stackView.addView(imageView, in: .bottom)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configure(_ message: Message) {
        super.configure(message)

        Entropy.default.thumbnail(for: message) { [weak self] result, message in
            // View still in memory?
            guard let self = self else { return }

            // View not recycled?
            guard self.message == message else { return }

            guard let image = result.value else { return }

            self.imageView.image = image
        }
    }
}
