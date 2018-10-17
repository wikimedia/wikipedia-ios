// This file keeps the same area of the article onscreen after rotate or tablet TOC toggle.
const utilities = require('./utilities')

let topElement = undefined
let relativeYOffset = 0

const relativeYOffsetForElement = element => {
  const rect = element.getBoundingClientRect()
  return rect.top / rect.height
}

const recordTopElementAndItsRelativeYOffset = () => {
  topElement = document.elementFromPoint( window.innerWidth / 2, window.innerHeight / 3 )
  topElement = utilities.findClosest(topElement, 'div#content > div') || topElement
  if (topElement) {
    relativeYOffset = relativeYOffsetForElement(topElement)
  } else {
    relativeYOffset = 0
  }
}

const yOffsetFromRelativeYOffsetForElement = element => {
  const rect = element.getBoundingClientRect()
  return window.scrollY + rect.top - relativeYOffset * rect.height
}

const scrollToSamePlaceBeforeResize = () => {
  if (!topElement) {
    return
  }
  window.scrollTo(0, yOffsetFromRelativeYOffsetForElement(topElement))
}

window.addEventListener('resize', event => setTimeout(scrollToSamePlaceBeforeResize, 50))

let timer = null
window.addEventListener('scroll', () => {
  if(timer !== null) {
    clearTimeout(timer)
  }
  timer = setTimeout(recordTopElementAndItsRelativeYOffset, 250)
}, false)

exports.recordTopElementAndItsRelativeYOffset = recordTopElementAndItsRelativeYOffset
exports.scrollToSamePlaceBeforeResize = scrollToSamePlaceBeforeResize