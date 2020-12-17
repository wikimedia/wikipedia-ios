
//*****BEGIN: index-main.js

const wmf = {}

wmf.elementLocation = {}
wmf.utilities = {}
wmf.findInPage = {}
wmf.editTextSelection = {}

window.wmf = wmf

//*****END: codemirror-range-objects.js

//*****BEGIN: utilities.js

const accessibilityCursorToFragment = fragmentId => {
  /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
  const focus_element = document.getElementById(fragmentId)
  const other_element = document.body
  other_element.setAttribute('tabindex', 0)
  other_element.focus()
  focus_element.setAttribute('tabindex', 0)
  focus_element.focus()
}

//*****END: utilities.js

//*****BEGIN: editTextSelection.js

class SelectedTextEditInfo {
  constructor(selectedAndAdjacentText, isSelectedTextInTitleDescription, sectionID, descriptionSource) {
    this.selectedAndAdjacentText = selectedAndAdjacentText
    this.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
    this.sectionID = sectionID
    this.descriptionSource = descriptionSource
  }
}

const getClosestFromSelection = (selection, selector) => {
  if (!selection) {
    return null
  }
  if (!selection.anchorNode) {
    return null
  }
  if (!selection.anchorNode.parentElement) {
    return null
  }
  return selection.anchorNode.parentElement.closest(selector)
}

const isSelectedTextInTitleDescription = selection => getClosestFromSelection(selection, 'p#pcs-edit-section-title-description') != null

const isSelectedTextInArticleTitle = selection  => getClosestFromSelection(selection, 'h1.pcs-edit-section-title') != null

const getSelectedTextSectionID = selection => {
  const section = getClosestFromSelection(selection, 'section[data-mw-section-id]')
  if (!section) {
    return null
  }
  const sectionIDString = section.getAttribute('data-mw-section-id')
  if (sectionIDString == null) {
    return null
  }
  return parseInt(sectionIDString)
}

const getSelectedTextEditInfo = () => {
  const selection = window.getSelection()

  const isTitleDescriptionSelection = isSelectedTextInTitleDescription(selection)
  let sectionID = 0
  if (!isTitleDescriptionSelection) {
    sectionID = getSelectedTextSectionID(selection)
  }

  let selectedAndAdjacentText = isSelectedTextInArticleTitle(selection) ? new SelectedAndAdjacentText('', '', '') : getSelectedAndAdjacentText().reducedToSpaceSeparatedWordsOnly()

  selection.removeAllRanges()
  selection.empty()

  // EditTransform.IDS.TITLE_DESCRIPTION == 'pcs-edit-section-title-description'
  const descriptionElement = document.getElementById('pcs-edit-section-title-description')
  // EditTransform.DATA_ATTRIBUTE.DESCRIPTION_SOURCE == 'data-description-source'
  const descriptionSource = descriptionElement && descriptionElement.getAttribute('data-description-source') || undefined

  return new SelectedTextEditInfo(
    selectedAndAdjacentText,
    isTitleDescriptionSelection,
    sectionID,
    descriptionSource
  )
}

const stringWithoutParenthesisForString = s => s.replace(/\([^\(\)]*\)/g, ' ')
const stringWithoutReferenceForString = s => s.replace(/\[[^\[\]]*\]/g, ' ')

// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `codemirror-editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
  // Reduces to space separated words only and only keeps a couple adjacent before and after words.
  reducedToSpaceSeparatedWordsOnly() {
    const separator = ' '
    const wordsOnlyForString = s => stringWithoutParenthesisForString(stringWithoutReferenceForString(s)).replace(/[\W]+/g, separator).trim().split(separator)

    return new SelectedAndAdjacentText(
      wordsOnlyForString(this.selectedText).join(separator),
      wordsOnlyForString(this.textBeforeSelectedText).join(separator),
      wordsOnlyForString(this.textAfterSelectedText).join(separator)
    )
  }
}

