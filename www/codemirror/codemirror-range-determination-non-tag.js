const intersection = require('./codemirror-range-set-utilities').intersection
const difference = require('./codemirror-range-set-utilities').difference
const ItemRange = require('./codemirror-range-objects').ItemRange
const MarkupItem = require('./codemirror-range-objects').MarkupItem
const ItemLocation = require('./codemirror-range-objects').ItemLocation

// - returns set of types for token
// - smooths out inconsistent nested bold and italic types
const tokenTypes = (token) => {
  const types = (token.type || '')
    .trim()
    .split(' ')
    .filter(s => s.length > 0)
    .map(s => {
      // the parser fails to add 'mw-apostrophes-bold' for nested bold (it only adds 'mw-apostrophes')
      if (s === 'mw-apostrophes' && token.string === `'''`) {
        return 'mw-apostrophes-bold'
      }
      // the parser fails to add 'mw-apostrophes-italic' for nested italic (it only adds 'mw-apostrophes')
      if (s === 'mw-apostrophes' && token.string === `''`) {
        return 'mw-apostrophes-italic'
      }
      return s
    })

  return new Set(types)
}

const nonTagMarkupItemsForLineTokens = (lineTokens, line) => {
  const soughtTokenTypes = new Set(['mw-apostrophes-bold', 'mw-apostrophes-italic', 'mw-link-bracket', 'mw-section-header', 'mw-template-bracket'])  

  let trackedTypes = new Set()
  let outputMarkupItems = []
  
  const tokenWithEnrichedInHtmlTagArray = (token, index, tokens) => {
    
    const types = intersection(tokenTypes(token), soughtTokenTypes)
    
    const typesToStopTracking = Array.from(intersection(trackedTypes, types))
    const typesToStartTracking = Array.from(difference(types, trackedTypes))
    
    const addMarkupItemWithRangeStarts = (type) => {
      const inner = new ItemRange(new ItemLocation(line, token.end), new ItemLocation(line, -1))
      const outer = new ItemRange(new ItemLocation(line, token.start), new ItemLocation(line, -1))
      const markupItem = new MarkupItem(type, inner, outer)
      outputMarkupItems.push(markupItem)
    }
    
    const updateMarkupItemRangeEnds = (type) => {
      const markupItem = outputMarkupItems.find(markupItem => {
        return markupItem.type === type && !markupItem.isComplete()
      })
      if (markupItem) {
        markupItem.innerRange.endLocation.ch = token.start
        markupItem.outerRange.endLocation.ch = token.end
      }
    }
    
    typesToStartTracking.forEach(addMarkupItemWithRangeStarts)
    typesToStopTracking.forEach(updateMarkupItemRangeEnds)
    
    typesToStopTracking.forEach(tag => trackedTypes.delete(tag))
    typesToStartTracking.forEach(tag => trackedTypes.add(tag))
  }
  
  lineTokens.forEach(tokenWithEnrichedInHtmlTagArray)    
  return outputMarkupItems
}

exports.nonTagMarkupItemsForLineTokens = nonTagMarkupItemsForLineTokens
