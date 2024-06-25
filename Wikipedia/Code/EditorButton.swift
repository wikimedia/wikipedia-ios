import Foundation

struct EditorButton {
    enum Kind {
        case undo
        case redo
        case progress
    }

    let kind: Kind
}
