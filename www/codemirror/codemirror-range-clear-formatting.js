const getItemRangeFromSelection = require('./codemirror-range-utilities').getItemRangeFromSelection
const getMarkupItemsIntersectingSelection = require('./codemirror-range-utilities').getMarkupItemsIntersectingSelection
const getButtonNamesFromMarkupItems = require('./codemirror-range-utilities').getButtonNamesFromMarkupItems
const markupItemsForItemRangeLines = require('./codemirror-range-determination').markupItemsForItemRangeLines

const buttonNamesInSelectionRange = (codeMirror, selectionRange) => {
  const markupItems = markupItemsForItemRangeLines(codeMirror, selectionRange)
  const markupItemsIntersectingSelection = getMarkupItemsIntersectingSelection(codeMirror, markupItems, selectionRange)
  const buttonNames = getButtonNamesFromMarkupItems(markupItemsIntersectingSelection)
  return buttonNames
}

const canClearFormatting = (codeMirror) => {
  let selectionRange = getItemRangeFromSelection(codeMirror)
  if (selectionRange.isZeroLength()) {
    return false
  }

  const buttonNames = buttonNamesInSelectionRange(codeMirror, selectionRange)
  if (buttonNames.includes('reference') || buttonNames.includes('template') || buttonNames.includes('template-argument') || buttonNames.includes('template-name') || buttonNames.includes('template-delimiter')) {
    return false
  }
  
  return canRelocateOrRemoveExistingMarkupForSelectionRange(codeMirror) || canSplitMarkupAroundSelectionRange(codeMirror)
}

const clearFormatting = (codeMirror) => {
  codeMirror.operation(() => {
    relocateOrRemoveExistingMarkupForSelectionRange(codeMirror, false)
    splitMarkupAroundSelectionRange(codeMirror, false)
    pruneWhitespaceOnlyMarkupItems(codeMirror)
  })
}

const canRelocateOrRemoveExistingMarkupForSelectionRange = (codeMirror) => relocateOrRemoveExistingMarkupForSelectionRange(codeMirror, true)

const unsplittableMarkupTypes = ["mw-section-header"]  // headers should always be removed, never split

const relocateOrRemoveExistingMarkupForSelectionRange = (codeMirror, evaluateOnly = false) => {
  let selectionRange = getItemRangeFromSelection(codeMirror)
  const originalSelectionRange = selectionRange

  const allMarkupItems = markupItemsForItemRangeLines(codeMirror, selectionRange)
  const markupItems = allMarkupItems.filter(item => !unsplittableMarkupTypes.includes(item.type) && item.innerRangeStartsOrEndsInRange(selectionRange, true))
  const unsplittableItems = allMarkupItems.filter(item => unsplittableMarkupTypes.includes(item.type))
  
  selectionRange = getExpandedSelectionRange(codeMirror, markupItems, selectionRange)
  if (!evaluateOnly) {
    codeMirror.setSelection(selectionRange.startLocation, selectionRange.endLocation, '+')
  }

  const markupItemsIntersectingSelection = getMarkupItemsIntersectingSelection(codeMirror, markupItems, selectionRange)

  let markupRangesToMoveAfterSelection = []
  let markupRangesToMoveBeforeSelection = []
  let unsplittableMarkupRangesToRemove = []
  let markupRangesToRemove = []
  unsplittableItems.forEach(item => {
    unsplittableMarkupRangesToRemove.push(item.openingMarkupRange())
    unsplittableMarkupRangesToRemove.push(item.closingMarkupRange())
  })
  markupItemsIntersectingSelection.forEach(item => {
    const startsInside = item.outerRange.startsInsideRange(selectionRange, true)
    const endsInside = item.outerRange.endsInsideRange(selectionRange, true)
    if (!(startsInside === endsInside)) { // XOR
      if (startsInside) {
        markupRangesToMoveAfterSelection.push(item.openingMarkupRange())
      }
      if (endsInside) {
        markupRangesToMoveBeforeSelection.unshift(item.closingMarkupRange())
      }
    } else if (startsInside && endsInside) {
      markupRangesToRemove.push(item.openingMarkupRange())
      markupRangesToRemove.push(item.closingMarkupRange())
    }
  })
  
  const noMarkupToBeMovedToEitherSide = (markupRangesToMoveAfterSelection.length === 0 && markupRangesToMoveBeforeSelection.length === 0)
  if (noMarkupToBeMovedToEitherSide) {
    const openingMarkupRanges = markupItemsIntersectingSelection.map(item => item.openingMarkupRange())
    const closingMarkupRanges = markupItemsIntersectingSelection.map(item => item.closingMarkupRange())
    const allMarkupRanges = unsplittableMarkupRangesToRemove.concat(openingMarkupRanges.concat(closingMarkupRanges))
    if (evaluateOnly) {
      return allMarkupRanges.length > 0
    }
    removeTextFromRanges(codeMirror, allMarkupRanges)
    return allMarkupRanges.length > 0
  }
  if (evaluateOnly) {
    return true
  }

  let accumulatedLeftMarkup = getTextFromRanges(codeMirror, markupRangesToMoveAfterSelection)
  let accumulatedRightMarkup = getTextFromRanges(codeMirror, markupRangesToMoveBeforeSelection)

  // Work-around for cases which will result in empty markup items such as `<u></u>`, which, in some
  // cases, confuses the CodeMirror wikitext parsing. Injects a space inside such markup items so
  // they tokenize correctly can later be identified as whitespace-only and pruned. 
  if (selectionStartsAtOpeningMarkupEnd(markupItems, selectionRange)) {
    accumulatedRightMarkup = ` ${accumulatedRightMarkup}`
  }
  if (selectionEndsAtClosingMarkupStart(markupItems, selectionRange)) {
    accumulatedLeftMarkup = `${accumulatedLeftMarkup} `
  }

  // Relocate any markup that needs to be moved after selection
  codeMirror.replaceRange(accumulatedLeftMarkup, selectionRange.endLocation, null, '+')

  // Remove any markup that needs to be blasted
  const allMarkupRangesToRemove = markupRangesToMoveBeforeSelection.concat(markupRangesToMoveAfterSelection).concat(markupRangesToRemove).concat(unsplittableMarkupRangesToRemove)
  removeTextFromRanges(codeMirror, allMarkupRangesToRemove)

  // Relocate any markup that needs to be moved before selection
  codeMirror.replaceRange(accumulatedRightMarkup, selectionRange.startLocation, null, '+')

  // Adjust selection to account for adjustments made above.
  codeMirror.setSelection(
    selectionRange.startLocation.withOffset(0, accumulatedRightMarkup.length), 
    selectionRange.endLocation.withOffset(0, -getTextFromRanges(codeMirror, markupRangesToMoveAfterSelection.concat(markupRangesToRemove)).length),
    '+'
  )
  return true
}

