var initialTopElement = undefined
var initialRelativeYOffset = 0

// Invoke from native code *before* a size change.
exports.sizeWillChange = function() {
  initialTopElement = document.elementFromPoint( window.innerWidth / 2, 0 )
  if (initialTopElement) {
    const rect = initialTopElement.getBoundingClientRect()
    initialRelativeYOffset = rect.top / rect.height
  } else {
    initialRelativeYOffset = 0
  }
}

// Invoke from native code *after* a size change to get a size change adjusted yOffset which keeps
// the same part of the article onscreen which was onscreen before the size change. Useful for
// device rotation, tablet TOC toggling etc...
exports.getSizeChangeAdjustedYOffset = function() {
  if (initialTopElement) {
    const rect = initialTopElement.getBoundingClientRect()
    const yOffset = window.scrollY + rect.top - initialRelativeYOffset * rect.height
    return yOffset
  }
  return 0
}