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

class SectionFilter {
    acceptNode(node) {
        return node.tagName === 'SECTION'
    }
}

const getFirstOnScreenSectionId = (insetTop) => {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT, new SectionFilter())
    let node
    let sectionId = -1
    while ((node = walker.nextNode())) {
        const rect = node.getBoundingClientRect()
        if (rect.top <= insetTop + 1) {
            const sectionIdString = node.getAttribute('data-mw-section-id')
            if (!sectionIdString) {
                continue
            }
            sectionId = parseInt(sectionIdString)
        } else if (sectionId !== -1) {
            break
        }
    }
    return sectionId
}

const pcsUtilities = {
    getElementRect,
    getFirstOnScreenSectionId
}
