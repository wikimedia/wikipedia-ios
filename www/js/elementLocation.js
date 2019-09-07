//  Used by methods in "UIWebView+ElementLocation.h" category.

const stringEndsWith = (str, suffix) => str.indexOf(suffix, str.length - suffix.length) !== -1

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
    if (rect.Y > insetTop || rect.Y + rect.Height > insetTop) {
      return i
    }
  }
  return -1
}

exports.getElementToMakeFirstOnScreenElement = (fragment, parentElementPrefix) => {
  var element = document.getElementById(fragment)
  // needed so the same element which `getIndexOfFirstOnScreenElement` looks for is scrolled to top (if the case the fragment is for a TOC item)
  if (element.parentElement.id && element.parentElement.id.startsWith(parentElementPrefix)) {
    element = element.parentElement
  }
  return element
}

exports.makeElementFirstOnScreenElement = (element, insetTop) => {
  element.scrollIntoView(true)
  // `- 1` needed so when element is scrolled to the top it's far enough onscreen so `getIndexOfFirstOnScreenElement` will determine that it is currently the first onscreen element (if the fragment is for a TOC item)
  window.scrollBy(0, -Math.max(0, insetTop - 1))
}

exports.getElementFromPoint = (x, y) => document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)

exports.isElementTopOnscreen = element => element.getBoundingClientRect().top < 0
