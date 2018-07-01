import Cocoa

class MasterViewController: NSSplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarViewController = children[0] as! SidebarViewController
        let chatViewController = children[1] as! ChatViewController

        sidebarViewController.chatViewController = chatViewController
    }
}