const getSelectedAndAdjacentText = () => {
  const selection = window.getSelection()
  const range = selection.getRangeAt(0)
  const selectedText = range.toString()
  selection.modify('extend', 'backward', 'sentenceboundary')
  const textBeforeSelectedText = window.getSelection().getRangeAt(0).toString().slice(0, -selectedText.length)
  selection.modify('extend', 'forward', 'sentenceboundary')
  const textAfterSelectedText = window.getSelection().getRangeAt(0).toString()
  window.getSelection().removeAllRanges()
  window.getSelection().addRange(range)
  return new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
}

//*****END: editTextSelection.js
//*****BEGIN: elementLocation.js

//  Used by methods in "UIWebView+ElementLocation.h" category.

class SectionFilter {
  acceptNode(node) {
    return node.tagName === 'SECTION'
  }
}

const headerTagRegex = /^H[0-9]$/

class HeaderFilter {
  acceptNode(node) {
    return node.tagName && headerTagRegex.test(node.tagName)
  }
}

const getAnchorForSection = section => {
  let node
  let anchor = ''
  const sectionWalker = document.createTreeWalker(section, NodeFilter.SHOW_ELEMENT, new HeaderFilter())
  while (node = sectionWalker.nextNode()) {
    if (!node.id) {
      continue
    }
    anchor = node.id
    break
  }
  return anchor
}

const getFirstOnScreenSection = insetTop => {
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT, new SectionFilter())
  let node
  let id = -1
  let anchor = ''
  let section
  while (node = walker.nextNode()) {
    const rect = node.getBoundingClientRect()
    if (rect.top > insetTop + 1) {
      if (!section) {
        continue
      }
      anchor = getAnchorForSection(section)
      break
    }
    const sectionIdString = node.getAttribute('data-mw-section-id')
    if (!sectionIdString) {
      continue
    }
    id = parseInt(sectionIdString)
    section = node
  }
  return {id, anchor}
}

const getImageWithSrc = src => document.querySelector(`img[src$="${src}"]`)

const getElementRect = element => {
  const rect = element.getBoundingClientRect()
  // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
  return {
    Y: rect.top,
    X: rect.left,
    Width: rect.width,
    Height: rect.height
  }
}

const getIndexOfFirstOnScreenElement = (elementPrefix, elementCount, insetTop) => {
  for (let i = 0; i < elementCount; ++i) {
    const div = document.getElementById(elementPrefix + i)
    if (div === null) {
      continue
    }
    const rect = this.getElementRect(div)
    if (rect.Y > insetTop + 1 || rect.Y + rect.Height > insetTop + 1) {
      return i
    }
  }
  return -1
}

const getElementFromPoint = (x, y) => document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)

const isElementTopOnscreen = element => element.getBoundingClientRect().top < 0

//*****END: elementLocation.js
//*****BEGIN: findInPage.js

// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

let PreviousFocusMatchSpanId = null

const deFocusPreviouslyFocusedSpan = () => {
  if (PreviousFocusMatchSpanId) {
    document.getElementById(PreviousFocusMatchSpanId).classList.remove('findInPageMatch_Focus')
    PreviousFocusMatchSpanId = null
  }
}

const removeSearchTermHighlight = highlightElement => {
  highlightElement.parentNode.insertBefore(highlightElement.removeChild(highlightElement.firstChild), highlightElement)
  highlightElement.parentNode.removeChild(highlightElement)
}

const removeSearchTermHighlights = () => {
  // const startTime = new Date()
  deFocusPreviouslyFocusedSpan()
  walkBackwards(document.body, NodeFilter.SHOW_ELEMENT, searchTermHighlightFilter, removeSearchTermHighlight)
  document.normalize()
  // printTimeElapsedDebugMessage('CLEAR', startTime)
}

const addSearchTermHighlight = (idx, textNode, searchTerm) => {
  const value = textNode.nodeValue
  const span = document.createElement('span')
  let newTextNode = document.createTextNode(value.substr(idx, searchTerm.length))
  span.appendChild(newTextNode)
  span.setAttribute('class', 'findInPageMatch')
  span.setAttribute('id', `find|${ Math.random().toString(36).substring(2, 9) }`)
  newTextNode = document.createTextNode(value.substr(idx + searchTerm.length))
  textNode.deleteData(idx, value.length - idx)
  const nextNode = textNode.nextSibling
  textNode.parentNode.insertBefore(span, nextNode)
  textNode.parentNode.insertBefore(newTextNode, nextNode)
  return newTextNode
}

