import AppKit
import EntropyKit

class TextMessageView: NSView {
    @IBOutlet private var avatarView: NSImageView!
    @IBOutlet private var displaynameLabel: NSTextField!
    @IBOutlet private var dateLabel: NSTextField!
    @IBOutlet private var body: MessageBodyView!

    private static let bigEmojiFont = NSFont.systemFont(ofSize: NSFont.systemFontSize * Settings.bigEmojiSizeFactor)
    private static let defaultFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

    private static var _messageDateFormatter: DateFormatter?
    private static var messageDateFormatter: DateFormatter {
        if _messageDateFormatter == nil {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            _messageDateFormatter = formatter
        }
        return _messageDateFormatter!
    }

    private static var _messageDetailDateFormatter: DateFormatter?
    private static var messageDetailDateFormatter: DateFormatter {
        if _messageDetailDateFormatter == nil {
            let formatter = DateFormatter()
            formatter.timeStyle = .medium
            formatter.dateStyle = .medium
            _messageDetailDateFormatter = formatter
        }
        return _messageDetailDateFormatter!
    }

    var message: Message? {
        didSet {
            guard let message = message else { return }
            configure(message)
        }
    }

    private func configure(_ message: Message) {
        guard let sender = message.sender else { return }

        displaynameLabel.stringValue = sender.displayname

        configureTextView(for: message.body)

        dateLabel.stringValue = TextMessageView.messageDateFormatter.string(for: message.date)!
        dateLabel.toolTip = TextMessageView.messageDetailDateFormatter.string(for: message.date)

        if message.body.count <= Settings.maxBigEmojiLength && message.body.isEmojiOnly {
            body.font = TextMessageView.bigEmojiFont
        } else {
            body.font = TextMessageView.defaultFont
        }

        Entropy.default.avatar(for: sender.id) { [weak self] result, userID in
            // View still in memory?
            guard let self = self else { return }

            // View not recycled?
            guard sender.id == userID else { return }

            if let image = result.value {
                self.avatarView.image = image
            }
        }
    }

    private func configureTextView(for messageBody: String) {
        let storage = NSTextStorage()
        let container = NSTextContainer()
        let layoutManager = NSLayoutManager()

        container.widthTracksTextView = true
        container.lineFragmentPadding = 0

        layoutManager.usesFontLeading = false

        layoutManager.replaceTextStorage(storage)
        container.replaceLayoutManager(layoutManager)
        body.replaceTextContainer(container)

        body.string = messageBody

        body.isEditable = true
        body.isAutomaticLinkDetectionEnabled = true
        body.isAutomaticDataDetectionEnabled = true
        body.checkTextInDocument(nil)
        body.isEditable = false
        body.isHorizontallyResizable = false
        body.isVerticallyResizable = true

        body.invalidateIntrinsicContentSize()
    }
}
