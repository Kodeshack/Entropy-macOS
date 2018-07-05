import Cocoa
import EntropyKit

class ChatViewController: NSViewController {
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var messageInput: NSTextView!
    @IBOutlet private var messageInputHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var messageInputMinHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var messageInputMaxHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var messageInputBackgroundView: NSVisualEffectView!

    private var newLineModifier = false
    private var lastTextHeight: CGFloat = 0

    private var messages: ObservablePersistedList<Message>?
    private var observerToken: ObservablePersistedList<Message>.ObserverToken?

    /// directory URL used for accepting file promises
    private lazy var destinationURL: URL = {
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()

    var room: Room? {
        didSet {
            guard let room = room else { return }
            messages = try! Entropy.default.messages(for: room.id)
            observerToken?.invalidate()
            observerToken = messages?.addObserver(for: tableView, configureCell: configure)

            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        messageInput.delegate = self
        messageInput.enclosingScrollView?.wantsLayer = true
        messageInput.enclosingScrollView?.layer?.cornerRadius = 5.0
        messageInput.textContainerInset = NSSize(width: 4, height: 4)
        messageInput.isVerticallyResizable = true

        let nib = NSNib(nibNamed: "TextMessageView", bundle: Bundle.main)
        tableView.register(nib, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TextMessageView"))

        if let view = view as? DragDestinationView {
            view.delegate = self
            view.registerForDraggedTypes(NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
            view.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
        }
    }

    deinit {
        observerToken?.invalidate()
    }
}

// MARK: - Message Stuff

extension ChatViewController {
    private func send() {
        guard let room = room else { return }

        let body = messageInput.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }

        Entropy.default.sendMessage(room: room, body: body)
        messageInput.string = ""
    }
}

// MARK: - NSTableViewDataSource

extension ChatViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return messages?.count ?? 0
    }

    private func configure(cell: NSView, at row: Int) {
        guard let messages = messages else { return }
        let message = messages[row]

        switch cell {
        case let cell as TextMessageView:
            cell.message = message
        default: break
        }
    }
}

// MARK: - NSTableViewDelegate

extension ChatViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("TextMessageView")
        let cell = tableView.makeView(withIdentifier: identifier, owner: tableView)!
        configure(cell: cell, at: row)
        return cell
    }
}

// MARK: - NSTextViewDelegate

extension ChatViewController: NSTextViewDelegate {
    private func updateMessageInputLayout() {
        // These could maybe be cached, but they are unowned bindings and it's unclear, when they are set and if they might change, so this is probably safer
        guard let textContainer = messageInput.textContainer, let layoutManager = messageInput.layoutManager else { return }

        // This could be optimized. But we don't have a lot of control over it, so I'm very cautions.
        layoutManager.ensureLayout(for: textContainer)
        let height = layoutManager.usedRect(for: textContainer).height

        // We could add another check here to avoid unnecessary updates to auto layout.
        guard height != lastTextHeight else { return }

        lastTextHeight = height

        if height < messageInputMinHeightConstraint.constant {
            messageInputHeightConstraint.constant = messageInputMinHeightConstraint.constant
        } else if height > messageInputMaxHeightConstraint.constant {
            messageInputHeightConstraint.constant = messageInputMaxHeightConstraint.constant
        } else {
            messageInputHeightConstraint.constant = height + messageInput.textContainerInset.height * 2 // * 2 because top and bottom, I think. Anyway, this works... for now.
        }

        messageInputBackgroundView.layoutSubtreeIfNeeded()
        tableView.enclosingScrollView?.contentInsets.bottom = messageInputBackgroundView.frame.height
    }

    func textDidChange(_: Notification) {
        updateMessageInputLayout()
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        newLineModifier = event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option)
    }

    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline) && !newLineModifier {
            send()
            updateMessageInputLayout()
            return true
        } else {
            return false
        }
    }
}

// MARK: - DragDestinationViewDelegate

extension ChatViewController: DragDestinationViewDelegate {
    func draggingEntered(forView _: DragDestinationView, sender: NSDraggingInfo) -> NSDragOperation {
        return sender.draggingSourceOperationMask.intersection([.copy])
    }

    func performDragOperation(forView _: DragDestinationView, sender: NSDraggingInfo) -> Bool {
        let supportedClasses = [
            NSFilePromiseReceiver.self,
            NSURL.self,
        ]

        let searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [
            .urlReadingFileURLsOnly: true,
        ]

        sender.enumerateDraggingItems(options: [], for: nil, classes: supportedClasses, searchOptions: searchOptions) { draggingItem, _, _ in
            switch draggingItem.item {
            case let filePromiseReceiver as NSFilePromiseReceiver:
                filePromiseReceiver.receivePromisedFiles(atDestination: self.destinationURL, options: [:], operationQueue: OperationQueue.current!) { fileURL, error in
                    if let error = error {
                        self.handleError(error)
                    } else {
                        self.handleFile(at: fileURL)
                    }
                }
            case let fileURL as URL:
                self.handleFile(at: fileURL)
            default: break
            }
        }

        return true
    }

    private func handleFile(at url: URL) {
        let okDialog = NSAlert()
        okDialog.messageText = "Are you sure you want to upload the file \(url.pathComponents.last!)?"
        okDialog.alertStyle = .warning
        okDialog.addButton(withTitle: "Send")
        okDialog.addButton(withTitle: "Cancel")

        guard okDialog.runModal() == .alertFirstButtonReturn else { return }

        do {
            let data = try Data(contentsOf: url)
            Entropy.default.sendMedia(room: room!, filename: url.pathComponents.last!, mimeType: "application/octet-stream", data: data)
        } catch {
            print(error)
        }
    }

    private func handleError(_ error: Error) {
        print(error)
    }
}
