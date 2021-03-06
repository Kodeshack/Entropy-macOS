import AppKit
import EntropyKit

class TextMessageView: NSView {
    private let avatarView: NSImageView = {
        let imageView = NSImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let displaynameLabel: NSTextField = {
        let label = NSTextField(frame: .zero)
        label.isEditable = false
        label.drawsBackground = false
        label.isBordered = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: NSTextField = {
        let label = NSTextField(frame: .zero)
        label.isEditable = false
        label.drawsBackground = false
        label.isBordered = false
        label.textColor = NSColor.secondaryLabelColor
        label.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bodyLabel: NSTextField = {
        let label = NSTextField(frame: .zero)
        label.isSelectable = true
        label.isEditable = false
        label.drawsBackground = false
        label.isBordered = false
        label.allowsEditingTextAttributes = true
        label.usesSingleLineMode = false
        label.cell?.wraps = true
        label.cell?.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(250), for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private static let bigEmojiFont = NSFont.systemFont(ofSize: NSFont.systemFontSize * Settings.bigEmojiSizeFactor)
    private static let defaultFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    private static let messageDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private static let messageDetailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .medium
        return formatter
    }()

    var message: Message? {
        didSet {
            guard let message = message else { return }
            configure(message)
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        addSubview(avatarView)
        addSubview(displaynameLabel)
        addSubview(dateLabel)
        addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: .ALDefaultSpacing),
            avatarView.topAnchor.constraint(equalTo: topAnchor),
            avatarView.heightAnchor.constraint(equalToConstant: 42),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),

            displaynameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: .ALDefaultSpacing),
            displaynameLabel.topAnchor.constraint(equalTo: topAnchor),
            displaynameLabel.firstBaselineAnchor.constraint(equalTo: dateLabel.firstBaselineAnchor),

            dateLabel.leadingAnchor.constraint(equalTo: displaynameLabel.trailingAnchor, constant: .ALDefaultSpacing),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            NSLayoutConstraint(item: bodyLabel, attribute: .top, relatedBy: .equal, toItem: displaynameLabel, attribute: .bottom, multiplier: 1.0, constant: .ALDefaultSpacing),
            bodyLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -.ALDefaultSpacing),
            bodyLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            bodyLabel.leadingAnchor.constraint(equalTo: displaynameLabel.leadingAnchor),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(_ message: Message) {
        guard let sender = message.sender else { return }

        displaynameLabel.stringValue = sender.displayname

        configure(body: message.body)

        dateLabel.stringValue = TextMessageView.messageDateFormatter.string(for: message.date)!
        dateLabel.toolTip = TextMessageView.messageDetailDateFormatter.string(for: message.date)

        Entropy.default.avatar(for: sender.id) { [weak self] result, userID in
            // View still in memory?
            guard let self = self else { return }

            // View not recycled?
            guard sender.id == userID else { return }

            if let image = result.success {
                self.avatarView.image = image
            }
        }
    }

    private func configure(body: String) {
        if body.count <= Settings.maxBigEmojiLength, body.isEmojiOnly {
            bodyLabel.font = TextMessageView.bigEmojiFont
        } else {
            bodyLabel.font = TextMessageView.defaultFont
        }

        bodyLabel.stringValue = body

        // Hightlight URLs.
        let attributedMessage = NSMutableAttributedString(attributedString: bodyLabel.attributedStringValue)
        for (url, range) in body.urls {
            attributedMessage.addAttribute(.link, value: url, range: range)
        }
        bodyLabel.attributedStringValue = attributedMessage
    }
}
