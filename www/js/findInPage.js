// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

let FindInPagePreviousFocusMatchSpanId = null

const recursivelyHighlightSearchTermInTextNodesStartingWithElement = (element, searchTerm) => {
  if (element) {
    if (element.nodeType == 3) {            // Text node
      while (true) {
        const value = element.nodeValue  // Search for searchTerm in text node
        const idx = value.toLowerCase().indexOf(searchTerm)

        if (idx < 0) break

        const span = document.createElement('span')
        let text = document.createTextNode(value.substr(idx, searchTerm.length))
        span.appendChild(text)
        span.setAttribute('class', 'findInPageMatch')

        text = document.createTextNode(value.substr(idx + searchTerm.length))
        element.deleteData(idx, value.length - idx)
        const next = element.nextSibling
        element.parentNode.insertBefore(span, next)
        element.parentNode.insertBefore(text, next)
        element = text
      }
    } else if (element.nodeType == 1) {     // Element node
      if (element.style.display != 'none' && element.nodeName.toLowerCase() != 'select') {
        for (let i = element.childNodes.length - 1; i >= 0; i--) {
          recursivelyHighlightSearchTermInTextNodesStartingWithElement(element.childNodes[i], searchTerm)
        }
      }
    }
  }
}

const recursivelyRemoveSearchTermHighlightsStartingWithElement = element => {
  if (element) {
    if (element.nodeType == 1) {
      if (element.getAttribute('class') == 'findInPageMatch') {
        const text = element.removeChild(element.firstChild)
        element.parentNode.insertBefore(text, element)
        element.parentNode.removeChild(element)
        return true
      }
      let normalize = false
      for (let i = element.childNodes.length - 1; i >= 0; i--) {
        if (recursivelyRemoveSearchTermHighlightsStartingWithElement(element.childNodes[i])) {
          normalize = true
        }
      }
      if (normalize) {
        element.normalize()
      }

    }
  }
  return false
}

const deFocusPreviouslyFocusedSpan = () => {
  if(FindInPagePreviousFocusMatchSpanId){
    document.getElementById(FindInPagePreviousFocusMatchSpanId).classList.remove('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = null
  }
}

const removeSearchTermHighlights = () => {
  deFocusPreviouslyFocusedSpan()
  recursivelyRemoveSearchTermHighlightsStartingWithElement(document.body)
}

const rectIntersectsRect = (a, b) => a.left <= b.right && b.left <= a.right && a.top <= b.bottom && b.top <= a.bottom

const shouldReportMatch = matchSpan => {
  const parentRect = matchSpan.parentElement.getBoundingClientRect()

  // Detect if element is hidden because its *parent* is hidden.  
  if (parentRect.width == 0 || parentRect.height == 0) {
    return false
  }
  
  // Text node elements with 'text-overflow: ellipsis;' can truncate text. So we need a way to
  // detect if a match is in elided text - i.e. after the ellipsis and thus not visible. We can
  // check if the match span's rect intersects its parent element's rect - if so it's visible,
  // otherwise we don't need to report the match.
  return rectIntersectsRect(parentRect, matchSpan.getBoundingClientRect())
}

const findAndHighlightAllMatchesForSearchTerm = searchTerm => {
  removeSearchTermHighlights()
  if (searchTerm.trim().length === 0){
    window.webkit.messageHandlers.findInPageMatchesFound.postMessage([])
    return
  }
  searchTerm = searchTerm.trim()

  recursivelyHighlightSearchTermInTextNodesStartingWithElement(document.body, searchTerm.toLowerCase())

  // The recursion doesn't walk a first-to-last path, so it doesn't encounter the
  // matches in first-to-last order. We can work around this by adding the "id"
  // and building our results array *after* the recursion is done, thanks to
  // "getElementsByClassName".
  const orderedMatchIDsToReport = Array.from(document.getElementsByClassName('findInPageMatch'))
    .filter(shouldReportMatch) // Easier and faster to filter these here rather than in the recursion (as it's currently structured).
    .map((el, i) => {
      const matchSpanId = 'findInPageMatchID|' + i
      el.setAttribute('id', matchSpanId)
      return matchSpanId
    })

  window.webkit.messageHandlers.findInPageMatchesFound.postMessage(orderedMatchIDsToReport)
}

const useFocusStyleForHighlightedSearchTermWithId = id => {
  deFocusPreviouslyFocusedSpan()
  setTimeout(() => {
    document.getElementById(id).classList.add('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = id
  }, 0)
}

exports.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
exports.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
exports.removeSearchTermHighlights = removeSearchTermHighlights