(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
const markupItemsForLineTokens = require('./codemirror-range-determination').markupItemsForLineTokens

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

exports.showRangeDebuggingButtonsForCursorLine = showRangeDebuggingButtonsForCursorLine

},{"./codemirror-range-determination":4}],2:[function(require,module,exports){
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

},{"./codemirror-range-objects":6,"./codemirror-range-set-utilities":7}],3:[function(require,module,exports){
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

},{"./codemirror-range-objects":6}],4:[function(require,module,exports){

const tagMarkupItemsForLineTokens = require('./codemirror-range-determination-tag').tagMarkupItemsForLineTokens
const nonTagMarkupItemsForLineTokens = require('./codemirror-range-determination-non-tag').nonTagMarkupItemsForLineTokens

const markupItemsForLineTokens = (lineTokens, line) => {
  const tagMarkupItems = tagMarkupItemsForLineTokens(lineTokens, line)
  const nonTagMarkupItems = nonTagMarkupItemsForLineTokens(lineTokens, line)
  const markupItems = tagMarkupItems.concat(nonTagMarkupItems)
  return markupItems
}

exports.markupItemsForLineTokens = markupItemsForLineTokens

},{"./codemirror-range-determination-non-tag":2,"./codemirror-range-determination-tag":3}],5:[function(require,module,exports){
const RangeHelper = {}

RangeHelper.rangeDebugging = require('./codemirror-range-debugging')
RangeHelper.rangeDetermination = require('./codemirror-range-determination')
RangeHelper.rangeObjects = require('./codemirror-range-objects')

window.RangeHelper = RangeHelper
},{"./codemirror-range-debugging":1,"./codemirror-range-determination":4,"./codemirror-range-objects":6}],6:[function(require,module,exports){

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
    if (type === 'mw-apostrophes-italic') {
      return 'italic'
    }
    return type  
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
  
  endsInsideRange(range) {
    return (
      this.endLocation.greaterThanOrEquals(range.startLocation)
      &&
      this.endLocation.lessThanOrEquals(range.endLocation)
    )
  }
  
  startsInsideRange(range) {
    return (
      this.startLocation.greaterThanOrEquals(range.startLocation)
      &&
      this.startLocation.lessThanOrEquals(range.endLocation)
    )
  }

  intersectsRange(range) {
    return (
      this.endsInsideRange(range)
      ||
      this.startsInsideRange(range)
      ||
      range.endsInsideRange(this)
      ||
      range.startsInsideRange(this)
    )
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
}

exports.ItemRange = ItemRange
exports.MarkupItem = MarkupItem
exports.ItemLocation = ItemLocation

},{}],7:[function(require,module,exports){

const intersection = (a, b) => new Set([...a].filter(x => b.has(x)))
const difference = (a, b) => new Set([...a].filter(x => !b.has(x)))
const union = (a, b) => new Set([...a, ...b])

exports.intersection = intersection
exports.difference = difference
exports.union = union

},{}],8:[function(require,module,exports){
// const ItemRange = require('./codemirror-range-objects').ItemRange
// const ItemLocation = require('./codemirror-range-objects').ItemLocation




editor.on('cursorActivity', (doc) => {
console.log('wa')
/*
  sendNativeMessages(doc)

  clearTimeout(cursorActivityScrollTimer)
  cursorActivityScrollTimer = setTimeout(() => {
    scrollCursorIntoViewIfNeeded()        
  }, 25)
*/
})


/*
const rangesIntersect = (range1, range2) => {
  if (range1.start > range2.start + (range2.end - range2.start)) return false
  if (range2.start > range1.start + (range1.end - range1.start)) return false
  // const isSelected = ((Math.abs(range1.start - range1.end) > 0) && (Math.abs(range2.start - range2.end) > 0))
  // if ((range1.start === range2.end) || (range1.end === range2.start) && isSelected) return false
  return true
}

const getSelectionRange = (doc) => {
  const fromCursor = doc.getCursor('from')
  const toCursor = doc.getCursor('to')

  const start = fromCursor.ch
  const end = toCursor.ch
  const isSingleLine = (fromCursor.line === toCursor.line)
  const line = fromCursor.line
  const isRangeSelected = !isSingleLine || (end - start) > 0

  return {
    start,
    end,
    isSingleLine,
    line,
    isRangeSelected
  }
}

const tokensIntersectingSelection = (selectionRange, lineTokens) => {
  return lineTokens
    .filter(token => {
      return rangesIntersect(selectionRange, token)
    })
}
*/




// class ItemRange {
//   constructor(startLocation, endLocation) {
//     this.startLocation = startLocation
//     this.endLocation = endLocation
//   }
//   isComplete() {
//     return this.startLocation.isComplete() && this.endLocation.isComplete()
//   }
// }
// 
// class ItemLocation {
//   constructor(line, ch) {
//     this.line = line
//     this.ch = ch
//   }
//   isComplete() {
//     return this.line !== -1 && this.ch !== -1
//   }
// }

},{}]},{},[1,2,3,4,5,6,7,8]);
