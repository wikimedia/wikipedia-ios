
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
    
// Note:
    // Replace regex used to be `/[\W]+/g`, but it was stripping unicode letters like é, which are beneficial for searching in native-land.
    // Ideally we could replace this with `/[^\pL]+/g`, which should match anything that isn't a letter in any language, but I couldn't get it to work.
    // So for now, we're replacing punctuation-type characters with empty space.
  reducedToSpaceSeparatedWordsOnly() {
    const separator = ' '
    const wordsOnlyForString = s => stringWithoutParenthesisForString(stringWithoutReferenceForString(s)).replace(/[-'`~!@#$%^&*()_|+=?;:'",.<>\{\}\[\]\\\/]+/g, separator).trim().split(separator)

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

const searchTermIndex = (textNode, searchTerm) => replaceNonBreakingHyphens(textNode.nodeValue).toLowerCase().indexOf(replaceNonBreakingHyphens(searchTerm))

const replaceNonBreakingHyphens = text => text.replace("‑", "-")

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

//*****BEGIN: passageHighlight.js

// Highlights the passages of a semantic search result inside the article with the find-in-page
// token. A passage can span links and other inline elements, so the text of the section is
// matched as one string across its text nodes, not node by node as find-in-page does.

const passageCharacterFolds = { ' ': ' ', '‑': '-', '‘': "'", '’': "'", '“': '"', '”': '"' }

const foldPassageCharacter = character => {
  const folded = passageCharacterFolds[character] || character
  const lowercased = folded.toLowerCase()
  return lowercased.length === 1 ? lowercased : folded
}

const isPassageWhitespace = character => /\s/.test(character)

// Soft hyphen, zero-width space, joiners, direction marks and byte order mark: they take no room
// on screen, and the search index and the rendered article do not agree on them.
const isPassageInvisible = character => /[\u00AD\u200B-\u200F\uFEFF]/.test(character)

// Reference markers and edit links are not part of the passage text.
const passageExcludedElements = 'sup.mw-ref, .mw-ref, .reference, .mw-editsection, style, script'

const passageTextNodes = container => {
  const filter = node => {
    const parent = node.parentElement
    if (!parent || tagsToIgnore.has(parent.tagName) || parent.closest(passageExcludedElements)) {
      return NodeFilter.FILTER_SKIP
    }
    return NodeFilter.FILTER_ACCEPT
  }
  const walker = document.createTreeWalker(container, NodeFilter.SHOW_TEXT, filter, false)
  const nodes = []
  let node
  while (node = walker.nextNode()) nodes.push(node)
  return nodes
}

// The passage folded like the haystack: one space per whitespace run, trimmed.
const foldPassageText = text => {
  let folded = ''
  for (let index = 0; index < text.length; index++) {
    const character = foldPassageCharacter(text[index])
    if (isPassageInvisible(character)) continue
    if (isPassageWhitespace(character)) {
      if (folded.length > 0 && !folded.endsWith(' ')) folded += ' '
    } else {
      folded += character
    }
  }
  return folded.trim()
}

// The folded text of the nodes, with the node and offset behind every character of it.
const passageHaystack = nodes => {
  let text = ''
  const positions = []
  nodes.forEach(node => {
    const value = node.nodeValue
    for (let offset = 0; offset < value.length; offset++) {
      const character = foldPassageCharacter(value[offset])
      if (isPassageInvisible(character)) continue
      if (isPassageWhitespace(character)) {
        if (text.length === 0 || text.endsWith(' ')) continue
        text += ' '
      } else {
        text += character
      }
      positions.push({ node, offset })
    }
  })
  return { text, positions }
}

const wrapPassageTextNode = textNode => {
  const span = document.createElement('span')
  span.setAttribute('class', 'findInPageMatch')
  span.setAttribute('data-passage', '')
  span.setAttribute('id', `passage|${ Math.random().toString(36).substring(2, 9) }`)
  textNode.parentNode.insertBefore(span, textNode)
  span.appendChild(textNode)
  return span.id
}

// Wraps the characters of the haystack from `start` to `end` (inclusive), one span per text node.
const wrapPassageRange = (positions, start, end) => {
  const ids = []
  let index = start
  while (index <= end) {
    const { node, offset } = positions[index]
    let last = index
    while (last < end && positions[last + 1].node === node) last++
    const from = offset
    const to = positions[last].offset + 1
    let target = from > 0 ? node.splitText(from) : node
    if (to - from < target.length) target.splitText(to - from)
    ids.push(wrapPassageTextNode(target))
    index = last + 1
  }
  return ids
}

const highlightPassageIn = (container, needle) => {
  const { text, positions } = passageHaystack(passageTextNodes(container))
  const start = text.indexOf(needle)
  if (start < 0) return []
  return wrapPassageRange(positions, start, start + needle.length - 1)
}

// Highlights every passage inside the section of `anchor`, or in the whole article when the
// section is not there or does not contain the passage. Returns the ids of the spans.
const highlightPassages = (passages, anchor) => {
  removeSearchTermHighlights()
  const heading = anchor ? document.getElementById(anchor) : null
  const section = heading ? heading.closest('section') : null
  const ids = []
  passages.forEach(passage => {
    const needle = foldPassageText(passage)
    if (needle.length === 0) return
    let found = section ? highlightPassageIn(section, needle) : []
    if (found.length === 0) found = highlightPassageIn(document.body, needle)
    ids.push(...found)
  })
  return ids
}

//*****END: passageHighlight.js

//set window.wmf for calls outside the web view

window.wmf.elementLocation.getFirstOnScreenSection = getFirstOnScreenSection
window.wmf.elementLocation.getElementRect = getElementRect
window.wmf.utilities.accessibilityCursorToFragment = accessibilityCursorToFragment
window.wmf.findInPage.removeSearchTermHighlights = removeSearchTermHighlights
window.wmf.findInPage.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
window.wmf.findInPage.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
window.wmf.findInPage.highlightPassages = highlightPassages
window.wmf.findInPage.removeSearchTermHighlights = removeSearchTermHighlights
window.wmf.editTextSelection.getSelectedTextEditInfo = getSelectedTextEditInfo
