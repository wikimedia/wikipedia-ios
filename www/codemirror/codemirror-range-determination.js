const tagMarkupItemsForLineTokens = require('./codemirror-range-determination-tag').tagMarkupItemsForLineTokens
const nonTagMarkupItemsForLineTokens = require('./codemirror-range-determination-non-tag').nonTagMarkupItemsForLineTokens
const ItemRange = require('./codemirror-range-objects').ItemRange

const markupItemsForLineTokens = (lineTokens, line) => {
  const tagMarkupItems = tagMarkupItemsForLineTokens(lineTokens, line)
  const nonTagMarkupItems = nonTagMarkupItemsForLineTokens(lineTokens, line)
  const markupItems = tagMarkupItems.concat(nonTagMarkupItems)
  return markupItems
}

// Gets all markup items for ALL lines between range's start and end. 
// May include markup items to left of range start or right range end.
const markupItemsForItemRangeLines = (codeMirror, range) => {
  let markupItems = []
  range.lineNumbers().forEach(lineNumber => {
    const tokens = codeMirror.getLineTokens(lineNumber, true)
    const items = markupItemsForLineTokens(tokens, lineNumber)
    markupItems.push(...items)
  })
  return markupItems.sort((a, b) => {
    return a.openingMarkupRange().startLocation.greaterThan(b.openingMarkupRange().startLocation)
  })
}

exports.markupItemsForLineTokens = markupItemsForLineTokens
exports.markupItemsForItemRangeLines = markupItemsForItemRangeLines
