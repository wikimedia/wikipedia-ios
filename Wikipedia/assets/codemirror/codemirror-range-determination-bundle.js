(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
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
},{"./codemirror-range-determination":5,"./codemirror-range-utilities":9}],2:[function(require,module,exports){
const markupItemsForLineTokens = require('./codemirror-range-determination').markupItemsForLineTokens

// Uncomment the chunk below to add debugging buttons to top of article wikitext editor.

/*
setTimeout(() => {
  showRangeDebuggingButtonsForCursorLine(editor)
}, 1000)
*/

let markupItems = []
let currentItemIndex = 0
let highlightHandle = null
let useOuter = true
let codeMirror = null

const addButton = (title, tapClosure) => {
  const button = document.createElement('button')
  button.innerHTML = title
  document.body.insertBefore(button, document.body.firstChild)
  button.addEventListener ('click', tapClosure)
}

const clearItems = () => {
  markupItems = []
}

const clearHighlightHandle = () => {
  if (highlightHandle) {
    highlightHandle.clear()
  }
  highlightHandle = null
}

const reset = () => {
  clearHighlightHandle()
  clearItems()    
}

const kickoff = () => {
  reset()
  const line = codeMirror.getCursor().line
  const lineTokens = codeMirror.getLineTokens(line, true)
  markupItems = markupItemsForLineTokens(lineTokens, line)
  highlightTextForMarkupItemAtIndex(currentItemIndex)
}

const rangeDebuggingCSSClassName = 'range-debugging'

function addRangeDebuggingStyleOnce() {
  const id = 'debugging-style-element'
  if (document.getElementById(id)) {
    return
  }
  const cssNode = document.createElement('style')
  cssNode.id = id
  cssNode.innerHTML = `.${rangeDebuggingCSSClassName} { background-color: #cccccc; }`
  document.body.appendChild(cssNode)
}

const showRangeDebuggingButtonsForCursorLine = (cm) => {
  codeMirror = cm
  
  addRangeDebuggingStyleOnce()
  
  addButton('reset', () => {
    reset()
    currentItemIndex = 0
    console.log('reset')    
  })

  addButton('>', () => {
    clearHighlightHandle()
    currentItemIndex = currentItemIndex + 1
    if (currentItemIndex > (markupItems.length - 1)) {
      currentItemIndex = markupItems.length - 1
    }
    highlightTextForMarkupItemAtIndex(currentItemIndex)    
    console.log('next')    
  })

  addButton('<', () => {
    clearHighlightHandle()
    currentItemIndex = currentItemIndex - 1
    if (currentItemIndex < 0) {
      currentItemIndex = 0
    }
    highlightTextForMarkupItemAtIndex(currentItemIndex)    
    console.log('prev')    
  })

  addButton('test outer', () => {
    useOuter = true
    kickoff()
  })

  addButton('test inner', () => {
    useOuter = false
    kickoff()
  })
  
  const span = document.createElement('span')
  span.innerHTML = 'Tap line, then tap:'
  document.body.insertBefore(span, document.body.firstChild)
}

const highlightTextForMarkupItemAtIndex = (index) => {
  if (markupItems.length === 0) {
    return
  }

  const markupItem = markupItems[index]
  const range = useOuter ? markupItem.outerRange : markupItem.innerRange

  clearHighlightHandle()
  highlightHandle = codeMirror.markText(range.startLocation, range.endLocation, {
    className: rangeDebuggingCSSClassName
  })
}

},{"./codemirror-range-determination":5}],3:[function(require,module,exports){
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

},{"./codemirror-range-objects":7,"./codemirror-range-set-utilities":8}],4:[function(require,module,exports){
const ItemRange = require('./codemirror-range-objects').ItemRange
const MarkupItem = require('./codemirror-range-objects').MarkupItem
const ItemLocation = require('./codemirror-range-objects').ItemLocation

const isTokenForTagBracket = (token) => tokenIncludesType(token, 'mw-htmltag-bracket') || tokenIncludesType(token, 'mw-exttag-bracket')
const isTokenStartOfOpenTag = (token) => isTokenForTagBracket(token) && token.string === '<'
const isTokenEndOfOpenTag = (token) => isTokenForTagBracket(token) && token.string === '>'  
const isTokenStartOfCloseTag = (token) => isTokenForTagBracket(token) && token.string === '</'  

const getOpenTagStartTokenIndices = (lineTokens) => {
  let openTagStartTokenIndices = []
  const possiblyRecordOpenTagTokenIndex = (token, index) => {
    if (isTokenStartOfOpenTag(token)) {
      openTagStartTokenIndices.push(index)
    }
  }
  lineTokens.forEach(possiblyRecordOpenTagTokenIndex)
  return openTagStartTokenIndices
}

const getOpenTagEndTokenIndices = (lineTokens, openTagStartTokenIndices) => {
  const getOpenTagEndTokenIndex = (openTagStartTokenIndex) => {
    return lineTokens.findIndex((t, i) => {
      return i > openTagStartTokenIndex && isTokenEndOfOpenTag(t)
    })
  }
  return openTagStartTokenIndices.map(getOpenTagEndTokenIndex)
}

const tagMarkupItemsForLineTokens = (lineTokens, line) => {
  const openTagStartTokenIndices = getOpenTagStartTokenIndices(lineTokens)    
  const tagTypeTokenIndices = openTagStartTokenIndices.map(i => i + 1)
  const openTagEndTokenIndices = getOpenTagEndTokenIndices(lineTokens, openTagStartTokenIndices)

  const closeTagStartTokenIndices = getCloseTagStartTokenIndices(lineTokens, openTagEndTokenIndices)    
  const closeTagEndTokenIndices = closeTagStartTokenIndices.map(i => i + 2)

  let output = []
  const tagCount = openTagStartTokenIndices.length
  
  for (let i = 0; i < tagCount; i++) { 
    const openTagStartTokenIndex = openTagStartTokenIndices[i]
    const tagTypeTokenIndex = tagTypeTokenIndices[i]
    const openTagEndTokenIndex = openTagEndTokenIndices[i]
    const closeTagStartTokenIndex = closeTagStartTokenIndices[i]
    const closeTagEndTokenIndex = closeTagEndTokenIndices[i]

    if (
      openTagStartTokenIndex === undefined ||
      tagTypeTokenIndex === undefined ||
      openTagEndTokenIndex === undefined ||
      closeTagStartTokenIndex === undefined ||
      closeTagEndTokenIndex === undefined
    ) {
      continue
    }

    let outer = new ItemRange(new ItemLocation(line, lineTokens[openTagStartTokenIndex].start), new ItemLocation(line, lineTokens[closeTagEndTokenIndex].end))
    let inner = new ItemRange(new ItemLocation(line, lineTokens[openTagEndTokenIndex].end), new ItemLocation(line, lineTokens[closeTagStartTokenIndex].start))
    let type = lineTokens[tagTypeTokenIndex].string.trim()
    output.push(new MarkupItem(type, inner, outer))
  }
  return output
}

const getCloseTagStartTokenIndices = (lineTokens, openTagEndTokenIndices) => {
  let closeTagStartTokenIndices = []
  
  openTagEndTokenIndices.forEach(openTagEndTokenIndex => {
    let depth = 0
    for (let i = openTagEndTokenIndex + 1; i < lineTokens.length; i++) { 
      let thisToken = lineTokens[i]
      if (isTokenStartOfOpenTag(thisToken)){
        depth = depth + 1
      } else if (isTokenStartOfCloseTag(thisToken)) {
        if (depth === 0) {
          closeTagStartTokenIndices.push(i)
          break
        }
        depth = depth - 1        
      }
    }
    
  })
  
  return closeTagStartTokenIndices
}

exports.tagMarkupItemsForLineTokens = tagMarkupItemsForLineTokens

},{"./codemirror-range-objects":7}],5:[function(require,module,exports){
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

},{"./codemirror-range-determination-non-tag":3,"./codemirror-range-determination-tag":4,"./codemirror-range-objects":7}],6:[function(require,module,exports){
const RangeHelper = {}

RangeHelper.rangeDebugging = require('./codemirror-range-debugging')
RangeHelper.rangeDetermination = require('./codemirror-range-determination')
RangeHelper.rangeObjects = require('./codemirror-range-objects')
RangeHelper.rangeUtilities = require('./codemirror-range-utilities')
RangeHelper.rangeClearFormatting = require('./codemirror-range-clear-formatting')
RangeHelper.getMarkupItemsIntersectingSelection = require('./codemirror-range-utilities').getMarkupItemsIntersectingSelection
RangeHelper.getItemRangeFromSelection = require('./codemirror-range-utilities').getItemRangeFromSelection
RangeHelper.markupItemsForItemRangeLines = require('./codemirror-range-determination').markupItemsForItemRangeLines


window.RangeHelper = RangeHelper
},{"./codemirror-range-clear-formatting":1,"./codemirror-range-debugging":2,"./codemirror-range-determination":5,"./codemirror-range-objects":7,"./codemirror-range-utilities":9}],7:[function(require,module,exports){

class MarkupItem {
  constructor(type, innerRange, outerRange) {
    this.type = type
    this.innerRange = innerRange
    this.outerRange = outerRange
    this.buttonName = MarkupItem.buttonNameForType(type)
  }
  isComplete() {
    return this.innerRange.isComplete() && this.outerRange.isComplete()
  }
  static buttonNameForType(type) {
    if (type === 'mw-apostrophes-bold') {
      return 'bold'
    }
    if (type === 'mw-section-header') {
      return 'header'
    }
    if (type === 'mw-link-bracket') {
      return 'link'
    }
    if (type === 'mw-template-bracket') {
      return 'template'
    }
    if (type === 'mw-template-argument-name') {
      return 'template-argument'
    }
    if (type === 'mw-template-name') {
      return 'template-name'
    }
    if (type == 'mw-template-delimiter') {
      return 'template-delimiter'
    }
    if (type === 'mw-apostrophes-italic') {
      return 'italic'
    }
    if (type === 'ref') {
      return 'reference'
    }
    return type  
  }
  
  openingMarkupRange() {
    return new ItemRange(
      this.outerRange.startLocation, 
      this.innerRange.startLocation
    )
  }
  
  closingMarkupRange() {
    return new ItemRange(
      this.innerRange.endLocation, 
      this.outerRange.endLocation
    )    
  }

  innerRangeStartsOrEndsInRange(range, allowEdgeOverlap = false) {
    return this.innerRange.startsInsideRange(range, allowEdgeOverlap) || this.innerRange.endsInsideRange(range, allowEdgeOverlap)
  }
}

class ItemRange {
  constructor(startLocation, endLocation) {
    this.startLocation = startLocation
    this.endLocation = endLocation
  }
  isComplete() {
    return this.startLocation.isComplete() && this.endLocation.isComplete()
  }

  endsInsideRange(range, allowEdgeOverlap = false) {
    return allowEdgeOverlap ?
      this.endLocation.greaterThanOrEquals(range.startLocation) && this.endLocation.lessThanOrEquals(range.endLocation) :
      this.endLocation.greaterThan(range.startLocation) && this.endLocation.lessThan(range.endLocation)
  }
  
  startsInsideRange(range, allowEdgeOverlap = false) {
    return allowEdgeOverlap ? 
      this.startLocation.greaterThanOrEquals(range.startLocation) && this.startLocation.lessThanOrEquals(range.endLocation) :
      this.startLocation.greaterThan(range.startLocation) && this.startLocation.lessThan(range.endLocation)
  }

  intersectsRange(range, allowEdgeOverlap = false) {
    return (
      this.endsInsideRange(range, allowEdgeOverlap)
      ||
      this.startsInsideRange(range, allowEdgeOverlap)
      ||
      range.endsInsideRange(this, allowEdgeOverlap)
      ||
      range.startsInsideRange(this, allowEdgeOverlap)
    )
  }

  isZeroLength() {
    return this.startLocation.line === this.endLocation.line && this.startLocation.ch === this.endLocation.ch
  }
  
  lineNumbers() {
    const startLine = this.startLocation.line
    const endLine = this.endLocation.line
    return new Array(endLine - startLine + 1).fill().map((d, i) => i + startLine)
  }
}

class ItemLocation {
  constructor(line, ch) {
    this.line = line
    this.ch = ch
  }
  isComplete() {
    return this.line !== -1 && this.ch !== -1
  }
  greaterThan(location) {
    if (this.line < location.line) {
      return false
    }
    if (this.line === location.line && this.ch <= location.ch) {
      return false
    }
    return true
  }
  lessThan(location) {
    if (this.line > location.line) {
      return false
    }
    if (this.line === location.line && this.ch >= location.ch) {
      return false
    }
    return true
  }
  equals(location) {
    return (this.line === location.line && this.ch === location.ch)
  }
  greaterThanOrEquals(location) {
    return this.greaterThan(location) || this.equals(location)
  }
  lessThanOrEquals(location) {
    return this.lessThan(location) || this.equals(location)
  }
  withOffset(line, ch) {
    return new ItemLocation(this.line + line, this.ch + ch)
  }
}

exports.ItemRange = ItemRange
exports.MarkupItem = MarkupItem
exports.ItemLocation = ItemLocation

},{}],8:[function(require,module,exports){

// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set

// Returns set containing items that exist in both sets.
const intersection = (a, b) => new Set([...a].filter(x => b.has(x)))

// Returns set containing items that exist only in the first set and not in both sets.
const difference = (a, b) => new Set([...a].filter(x => !b.has(x)))

// Returns set containing all items from both sets, without dupes.
const union = (a, b) => new Set([...a, ...b])

// Returns true if all items set b are in set a.
const isSuperset = (a, b) => {
  for (let e of b) {
    if (!a.has(e)) {
      return false
    }
  }
  return true
}

// Returns set containing all items from both sets, except items that are present in both sets.
const symmetricDifference = (a, b) => {
  let diff = new Set(a)
  for (let e of b) {
    if (diff.has(e)) {
      diff.delete(e)
    } else {
      diff.add(e)
    }
  }
  return diff
}

exports.intersection = intersection
exports.difference = difference
exports.union = union
exports.isSuperset = isSuperset
exports.symmetricDifference = symmetricDifference

},{}],9:[function(require,module,exports){
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

},{"./codemirror-range-objects":7}]},{},[1,2,3,4,5,6,7,8,9]);
