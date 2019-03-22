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
