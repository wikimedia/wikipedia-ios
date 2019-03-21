const ItemRange = require('./codemirror-range-objects').ItemRange
const ItemLocation = require('./codemirror-range-objects').ItemLocation

const getItemRangeFromSelection = require('./codemirror-range-utilities').getItemRangeFromSelection
const getMarkupItemsIntersectingSelection = require('./codemirror-range-utilities').getMarkupItemsIntersectingSelection
const getButtonNamesFromMarkupItems = require('./codemirror-range-utilities').getButtonNamesFromMarkupItems
const markupItemsForItemRangeLines = require('./codemirror-range-determination').markupItemsForItemRangeLines

const markupItemsStartingOrEndingInSelectionRange = (codeMirror, selectionRange) =>
  markupItemsForItemRangeLines(codeMirror, selectionRange).filter(item => item.innerRangeStartsOrEndsInRange(selectionRange, true))

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
  if (buttonNames.includes('reference') || buttonNames.includes('template')) {
    return false
  }
  
  return canRelocateOrRemoveExistingMarkupForSelectionRange(codeMirror) || canSplitMarkupAroundSelectionRange(codeMirror)
}

const clearFormatting = (codeMirror) => {
  relocateOrRemoveExistingMarkupForSelectionRange(codeMirror, false)
  splitMarkupAroundSelectionRange(codeMirror, false)
}

const canRelocateOrRemoveExistingMarkupForSelectionRange = (codeMirror) => relocateOrRemoveExistingMarkupForSelectionRange(codeMirror, true)

const relocateOrRemoveExistingMarkupForSelectionRange = (codeMirror, evaluateOnly = false) => {
  let selectionRange = getItemRangeFromSelection(codeMirror)
  const originalSelectionRange = selectionRange

  const markupItems = markupItemsStartingOrEndingInSelectionRange(codeMirror, selectionRange)
  
  selectionRange = getExpandedSelectionRange(codeMirror, markupItems, selectionRange)
  if (!evaluateOnly) {
    codeMirror.setSelection(selectionRange.startLocation, selectionRange.endLocation, '+')
  }

  const markupItemsIntersectingSelection = getMarkupItemsIntersectingSelection(codeMirror, markupItems, selectionRange)

  let markupRangesToMoveAfterSelection = []
  let markupRangesToMoveBeforeSelection = []
  let markupRangesToRemove = []
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
    const allMarkupRanges = openingMarkupRanges.concat(closingMarkupRanges)
    if (evaluateOnly) {
      return allMarkupRanges.length > 0
    }
    removeTextFromRanges(codeMirror, allMarkupRanges)
    return allMarkupRanges.length > 0
  }
  if (evaluateOnly) {
    return true
  }

  const accumulatedLeftMarkup = getTextFromRanges(codeMirror, markupRangesToMoveAfterSelection)
  const accumulatedRightMarkup = getTextFromRanges(codeMirror, markupRangesToMoveBeforeSelection)

  // Relocate any markup that needs to be moved after selection
  codeMirror.replaceRange(accumulatedLeftMarkup, selectionRange.endLocation, null, '+')

  // Remove any markup that needs to be blasted
  const allMarkupRangesToRemove = markupRangesToMoveBeforeSelection.concat(markupRangesToMoveAfterSelection).concat(markupRangesToRemove)
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

  // Work-around for cases which will result in empty markup items such as `<u></u>`.
  // Injects text inside such markup items so they can be identified and pruned. 
  // This also prevents a codemirror bug where it incorrectly tokenizes empty markup items.
  const removeMeMarker = 'R!E@M#O$V%E'
  const selectionStartsAtOpeningMarkupEnd = markupItems.find(item => item.openingMarkupRange().endLocation.equals(selectionRange.startLocation)) !== undefined
  if (selectionStartsAtOpeningMarkupEnd) {
    accumulatedLeftMarkup = `${removeMeMarker}${accumulatedLeftMarkup}`
  }
  const selectionEndsAtClosingMarkupStart = markupItems.find(item => item.closingMarkupRange().startLocation.equals(selectionRange.endLocation)) !== undefined
  if (selectionEndsAtClosingMarkupStart) {
    accumulatedRightMarkup = `${accumulatedRightMarkup}${removeMeMarker}`
  }

  // At selection end add opening tags.
  codeMirror.replaceRange(accumulatedRightMarkup, selectionRange.endLocation, null, '+')
  // At selection start add closing tags.
  codeMirror.replaceRange(accumulatedLeftMarkup, selectionRange.startLocation, null, '+')

  // Prune wikitext for items with 'removeMeMarker'.
  const updatedMarkupItems = markupItemsForItemRangeLines(codeMirror, selectionRange)
  const deleteItemWikitextIfMarkedForRemoval = (item) => {
    if (codeMirror.getRange(item.innerRange.startLocation, item.innerRange.endLocation) === removeMeMarker) {
      codeMirror.replaceRange('', item.outerRange.startLocation, item.outerRange.endLocation, '+')
    }
  }
  updatedMarkupItems.reverse().forEach(deleteItemWikitextIfMarkedForRemoval)

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

exports.clearFormatting = clearFormatting
exports.canClearFormatting = canClearFormatting