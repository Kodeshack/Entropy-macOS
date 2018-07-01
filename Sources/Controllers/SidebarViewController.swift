import Cocoa
import EntropyKit

class SidebarViewController: NSViewController {
    @IBOutlet private var outlineView: NSOutlineView!

    private var observerToken: ObservablePersistedList<Room>.ObserverToken?

    weak var chatViewController: ChatViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        outlineView.dataSource = self
        outlineView.delegate = self

        assert(observerToken == nil)
        observerToken = Entropy.default.rooms
            .addObserver(willChange: {}, onChange: { _, _ in }, didChange: outlineView.reloadData)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if Entropy.default.rooms.count > 0 {
            outlineView.selectRowIndexes(IndexSet(arrayLiteral: 0), byExtendingSelection: false)
        }
    }

    deinit {
        observerToken?.invalidate()
    }
}

// MARK: - NSOutlineViewDataSource

extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return Entropy.default.rooms.count
        }
        return 0
    }

    func outlineView(_: NSOutlineView, isItemExpandable _: Any) -> Bool {
        return false
    }

    func outlineView(_: NSOutlineView, child index: Int, ofItem _: Any?) -> Any {
        return Entropy.default.rooms[index]
    }
}

// MARK: - NSOutlineViewDelegate

extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        guard let room = item as? Room else {
            return nil
        }

        let identifier = NSUserInterfaceItemIdentifier(rawValue: "DataCell")
        let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
        cell.textField?.stringValue = "#\(room.smartName)"
        return cell
    }

    func outlineViewSelectionDidChange(_: Notification) {
        guard let room = outlineView.item(atRow: outlineView.selectedRow) as? Room else { return }
        chatViewController.room = room
        view.window?.title = "\(Bundle.main.applicationName) - #\(room.smartName)"
    }
}
