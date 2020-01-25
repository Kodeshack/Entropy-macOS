import AppKit

class DragDestinationView: NSView {
    var delegate: DragDestinationViewDelegate?

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        delegate?.draggingEntered(forView: self, sender: sender) ?? []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        delegate?.performDragOperation(forView: self, sender: sender) ?? false
    }
}

protocol DragDestinationViewDelegate: AnyObject {
    func draggingEntered(forView view: DragDestinationView, sender: NSDraggingInfo) -> NSDragOperation
    func performDragOperation(forView view: DragDestinationView, sender: NSDraggingInfo) -> Bool
}
