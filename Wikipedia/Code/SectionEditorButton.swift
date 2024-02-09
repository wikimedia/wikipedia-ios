import Foundation

struct SectionEditorButton {
    enum Kind {
        case undo
        case redo
        case progress
    }

    let kind: Kind
}
