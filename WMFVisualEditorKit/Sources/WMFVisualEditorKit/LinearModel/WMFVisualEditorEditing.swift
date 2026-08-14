import Foundation

/// Character-level and structural editing of the linear model — the first
/// slices of the transaction engine. Edits validate that they only touch
/// content they are allowed to touch, splice the linear items, mark the
/// enclosing blocks dirty (so the serializer knows what it may not emit from
/// source anymore), and return the removed items for exact undo.
extension WMFVisualEditorDocument {

    public enum EditingError: Error, Equatable {
        case rangeOutOfBounds
        case rangeContainsStructure
        case invalidInsertionPoint
        case unbalancedResult
    }

    private static let contentBlockTypes: Set<String> = ["paragraph", "heading", "listItem"]

    /// Replaces the characters in `linearRange` with `text` (annotated uniformly).
    /// An empty range is an insertion; empty text is a deletion.
    ///
    /// Returns the new document plus the exact removed items — pass those to
    /// `replacingItems(in:with:)` to undo (annotation-faithful restoration).
    public func replacingCharacters(in linearRange: Range<Int>, with text: String, annotations: [WMFVisualEditorAnnotation]) throws -> (document: WMFVisualEditorDocument, removedItems: [WMFVisualEditorLinearItem]) {
        let insertedItems = text.map { WMFVisualEditorLinearItem.character($0, annotations: annotations) }
        return try replacingItems(in: linearRange, with: insertedItems)
    }

    /// Splices `items` over `linearRange`. The range may only cover character
    /// items, and the edit position must sit inside content (adjacent to a
    /// character or directly inside an empty content block).
    public func replacingItems(in linearRange: Range<Int>, with items: [WMFVisualEditorLinearItem]) throws -> (document: WMFVisualEditorDocument, removedItems: [WMFVisualEditorLinearItem]) {
        guard linearRange.lowerBound >= 0, linearRange.upperBound <= linearModel.count else {
            throw EditingError.rangeOutOfBounds
        }

        let removedItems = Array(linearModel[linearRange])
        guard removedItems.allSatisfy({ if case .character = $0 { return true } else { return false } }) else {
            throw EditingError.rangeContainsStructure
        }

        guard isValidEditPosition(linearRange.lowerBound) else {
            throw EditingError.invalidInsertionPoint
        }

        var newItems = linearModel
        newItems.replaceSubrange(linearRange, with: items)

        var newStatistics = statistics
        applyStatisticsDelta(&newStatistics, removed: removedItems, inserted: items)

        var newDirtyBlockIndices = shiftedDirtyBlockIndices(afterSplicing: linearRange, delta: items.count - removedItems.count)
        if let enclosingIndex = enclosingOpenIndex(before: linearRange.lowerBound) {
            newDirtyBlockIndices.insert(enclosingIndex)
        }

        let newDocument = WMFVisualEditorDocument(bodyNode: bodyNode, linearModel: newItems, statistics: newStatistics, sourceHTML: sourceHTML, dirtyBlockIndices: newDirtyBlockIndices)
        return (newDocument, removedItems)
    }

    /// Replaces the characters in `linearRange` with `text`, preserving any
    /// structural items (container/meta/alien pairs) interleaved in the range.
    /// This is what typing and deleting through a selection uses: invisible
    /// spans and metas sit between characters everywhere in real articles, and
    /// a character edit must flow around them, not be blocked by them. All
    /// structural items in the range survive in order (a span whose characters
    /// are deleted becomes an empty span); balance is therefore untouched.
    ///
    /// Returns the exact original slice for undo via `splicingItems`.
    public func replacingCharactersPreservingStructure(in linearRange: Range<Int>, with text: String, annotations: [WMFVisualEditorAnnotation]) throws -> (document: WMFVisualEditorDocument, removedSlice: [WMFVisualEditorLinearItem], newSliceCount: Int) {
        guard linearRange.lowerBound >= 0, linearRange.upperBound <= linearModel.count else {
            throw EditingError.rangeOutOfBounds
        }

        let originalSlice = Array(linearModel[linearRange])
        let structureItems = originalSlice.filter { item in
            if case .character = item {
                return false
            }
            return true
        }

        // Inserting text needs a content position; pure deletion does not.
        if !text.isEmpty {
            guard isValidEditPosition(linearRange.lowerBound) else {
                throw EditingError.invalidInsertionPoint
            }
        }

        let insertedCharacterItems = text.map { WMFVisualEditorLinearItem.character($0, annotations: annotations) }
        let newSlice = insertedCharacterItems + structureItems

        var newItems = linearModel
        newItems.replaceSubrange(linearRange, with: newSlice)

        var newStatistics = statistics
        let removedCharacterItems = originalSlice.filter { item in
            if case .character = item {
                return true
            }
            return false
        }
        applyStatisticsDelta(&newStatistics, removed: removedCharacterItems, inserted: insertedCharacterItems)

        var newDirtyBlockIndices = shiftedDirtyBlockIndices(afterSplicing: linearRange, delta: newSlice.count - originalSlice.count)
        if let enclosingIndex = enclosingOpenIndex(before: linearRange.lowerBound) {
            newDirtyBlockIndices.insert(enclosingIndex)
        }
        // Structural items inside the slice keep their identity but their
        // subtrees may now differ from source (characters removed around them);
        // mark them dirty as well.
        var offset = linearRange.lowerBound + insertedCharacterItems.count
        for item in structureItems {
            if case .open = item {
                newDirtyBlockIndices.insert(offset)
            }
            offset += 1
        }

        let newDocument = WMFVisualEditorDocument(bodyNode: bodyNode, linearModel: newItems, statistics: newStatistics, sourceHTML: sourceHTML, dirtyBlockIndices: newDirtyBlockIndices)
        return (newDocument, originalSlice, newSlice.count)
    }

