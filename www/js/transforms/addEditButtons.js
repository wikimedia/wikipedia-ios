const newEditSectionButton = require('wikimedia-page-library').EditTransform.newEditSectionButton

const addEditButtonAfterElement = (preceedingElementSelector, sectionID, content) => {
  const preceedingElement = content.querySelector(preceedingElementSelector)
  preceedingElement.parentNode.insertBefore(
    newEditSectionButton(content, sectionID),
    preceedingElement.nextSibling
  )
}

const addEditButtonsToElements = (elementsSelector, sectionIDAttribute, content) => {
  content.querySelectorAll(elementsSelector)
    .forEach(function(element){
      element.appendChild(newEditSectionButton(content, element.getAttribute(sectionIDAttribute)))
    })
}

const add = content => {
  // Add lead section edit button after the lead section horizontal rule element.
  addEditButtonAfterElement('#content_block_0_hr', 0, content)
  // Add non-lead section edit buttons inside respective header elements.
  addEditButtonsToElements('.section_heading[data-id]:not([data-id=""]):not([data-id="0"])', 'data-id', content)
}

exports.add = add