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
const isHidden = element => element.offsetParent === null

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
  const matchFilter = node => !tagsToIgnore.has(node.parentElement.tagName) && !isHidden(node.parentElement)
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

exports.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
exports.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
exports.removeSearchTermHighlights = removeSearchTermHighlights