    /// Toggles an annotation over a range of characters — the transaction
    /// behind the formatting toolbar. If every character in the range already
    /// carries the annotation kind, it is removed; otherwise it is added to the
    /// characters missing it. Undo works through the standard removed-items
    /// mechanism, restoring the previous annotation lists exactly.
    public func togglingAnnotation(kind: WMFVisualEditorAnnotation.Kind, target: String? = nil, in linearRange: Range<Int>) throws -> (document: WMFVisualEditorDocument, removedItems: [WMFVisualEditorLinearItem]) {
        guard linearRange.lowerBound >= 0, linearRange.upperBound <= linearModel.count, !linearRange.isEmpty else {
            throw EditingError.rangeOutOfBounds
        }

        let rangeItems = Array(linearModel[linearRange])
        let characters: [(Character, [WMFVisualEditorAnnotation])] = try rangeItems.map { item in
            guard case .character(let character, let annotations) = item else {
                throw EditingError.rangeContainsStructure
            }
            return (character, annotations)
        }

        let everyCharacterHasKind = characters.allSatisfy { $0.1.contains { $0.kind == kind } }

        let modifiedItems: [WMFVisualEditorLinearItem] = characters.map { character, annotations in
            var modified = annotations
            if everyCharacterHasKind {
                modified.removeAll { $0.kind == kind }
            } else if !modified.contains(where: { $0.kind == kind }) {
                modified.append(WMFVisualEditorAnnotation(kind: kind, target: target))
            }
            return .character(character, annotations: modified)
        }

        return try replacingItems(in: linearRange, with: modifiedItems)
    }

    /// Splits the content block enclosing `linearIndex` in two — the structural
    /// transaction behind pressing Return. Splitting mid-block produces two
    /// blocks of the same type; splitting at the end of a heading starts a
    /// paragraph (matching the web visual editor's behavior).
    ///
    /// Returns the new document and the inserted `[close, open]` pair; undo is
    /// `splicingItems(in: linearIndex..<linearIndex+2, with: [])`.
    public func splittingBlock(at linearIndex: Int) throws -> (document: WMFVisualEditorDocument, insertedItems: [WMFVisualEditorLinearItem]) {
        guard linearIndex >= 0, linearIndex <= linearModel.count else {
            throw EditingError.rangeOutOfBounds
        }

        // Nearest unmatched content-block open item walking backward.
        var enclosing: (type: String, attributes: [String: String], index: Int)?
        var skipDepth = 0
        search: for index in stride(from: linearIndex - 1, through: 0, by: -1) {
            switch linearModel[index] {
            case .close:
                skipDepth += 1
            case .open(let type, let attributes, _):
                if skipDepth > 0 {
                    skipDepth -= 1
                } else {
                    if Self.contentBlockTypes.contains(type) {
                        enclosing = (type, attributes, index)
                    }
                    break search
                }
            case .character:
                break
            }
        }

        guard let enclosing else {
            throw EditingError.invalidInsertionPoint
        }

        var caretIsAtBlockEnd = false
        if linearIndex < linearModel.count, case .close(let closeType) = linearModel[linearIndex], closeType == enclosing.type {
            caretIsAtBlockEnd = true
        }

        let newBlockType: String
        let newBlockAttributes: [String: String]
        if enclosing.type == "heading", caretIsAtBlockEnd {
            newBlockType = "paragraph"
            newBlockAttributes = [:]
        } else {
            newBlockType = enclosing.type
            newBlockAttributes = enclosing.attributes
        }

        let insertedItems: [WMFVisualEditorLinearItem] = [
            .close(type: enclosing.type),
            .open(type: newBlockType, attributes: newBlockAttributes, preservedContent: nil)
        ]

        var newItems = linearModel
        newItems.insert(contentsOf: insertedItems, at: linearIndex)

        var newStatistics = statistics
        newStatistics.nodeTypeCounts[newBlockType, default: 0] += 1

        var newDirtyBlockIndices = shiftedDirtyBlockIndices(afterSplicing: linearIndex..<linearIndex, delta: insertedItems.count)
        newDirtyBlockIndices.insert(enclosing.index)
        newDirtyBlockIndices.insert(linearIndex + 1)

        let newDocument = WMFVisualEditorDocument(bodyNode: bodyNode, linearModel: newItems, statistics: newStatistics, sourceHTML: sourceHTML, dirtyBlockIndices: newDirtyBlockIndices)
        return (newDocument, insertedItems)
    }

