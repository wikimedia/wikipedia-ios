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
  for (let line = range.startLocation.line; line <= range.endLocation.line; line++) {
    const tokens = codeMirror.getLineTokens(line, true)
    const items = markupItemsForLineTokens(tokens, line)
    markupItems.push(...items)
  }
  return markupItems
}

exports.markupItemsForLineTokens = markupItemsForLineTokens
exports.markupItemsForItemRangeLines = markupItemsForItemRangeLines