// Need to remove in reverse order of appearance to avoid invalidating yet-to-be-removed ranges.
const removeTextFromRanges = (codeMirror, ranges) => {
  const reverseSortedRanges = Array.from(ranges).sort((a, b) => {
    return a.startLocation.lessThan(b.startLocation)
  })
  reverseSortedRanges.forEach(range => codeMirror.replaceRange('', range.startLocation, range.endLocation, '+'))
}

const getTextFromRanges = (codeMirror, ranges) => ranges.map(range => codeMirror.getRange(range.startLocation, range.endLocation)).join('')

const getExpandedSelectionRange = (codeMirror, markupItems, selectionRange) => {
  let newSelectionRange = selectionRange
  
  // If selectionRange starts inside a markup item's opening markup, the returned range start will be moved to start of opening markup.
  const selectionStartsInOpeningMarkupOfItem = markupItems.find(item => selectionRange.startsInsideRange(item.openingMarkupRange(), true))
  if (selectionStartsInOpeningMarkupOfItem) {
    newSelectionRange.startLocation = selectionStartsInOpeningMarkupOfItem.openingMarkupRange().startLocation
  } else {
    // If selectionRange starts inside a markup item's closing markup, the returned range start will be moved to end of closing markup.
    const selectionStartsInClosingMarkupOfItem = markupItems.find(item => selectionRange.startsInsideRange(item.closingMarkupRange(), true))
    if (selectionStartsInClosingMarkupOfItem) {
      newSelectionRange.startLocation = selectionStartsInClosingMarkupOfItem.closingMarkupRange().endLocation
    }
  }

  // If selectionRange ends inside a markup item's closing markup, the returned range end will be moved to end of closing markup.
  const selectionEndsInClosingMarkupOfItem = markupItems.find(item => selectionRange.endsInsideRange(item.closingMarkupRange(), true))
  if (selectionEndsInClosingMarkupOfItem) {
    newSelectionRange.endLocation = selectionEndsInClosingMarkupOfItem.closingMarkupRange().endLocation
  } else {
    // If selectionRange ends inside a markup item's opening markup, the returned range end will be moved to start of opening markup.
    const selectionEndsInOpeningMarkupOfItem = markupItems.find(item => selectionRange.endsInsideRange(item.openingMarkupRange(), true))
    if (selectionEndsInOpeningMarkupOfItem) {
      newSelectionRange.endLocation = selectionEndsInOpeningMarkupOfItem.openingMarkupRange().startLocation
    }
  }
  
  return newSelectionRange
}

