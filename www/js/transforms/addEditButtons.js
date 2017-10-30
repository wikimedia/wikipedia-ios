const newEditSectionButton = require('wikimedia-page-library').EditTransform.newEditSectionButton

function addEditButtonAfterElement(preceedingElementSelector, sectionID, content) {
  const preceedingElement = content.querySelector(preceedingElementSelector)
  preceedingElement.parentNode.insertBefore(
    newEditSectionButton(content, sectionID),
    preceedingElement.nextSibling
  )
}

function addEditButtonsToElements(elementsSelector, sectionIDAttribute, content) {
  Array.from(content.querySelectorAll(elementsSelector))
  .forEach(function(element){
    element.appendChild(newEditSectionButton(content, element.getAttribute(sectionIDAttribute)))
  })
}

exports.addEditButtonAfterElement = addEditButtonAfterElement
exports.addEditButtonsToElements = addEditButtonsToElements