const addSearchTermHighlights = (textNode, searchTerm) => {
  let idx = -1, currentTextNode = textNode
  while ((idx = searchTermIndex(currentTextNode, searchTerm)) > -1) {
    currentTextNode = addSearchTermHighlight(idx, currentTextNode, searchTerm)
  }
}

const searchTermIndex = (textNode, searchTerm) => textNode.nodeValue.toLowerCase().indexOf(searchTerm)

const searchTermHighlightFilter = node => {
  if (node.tagName !== 'SPAN') {
    return NodeFilter.FILTER_SKIP
  }
  if (node.className !== 'findInPageMatch') {
    return NodeFilter.FILTER_SKIP
  }
  return NodeFilter.FILTER_ACCEPT
}

const walkBackwards = (startAt, whatToExamine, filter, action) => {
  let node, nodes = [], walker = document.createTreeWalker(startAt, whatToExamine, filter, false)
  // TreeWalker.nextNode() returns nodes in order of appearance.
  while (node = walker.nextNode()) nodes.push(node)
  for (let i = nodes.length - 1; i >= 0; i--) {
    action(nodes[i])
  }
}

const tagsToIgnore = new Set(['AUDIO', 'BASE', 'BR', 'CANVAS', 'HEAD', 'HTML', 'IMG', 'META', 'OL', 'SCRIPT', 'SELECT', 'STYLE', 'TR', 'UL'])

const findAndHighlightAllMatchesForSearchTerm = searchTerm => {
  removeSearchTermHighlights()
  searchTerm = searchTerm.trim()
  if (searchTerm.length === 0) {
    return []
  }

  // const startTime = new Date()
  const matchMarker = node => addSearchTermHighlights(node, searchTerm.toLowerCase())
  const matchFilter = node => !tagsToIgnore.has(node.parentElement.tagName)
  walkBackwards(document.body, NodeFilter.SHOW_TEXT, matchFilter, matchMarker)

  const orderedMatchIDsToReport = [...document.querySelectorAll('span.findInPageMatch')].map(element => element.id)
  return orderedMatchIDsToReport
  // printTimeElapsedDebugMessage('SET', startTime)
}

/*
const printTimeElapsedDebugMessage = (string, startTime) => {
  let div = document.querySelector('div#debugPanel')
  if (!div) {
    div = document.createElement('div')
    div.id = 'debugPanel'
    div.style = `
      position: fixed;
      top: 35%;
      z-index: 99;
      background-color: green;
      color: white;
      padding: 15px;
      font-weight: bold;
      font-size: xx-large;
      border-radius: 10px 40px 10px 40px;
      text-align: center;
    `
    document.body.appendChild(div)
    div.addEventListener('click', event => event.target.remove(), true)
  }
  let timeDiff = (new Date() - startTime) / 1000
  div.innerHTML = `${string}<hr>Elapsed<br>${timeDiff}s`
}
*/

const useFocusStyleForHighlightedSearchTermWithId = id => {
  deFocusPreviouslyFocusedSpan()
  document.getElementById(id).classList.add('findInPageMatch_Focus')
  PreviousFocusMatchSpanId = id
}

//*****END: findInPage.js

//set window.wmf for calls outside the web view

window.wmf.elementLocation.getFirstOnScreenSection = getFirstOnScreenSection
window.wmf.elementLocation.getElementRect = getElementRect
window.wmf.utilities.accessibilityCursorToFragment = accessibilityCursorToFragment
window.wmf.findInPage.removeSearchTermHighlights = removeSearchTermHighlights
window.wmf.findInPage.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
window.wmf.findInPage.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
window.wmf.findInPage.removeSearchTermHighlights = removeSearchTermHighlights
window.wmf.editTextSelection.getSelectedTextEditInfo = getSelectedTextEditInfo