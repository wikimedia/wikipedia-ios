const elementLocation = require('./elementLocation')

const isCitation = href => href.indexOf('#cite_note') > -1
const isEndnote = href => href.indexOf('#endnote_') > -1
const isReference = href => href.indexOf('#ref_') > -1

const goDown = element => element.getElementsByTagName( 'A' )[0]

/**
 * Skip over whitespace but not other elements
 */
const skipOverWhitespace = skipFunc => element => {
  do {
    element = skipFunc( element )
    if (element && element.nodeType == Node.TEXT_NODE) {
      if (element.textContent.match(/^\s+$/)) {
        // Ignore empty whitespace
        continue
      } else {
        break
      }
    } else {
      // found an element or ran out
      break
    }
  } while (true)
  return element
}

let goLeft = skipOverWhitespace( element => element.previousSibling )
let goRight = skipOverWhitespace( element => element.nextSibling )

const hasCitationLink = element => {
  try {
    return isCitation( goDown( element ).getAttribute( 'href' ) )
  } catch (e) {
    return false
  }
}

const collectRefText = sourceNode => {
  const href = sourceNode.getAttribute( 'href' )
  const targetId = href.slice(1)
  let targetNode = document.getElementById( targetId )
  if ( targetNode === null ) {
    targetNode = document.getElementById( decodeURIComponent( targetId ) )
  }
  if ( targetNode === null ) {
    /*global console */
    console.log('reference target not found: ' + targetId)
    return ''
  }

  // preferably without the back link
  targetNode.querySelectorAll( '.mw-cite-backlink' )
    .forEach(backlink => {
      backlink.style.display = 'none'
    })
  return targetNode.innerHTML
}

const collectRefLink = sourceNode => {
  let node = sourceNode
  while (!node.classList || !node.classList.contains('reference')) {
    node = node.parentNode
    if (!node) {
      return ''
    }
  }
  return node.id
}

const sendNearbyReferences = sourceNode => {
  let selectedIndex = 0
  let refs = []
  let linkId = []
  let linkText = []
  let linkRects = []
  let curNode = sourceNode

  // handle clicked ref:
  refs.push( collectRefText( curNode ) )
  linkId.push( collectRefLink( curNode ) )
  linkText.push( curNode.textContent )

  // go left:
  curNode = sourceNode.parentElement
  while ( hasCitationLink( goLeft( curNode ) ) ) {
    selectedIndex += 1
    curNode = goLeft( curNode )
    refs.unshift( collectRefText( goDown ( curNode ) ) )
    linkId.unshift( collectRefLink( curNode ) )
    linkText.unshift( curNode.textContent )
  }

  // go right:
  curNode = sourceNode.parentElement
  while ( hasCitationLink( goRight( curNode ) ) ) {
    curNode = goRight( curNode )
    refs.push( collectRefText( goDown ( curNode ) ) )
    linkId.push( collectRefLink( curNode ) )
    linkText.push( curNode.textContent )
  }

  for(let i = 0; i < linkId.length; i++){
    const rect = elementLocation.getElementRect(document.getElementById(linkId[i]))
    linkRects.push(rect)
  }

  let referencesGroup = []
  for(let j = 0; j < linkId.length; j++){
    referencesGroup.push({
      'id': linkId[j],
      'rect': linkRects[j],
      'text': linkText[j],
      'html': refs[j]
    })
  }

  // Special handling for references
  window.webkit.messageHandlers.referenceClicked.postMessage({
    'selectedIndex': selectedIndex,
    'referencesGroup': referencesGroup
  })
}

exports.isEndnote = isEndnote
exports.isReference = isReference
exports.isCitation = isCitation
exports.sendNearbyReferences = sendNearbyReferences