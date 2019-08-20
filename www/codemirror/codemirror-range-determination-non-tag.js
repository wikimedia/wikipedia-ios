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
  const soughtBoundaryTokenTypes = new Set(['mw-apostrophes-bold', 'mw-apostrophes-italic', 'mw-link-bracket', 'mw-section-header', 'mw-template-bracket'])  
  const soughtTokenTypes = new Set(['mw-template-bracket', 'mw-template-name', 'mw-template-argument-name', 'mw-template-delimiter'])

  let trackedTypes = new Set()
  let outputMarkupItems = []
  
  const tokenWithEnrichedInHtmlTagArray = (token, index, tokens) => {
    
    const boundaryTypes = intersection(tokenTypes(token), soughtBoundaryTokenTypes)
    const types = intersection(tokenTypes(token), soughtTokenTypes)
  
    const typesToStopTracking = Array.from(intersection(trackedTypes, boundaryTypes))
    const typesToStartTracking = Array.from(difference(boundaryTypes, trackedTypes))
    
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
    
    const addCompleteMarkupRanges = (type) => {
      const inner = new ItemRange(new ItemLocation(line, token.start), new ItemLocation(line, token.end))
      const outer = new ItemRange(new ItemLocation(line, token.start), new ItemLocation(line, token.end))
      const markupItem = new MarkupItem(type, inner, outer)
      outputMarkupItems.push(markupItem)
    }
    
    typesToStartTracking.forEach(addMarkupItemWithRangeStarts)
    typesToStopTracking.forEach(updateMarkupItemRangeEnds)
    types.forEach(addCompleteMarkupRanges)
    
    typesToStopTracking.forEach(tag => trackedTypes.delete(tag))
    typesToStartTracking.forEach(tag => trackedTypes.add(tag))
  }
  
  lineTokens.forEach(tokenWithEnrichedInHtmlTagArray)
  
  correctForCodeMirrorBoldItalicNestingBugsIfNeeded(outputMarkupItems)
  
  return outputMarkupItems
}

// Codemirror incorrectly tokenizes end tokens for italic markup ('') nested inside bold markup (''') in some cases.
// Example strings:
//  Hello '''''there''''' one
//  Hello '''x''there''''' two
// This method detects such instances and corrects inner and outer range end locations.
const correctForCodeMirrorBoldItalicNestingBugsIfNeeded = (markupItems) => {
  const aStartsInsideBAndEndsExactlyAfterB = (a, b) => a.outerRange.startsInsideRange(b.innerRange, true) && a.innerRange.endLocation.equals(b.outerRange.endLocation)
  const isItemItalic = item => item.buttonName === 'italic'
  const isItemBold = item => item.buttonName === 'bold'
  const soughtItalicItemForBoldItem = boldItem => markupItems
    .filter(isItemItalic)
    .find(italicItem => {
      return aStartsInsideBAndEndsExactlyAfterB(italicItem, boldItem)
    })
  const adjustBoldItalicPair = pair => {
    adjustMarkupItemInnerAndOuterRangeEndLocations(pair.boldItem, 2)
    adjustMarkupItemInnerAndOuterRangeEndLocations(pair.italicItem, -3)
  }
  const adjustMarkupItemInnerAndOuterRangeEndLocations = (markupItem, endLocationsOffset) => {
    markupItem.innerRange.endLocation.ch = markupItem.innerRange.endLocation.ch + endLocationsOffset
    markupItem.outerRange.endLocation.ch = markupItem.outerRange.endLocation.ch + endLocationsOffset
  }
  
  // Finds bold and italic pairs where:
  //  - bold contains the italic start
  //  - italic inner range end location equals the bold outer range end location
  // Then makes needed adjustments on these pairs.
  markupItems
    .filter(isItemBold)
    .map(boldItem => {
      const italicItem = soughtItalicItemForBoldItem(boldItem)
      return (italicItem !== undefined) ? {boldItem, italicItem} : null
    })
    .filter(maybePair => maybePair !== null)
    .forEach(adjustBoldItalicPair)
}

exports.nonTagMarkupItemsForLineTokens = nonTagMarkupItemsForLineTokens
