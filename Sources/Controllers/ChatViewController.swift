import Cocoa
import EntropyKit

class ChatViewController: NSViewController {
    @IBOutlet private var tableView: NSTableView!
    @IBOutlet private var messageView: NSTextView!

    private var messages: ObservablePersistedList<Message>?
    private var observerToken: ObservablePersistedList<Message>.ObserverToken?

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

        messageView.delegate = self
    }

    deinit {
        observerToken?.invalidate()
    }
}

// MARK: - Message Stuff

extension ChatViewController {
    private func send() {
        guard let room = room else { return }

        let body = messageView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        Entropy.default.sendMessage(room: room, body: body)
        messageView.string = ""
    }
}

// MARK: - NSTableViewDataSource

extension ChatViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return messages?.count ?? 0
    }

    private func configure(cell: NSTableCellView, at row: Int) {
        guard let messages = messages else { return }
        let message = messages[row]
        cell.textField?.stringValue = message.body
    }
}

// MARK: - NSTableViewDelegate

extension ChatViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("MessageView")
        let cell = tableView.makeView(withIdentifier: identifier, owner: tableView) as! NSTableCellView
        configure(cell: cell, at: row)
        return cell
    }
}

// MARK: - NSTextViewDelegate

extension ChatViewController: NSTextViewDelegate {
    func textView(_: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline) {
            send()
            return true
        } else {
            return false
        }
    }
}