    /// Low-level splice for undo/redo of structural edits: no character-only
    /// restriction, but the result must remain balanced (every close matches
    /// its open, depth never goes negative). Statistics are recomputed and the
    /// enclosing block is conservatively marked dirty.
    public func splicingItems(in linearRange: Range<Int>, with items: [WMFVisualEditorLinearItem]) throws -> (document: WMFVisualEditorDocument, removedItems: [WMFVisualEditorLinearItem]) {
        guard linearRange.lowerBound >= 0, linearRange.upperBound <= linearModel.count else {
            throw EditingError.rangeOutOfBounds
        }

        let removedItems = Array(linearModel[linearRange])
        var newItems = linearModel
        newItems.replaceSubrange(linearRange, with: items)

        var openStack: [String] = []
        for item in newItems {
            switch item {
            case .open(let type, _, _):
                openStack.append(type)
            case .close(let type):
                guard openStack.popLast() == type else {
                    throw EditingError.unbalancedResult
                }
            case .character:
                break
            }
        }
        guard openStack.isEmpty else {
            throw EditingError.unbalancedResult
        }

        var newStatistics = WMFVisualEditorDocumentStatistics()
        newStatistics.skippedElementCounts = statistics.skippedElementCounts
        for item in newItems {
            switch item {
            case .open(let type, _, _):
                newStatistics.nodeTypeCounts[type, default: 0] += 1
            case .character(_, let annotations):
                newStatistics.characterCount += 1
                if !annotations.isEmpty {
                    newStatistics.annotatedCharacterCount += 1
                }
            case .close:
                break
            }
        }

        var newDirtyBlockIndices = shiftedDirtyBlockIndices(afterSplicing: linearRange, delta: items.count - removedItems.count)
        if let enclosingIndex = enclosingOpenIndex(before: linearRange.lowerBound) {
            newDirtyBlockIndices.insert(enclosingIndex)
        }

        let newDocument = WMFVisualEditorDocument(bodyNode: bodyNode, linearModel: newItems, statistics: newStatistics, sourceHTML: sourceHTML, dirtyBlockIndices: newDirtyBlockIndices)
        return (newDocument, removedItems)
    }

    // MARK: - Private

    /// Nearest unmatched open item before `position` — the node that directly
    /// contains it.
    private func enclosingOpenIndex(before position: Int) -> Int? {
        var skipDepth = 0
        for index in stride(from: position - 1, through: 0, by: -1) {
            switch linearModel[index] {
            case .close:
                skipDepth += 1
            case .open:
                if skipDepth > 0 {
                    skipDepth -= 1
                } else {
                    return index
                }
            case .character:
                break
            }
        }
        return nil
    }

    /// Dirty indices survive a splice by shifting: indices past the replaced
    /// range move by `delta`; indices inside it are dropped.
    private func shiftedDirtyBlockIndices(afterSplicing linearRange: Range<Int>, delta: Int) -> Set<Int> {
        var shifted = Set<Int>()
        for index in dirtyBlockIndices {
            if index < linearRange.lowerBound {
                shifted.insert(index)
            } else if index >= linearRange.upperBound {
                shifted.insert(index + delta)
            }
        }
        return shifted
    }

    /// A position is editable when it touches character content: the previous
    /// item or the item at the position is a character, or the position sits
    /// directly inside an (empty) content block such as a paragraph or heading.
    private func isValidEditPosition(_ position: Int) -> Bool {
        let contentBlockTypes = Self.contentBlockTypes

        if position > 0, position <= linearModel.count {
            switch linearModel[position - 1] {
            case .character:
                return true
            case .open(let type, _, _) where contentBlockTypes.contains(type):
                return true
            default:
                break
            }
        }
        if position < linearModel.count {
            if case .character = linearModel[position] {
                return true
            }
        }
        return false
    }

    private func applyStatisticsDelta(_ statistics: inout WMFVisualEditorDocumentStatistics, removed: [WMFVisualEditorLinearItem], inserted: [WMFVisualEditorLinearItem]) {
        for item in removed {
            if case .character(_, let annotations) = item {
                statistics.characterCount -= 1
                if !annotations.isEmpty {
                    statistics.annotatedCharacterCount -= 1
                }
            }
        }
        for item in inserted {
            if case .character(_, let annotations) = item {
                statistics.characterCount += 1
                if !annotations.isEmpty {
                    statistics.annotatedCharacterCount += 1
                }
            }
        }
    }
}
