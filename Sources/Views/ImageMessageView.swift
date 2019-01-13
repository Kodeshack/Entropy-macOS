import AppKit
import EntropyKit

class ImageMessageView: TextMessageView {
    private let imageView: SimpleImageView = {
        let imageView = SimpleImageView(frame: .zero)
        imageView.imageAlignment = .alignTopLeft
        imageView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private var ratioConstraint: NSLayoutConstraint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        imageView.heightAnchor.constraint(lessThanOrEqualToConstant: 200).isActive = true

        stackView.addView(imageView, in: .bottom)

        let f = self.imageView.widthAnchor.constraint(equalTo: self.stackView.widthAnchor, multiplier: 1)
        f.priority = NSLayoutConstraint.Priority(500)
        f.isActive = true
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

            self.ratioConstraint?.isActive = false
            let ratio = image.size.height / image.size.width
            self.ratioConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: ratio)
            self.ratioConstraint?.priority = NSLayoutConstraint.Priority(750)
            self.ratioConstraint?.isActive = true
        }
    }
}