const canSplitMarkupAroundSelectionRange = (codeMirror) => splitMarkupAroundSelectionRange(codeMirror, true)

const splitMarkupAroundSelectionRange = (codeMirror, evaluateOnly = false) => {
  const selectionRange = getItemRangeFromSelection(codeMirror)

  let markupItems = markupItemsForItemRangeLines(codeMirror, selectionRange)

  const markupItemOpeningOrClosingMarkupIntersectsSelectionRange = (item) => item.openingMarkupRange().intersectsRange(selectionRange, false) || item.closingMarkupRange().intersectsRange(selectionRange, false)

  const selectionIncludesAnyOpeningOrClosingMarkup = markupItems.find(markupItemOpeningOrClosingMarkupIntersectsSelectionRange) !== undefined

  if (selectionIncludesAnyOpeningOrClosingMarkup) {
    return false
  }

  const selectionIntersectsItemInnerRange = (item) => item.innerRange.intersectsRange(selectionRange, true)
  markupItems = markupItems.filter(selectionIntersectsItemInnerRange)// === undefined
  // Return if selection doesn't intersect with any markup items (selected word at end of line after last markup item etc).
  if (markupItems.length === 0) {
    return false
  }
  
  if (evaluateOnly) {
    return true
  }

  let markupRangesToAddBeforeSelection = []
  let markupRangesToAddAfterSelection = []

  markupItems.forEach(item => {
    markupRangesToAddBeforeSelection.unshift(item.closingMarkupRange())
    markupRangesToAddAfterSelection.push(item.openingMarkupRange())
  })

  let accumulatedLeftMarkup = getTextFromRanges(codeMirror, markupRangesToAddBeforeSelection)
  let accumulatedRightMarkup = getTextFromRanges(codeMirror, markupRangesToAddAfterSelection)

  // Work-around for cases which will result in empty markup items such as `<u></u>`, which, in some
  // cases, confuses the CodeMirror wikitext parsing. Injects a space inside such markup items so
  // they tokenize correctly can later be identified as whitespace-only and pruned. 
  if (selectionStartsAtOpeningMarkupEnd(markupItems, selectionRange)) {
    accumulatedLeftMarkup = ` ${accumulatedLeftMarkup}`
  }
  if (selectionEndsAtClosingMarkupStart(markupItems, selectionRange)) {
    accumulatedRightMarkup = `${accumulatedRightMarkup} `
  }

  // At selection end add opening tags.
  codeMirror.replaceRange(accumulatedRightMarkup, selectionRange.endLocation, null, '+')
  // At selection start add closing tags.
  codeMirror.replaceRange(accumulatedLeftMarkup, selectionRange.startLocation, null, '+')

  // Adjust selection.
  const origSelectionRangeLineExtent = selectionRange.endLocation.line - selectionRange.startLocation.line
  const origSelectionRangeChExtent = selectionRange.endLocation.ch - selectionRange.startLocation.ch
  const newSelectionRange = getItemRangeFromSelection(codeMirror)
  codeMirror.setSelection(
    newSelectionRange.startLocation, 
    newSelectionRange.startLocation.withOffset(origSelectionRangeLineExtent, origSelectionRangeChExtent),
    '+'
  )

  return true
}

const selectionStartsAtOpeningMarkupEnd = (markupItems, selectionRange) => markupItems.find(item => item.openingMarkupRange().endLocation.equals(selectionRange.startLocation)) !== undefined
const selectionEndsAtClosingMarkupStart = (markupItems, selectionRange) => markupItems.find(item => item.closingMarkupRange().startLocation.equals(selectionRange.endLocation)) !== undefined

// Safely prunes even items which end up empty as a result of pruning other nested items.
const pruneWhitespaceOnlyMarkupItems = (codeMirror) => {
  const itemContainsOnlyWhitespace = item => codeMirror.getRange(item.innerRange.startLocation, item.innerRange.endLocation).trim().length === 0
  const pruneItem = item => codeMirror.replaceRange('', item.outerRange.startLocation, item.outerRange.endLocation, '+')
  const selectionRange = getItemRangeFromSelection(codeMirror)
  let maxItemsToPrune = markupItemsForItemRangeLines(codeMirror, selectionRange).length
  while (maxItemsToPrune > 0) {
    let itemsToPrune = markupItemsForItemRangeLines(codeMirror, selectionRange).filter(itemContainsOnlyWhitespace)
    if (itemsToPrune.length === 0) {
      break
    }
    itemsToPrune.reverse().forEach(item => {
      pruneItem(item)
    })
    maxItemsToPrune = maxItemsToPrune - 1  
  }
}

exports.clearFormatting = clearFormatting
exports.canClearFormatting = canClearFormatting