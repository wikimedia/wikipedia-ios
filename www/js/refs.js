var elementLocation = require('./elementLocation')

function isCitation( href ) {
  return href.indexOf('#cite_note') > -1
}

function isEndnote( href ) {
  return href.indexOf('#endnote_') > -1
}

function isReference( href ) {
  return href.indexOf('#ref_') > -1
}

function goDown( element ) {
  return element.getElementsByTagName( 'A' )[0]
}

/**
 * Skip over whitespace but not other elements
 */
function skipOverWhitespace( skipFunc ) {
  return function(element) {
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
}

var goLeft = skipOverWhitespace( function( element ) {
  return element.previousSibling
})

var goRight = skipOverWhitespace( function( element ) {
  return element.nextSibling
})

function hasCitationLink( element ) {
  try {
    return isCitation( goDown( element ).getAttribute( 'href' ) )
  } catch (e) {
    return false
  }
}

function collectRefText( sourceNode ) {
  var href = sourceNode.getAttribute( 'href' )
  var targetId = href.slice(1)
  var targetNode = document.getElementById( targetId )
  if ( targetNode === null ) {
    /*global console */
    console.log('reference target not found: ' + targetId)
    return ''
  }

  // preferably without the back link
  var backlinks = targetNode.getElementsByClassName( 'mw-cite-backlink' )    
  for (var i = 0; i < backlinks.length; i++) {
    backlinks[i].style.display = 'none'
  }
  return targetNode.innerHTML
}

function collectRefLink( sourceNode ) {
  var node = sourceNode
  while (!node.classList || !node.classList.contains('reference')) {
    node = node.parentNode
    if (!node) {
      return ''
    }
  }
  return node.id
}

function sendNearbyReferences( sourceNode ) {
  var selectedIndex = 0
  var refs = []
  var linkId = []
  var linkText = []
  var linkRects = []
  var curNode = sourceNode

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

  for(var i = 0; i < linkId.length; i++){
    var rect = elementLocation.getElementRect(document.getElementById(linkId[i]))
    linkRects.push(rect)
  }
    
  var referencesGroup = []
  for(var j = 0; j < linkId.length; j++){
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