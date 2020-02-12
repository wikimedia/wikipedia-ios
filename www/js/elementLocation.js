//  Used by methods in "UIWebView+ElementLocation.h" category.

class SectionFilter {
  acceptNode(node) {
    return node.tagName === 'SECTION'
  }
}

exports.getFirstOnScreenSection = insetTop => {
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT, new SectionFilter())
  let node
  let id = -1
  let anchor = ''
  while (node = walker.nextNode()) {
    const rect = node.getBoundingClientRect()
    if (rect.top > insetTop + 1) {
      continue
    }
    const sectionIdString = node.getAttribute('data-mw-section-id')
    if (!sectionIdString) {
      continue
    }
    id = parseInt(sectionIdString)
    const sectionWalker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT)
    while (node = sectionWalker.nextNode()) {
      if (!node.id) {
        continue
      }
      anchor = node.id
      break
    }
    break
  }
  return {id, anchor}
}

exports.getImageWithSrc = src => document.querySelector(`img[src$="${src}"]`)

exports.getElementRect = element => {
  const rect = element.getBoundingClientRect()
  // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
  return {
    Y: rect.top,
    X: rect.left,
    Width: rect.width,
    Height: rect.height
  }
}

exports.getIndexOfFirstOnScreenElement = (elementPrefix, elementCount, insetTop) => {
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

exports.getElementFromPoint = (x, y) => document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)

exports.isElementTopOnscreen = element => element.getBoundingClientRect().top < 0