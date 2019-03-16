const ItemRange = require('./codemirror-range-objects').ItemRange
const ItemLocation = require('./codemirror-range-objects').ItemLocation

const getItemRangeFromSelection = (codeMirror) => {
  const fromCursor = codeMirror.getCursor('from')
  const toCursor = codeMirror.getCursor('to')
  const fromLocation = new ItemLocation(fromCursor.line, fromCursor.ch)
  const toLocation = new ItemLocation(toCursor.line, toCursor.ch)
  const selectionRange = new ItemRange(fromLocation, toLocation)
  return selectionRange
}

const getMarkupItemsIntersectingSelection = (codeMirror, markupItems, selectionRange) => {
  const itemIntersectsSelection = item => item.outerRange.intersectsRange(selectionRange, true)
  const itemDoesNotStartsAtSelectionEnd = item => !item.openingMarkupRange().startLocation.equals(selectionRange.endLocation)
  const itemDoesNotEndAtSelectionStart = item => !item.closingMarkupRange().endLocation.equals(selectionRange.startLocation)
  return markupItems
    .filter(itemIntersectsSelection)
    .filter(itemDoesNotStartsAtSelectionEnd)
    .filter(itemDoesNotEndAtSelectionStart)
}

const getButtonNamesFromMarkupItems = (markupItems) => markupItems.map(item => item.buttonName)

/*
TODO: add generic (non-regex or otherwise string aware) functional methods here for: 
- unwrapping existing markup item (i.e. turning off something like bold)
    would simply look at the item's inner and outer range and replace the code mirror string from the
    outer range with the code mirror string from the inner range,
- others t.b.d. - need to think a bit more about best way to implement wrapping related method(s)
*/

exports.getItemRangeFromSelection = getItemRangeFromSelection
exports.getMarkupItemsIntersectingSelection = getMarkupItemsIntersectingSelection
exports.getButtonNamesFromMarkupItems = getButtonNamesFromMarkupItems
