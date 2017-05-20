(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var wmf = {}

wmf.elementLocation = require('./js/elementLocation')
wmf.utilities = require('./js/utilities')
wmf.findInPage = require('./js/findInPage')
wmf.footerReadMore = require('./js/transforms/footerReadMore')
wmf.footerMenu = require('./js/transforms/footerMenu')
wmf.footerLegal = require('./js/transforms/footerLegal')
wmf.filePages = require('./js/transforms/disableFilePageEdit')
wmf.tables = require('./js/transforms/collapseTables')
wmf.redlinks = require('./js/transforms/hideRedlinks')
wmf.paragraphs = require('./js/transforms/relocateFirstParagraph')
wmf.images = require('./js/transforms/widenImages')

window.wmf = wmf
},{"./js/elementLocation":2,"./js/findInPage":3,"./js/transforms/collapseTables":6,"./js/transforms/disableFilePageEdit":7,"./js/transforms/footerLegal":8,"./js/transforms/footerMenu":9,"./js/transforms/footerReadMore":10,"./js/transforms/hideRedlinks":12,"./js/transforms/relocateFirstParagraph":13,"./js/transforms/widenImages":14,"./js/utilities":15}],2:[function(require,module,exports){
//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1
}

exports.getImageWithSrc = function(src) {
  var images = document.getElementsByTagName('img')
  for (var i = 0; i < images.length; ++i) {
    if (stringEndsWith(images[i].src, src)) {
      return images[i]
    }
  }
  return null
}

exports.getElementRect = function(element) {
  var rect = element.getBoundingClientRect()
    // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
  return {
    Y: rect.top,
    X: rect.left,
    Width: rect.width,
    Height: rect.height
  }
}

exports.getIndexOfFirstOnScreenElement = function(elementPrefix, elementCount){
  for (var i = 0; i < elementCount; ++i) {
    var div = document.getElementById(elementPrefix + i)
    if (div === null) {
      continue
    }
    var rect = this.getElementRect(div)
    if ( rect.Y >= -1 || rect.Y + rect.Height >= 50) {
      return i
    }
  }
  return -1
}

exports.getElementFromPoint = function(x, y){
  return document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)
}

exports.isElementTopOnscreen = function(element){
  return element.getBoundingClientRect().top < 0
}
},{}],3:[function(require,module,exports){
// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

var FindInPageResultCount = 0
var FindInPageResultMatches = []
var FindInPagePreviousFocusMatchSpanId = null

function recursivelyHighlightSearchTermInTextNodesStartingWithElement(element, searchTerm) {
  if (element) {
    if (element.nodeType == 3) {            // Text node
      while (true) {
        var value = element.nodeValue  // Search for searchTerm in text node
        var idx = value.toLowerCase().indexOf(searchTerm)
                
        if (idx < 0) break
                
        var span = document.createElement('span')
        var text = document.createTextNode(value.substr(idx, searchTerm.length))
        span.appendChild(text)
        span.setAttribute('class', 'findInPageMatch')

        text = document.createTextNode(value.substr(idx + searchTerm.length))
        element.deleteData(idx, value.length - idx)
        var next = element.nextSibling
        element.parentNode.insertBefore(span, next)
        element.parentNode.insertBefore(text, next)
        element = text
        FindInPageResultCount++
      }
    } else if (element.nodeType == 1) {     // Element node
      if (element.style.display != 'none' && element.nodeName.toLowerCase() != 'select') {
        for (var i = element.childNodes.length - 1; i >= 0; i--) {
          recursivelyHighlightSearchTermInTextNodesStartingWithElement(element.childNodes[i], searchTerm)
        }
      }
    }
  }
}

function recursivelyRemoveSearchTermHighlightsStartingWithElement(element) {
  if (element) {
    if (element.nodeType == 1) {
      if (element.getAttribute('class') == 'findInPageMatch') {
        var text = element.removeChild(element.firstChild)
        element.parentNode.insertBefore(text,element)
        element.parentNode.removeChild(element)
        return true
      } 
      var normalize = false
      for (var i = element.childNodes.length - 1; i >= 0; i--) {
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

function deFocusPreviouslyFocusedSpan() {
  if(FindInPagePreviousFocusMatchSpanId){
    document.getElementById(FindInPagePreviousFocusMatchSpanId).classList.remove('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = null
  }
}

function removeSearchTermHighlights() {
  FindInPageResultCount = 0
  FindInPageResultMatches = []
  deFocusPreviouslyFocusedSpan()
  recursivelyRemoveSearchTermHighlightsStartingWithElement(document.body)
}

function findAndHighlightAllMatchesForSearchTerm(searchTerm) {
  removeSearchTermHighlights()
  if (searchTerm.trim().length === 0){
    window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches)
    return
  }
  searchTerm = searchTerm.trim()
    
  recursivelyHighlightSearchTermInTextNodesStartingWithElement(document.body, searchTerm.toLowerCase())
    
    // The recursion doesn't walk a first-to-last path, so it doesn't encounter the
    // matches in first-to-last order. We can work around this by adding the "id"
    // and building our results array *after* the recursion is done, thanks to
    // "getElementsByClassName".
  var orderedMatchElements = document.getElementsByClassName('findInPageMatch')
  FindInPageResultMatches.length = orderedMatchElements.length
  for (var i = 0; i < orderedMatchElements.length; i++) {
    var matchSpanId = 'findInPageMatchID|' + i
    orderedMatchElements[i].setAttribute('id', matchSpanId)
        // For now our results message to native land will be just an array of match span ids.
    FindInPageResultMatches[i] = matchSpanId
  }
    
  window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches)
}

function useFocusStyleForHighlightedSearchTermWithId(id) {
  deFocusPreviouslyFocusedSpan()
  setTimeout(function(){
    document.getElementById(id).classList.add('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = id
  }, 0)
}

exports.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm
exports.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId
exports.removeSearchTermHighlights = removeSearchTermHighlights
},{}],4:[function(require,module,exports){
(function () {
  var refs = require('./refs')
  var utilities = require('./utilities')
  var tableCollapser = require('wikimedia-page-library').CollapseTable

  document.onclick = function() {
    // Reminder: resist adding any click/tap handling here - they can
    // "fight" with items in the touchEndedWithoutDragging handler.
    // Add click/tap handling to touchEndedWithoutDragging instead.
    event.preventDefault() // <-- Do not remove!
  }

  // track where initial touches start
  var touchDownY = 0.0
  document.addEventListener(
            'touchstart',
            function (event) {
              touchDownY = parseInt(event.changedTouches[0].clientY)
            }, false)

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
  function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
      return false
    }
 
    /*
    "touchstart" is fired when you do a peek in WKWebView, but when the peek view controller
    is presented, it appears the JS for the then covered webview more or less pauses, and
    the matching "touchend" does't get called until the view is again shown and touched (the
    hanging "touchend" seems to fire just before that new touch's "touchstart").
    This is troublesome because that delayed call to "touchend" ends up causing the image or
    link click handling to be called when the user touches the article again, even though
    that image or link is probably not what the user is interacting with now. Thankfully we
    can check for this weird condition because when it happens the number of touches hasn't
    gone to 0 yet. So we check here and bail if that's the case.
    */
    var didDetectHangingTouchend = event.touches.length > 0
    if(didDetectHangingTouchend){
      return false
    }
 
    var href = hrefTarget.getAttribute( 'href' )
    if (hrefTarget.getAttribute( 'data-action' ) === 'edit_section') {
      window.webkit.messageHandlers.editClicked.postMessage({ sectionId: hrefTarget.getAttribute( 'data-id' ) })
    } else if (href && refs.isCitation(href)) {
      // Handle reference links with a popup view instead of scrolling about!
      refs.sendNearbyReferences( hrefTarget )
    } else if (href && href[0] === '#') {
 
      tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)))
 
      // If it is a link to an anchor in the current page, use existing link handling
      // so top floating native header height can be taken into account by the regular
      // fragment handling logic.
      window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
    } else if (event.target.tagName === 'IMG' && event.target.getAttribute( 'data-image-gallery' ) === 'true') {      
      window.webkit.messageHandlers.imageClicked.postMessage({
        'src': event.target.getAttribute('src'),
        'width': event.target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
        'height': event.target.naturalHeight,
        'data-file-width': event.target.getAttribute('data-file-width'),
        'data-file-height': event.target.getAttribute('data-file-height')
      })
    } else if (href) {
      window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
    } else {
      return false
    }
    return true
  }

  function touchEndedWithoutDragging(event){
    /*
     there are certain elements which don't have an <a> ancestor, so if we fail to find it,
     specify the event's target instead
     */
    var didSendMessage = maybeSendMessageForTarget(event, utilities.findClosest(event.target, 'A') || event.target)

    var hasSelectedText = window.getSelection().rangeCount > 0

    if (!didSendMessage && !hasSelectedText) {
      // Do NOT prevent default behavior -- this is needed to for instance
      // handle deselection of text.
      window.webkit.messageHandlers.nonAnchorTouchEndedWithoutDragging.postMessage({
        id: event.target.getAttribute( 'id' ),
        tagName: event.target.tagName
      })

    }
  }

  function handleTouchEnded(event){
    var touchobj = event.changedTouches[0]
    var touchEndY = parseInt(touchobj.clientY)
    if (touchDownY - touchEndY === 0 && event.changedTouches.length === 1) {
      // None of our tap events should fire if the user dragged vertically.
      touchEndedWithoutDragging(event)
    }
  }

  document.addEventListener('touchend', handleTouchEnded, false)

})()
},{"./refs":5,"./utilities":15,"wikimedia-page-library":16}],5:[function(require,module,exports){
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
},{"./elementLocation":2}],6:[function(require,module,exports){
const tableCollapser = require('wikimedia-page-library').CollapseTable
var location = require('../elementLocation')

function footerDivClickCallback(container) {
  if(location.isElementTopOnscreen(container)){
    window.scrollTo( 0, container.offsetTop - 10 )
  }
}

function hideTables(content, isMainPage, pageTitle, infoboxTitle, otherTitle, footerTitle) {
  tableCollapser.collapseTables(document, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback)
}

exports.hideTables = hideTables
},{"../elementLocation":2,"wikimedia-page-library":16}],7:[function(require,module,exports){

function disableFilePageEdit( content ) {
  var filetoc = content.querySelector( '#filetoc' )
  if (filetoc) {
    // We're on a File: page! Do some quick hacks.
    // In future, replace entire thing with a custom view most of the time.
    // Hide edit sections
    var editSections = content.querySelectorAll('.edit_section_button')
    for (var i = 0; i < editSections.length; i++) {
      editSections[i].style.display = 'none'
    }
    var fullImageLink = content.querySelector('.fullImageLink a')
    if (fullImageLink) {
      // Don't replace the a with a span, as it will break styles.
      // Just disable clicking.
      // Don't disable touchstart as this breaks scrolling!
      fullImageLink.href = ''
      fullImageLink.addEventListener( 'click', function( event ) {
        event.preventDefault()
      } )
    }
  }
}

exports.disableFilePageEdit = disableFilePageEdit
},{}],8:[function(require,module,exports){

function add(licenseString, licenseSubstitutionString, containerID, licenceLinkClickHandler) {
  var container = document.getElementById(containerID)
  var licenseStringHalves = licenseString.split('$1')


  container.innerHTML = 
  `<div class='footer_legal_contents'>
    <hr class='footer_legal_divider'>
    <span class='footer_legal_licence'>
      ${licenseStringHalves[0]}
      <a class='footer_legal_licence_link'>
        ${licenseSubstitutionString}
      </a>
      ${licenseStringHalves[1]}
    </span>
  </div>`

  container.querySelector('.footer_legal_licence_link')
           .addEventListener('click', function(){
             licenceLinkClickHandler()
           }, false)
}

exports.add = add
},{}],9:[function(require,module,exports){

// var thisType = IconTypeEnum.languages;
// var iconClass = IconTypeEnum.properties[thisType].iconClass; 
// iconClass is 'footer_menu_icon_languages'
var IconTypeEnum = {
  languages: 1,
  lastEdited: 2,
  pageIssues: 3,
  disambiguation: 4,
  coordinate: 5,
  properties: {
    1: {iconClass: 'footer_menu_icon_languages'},
    2: {iconClass: 'footer_menu_icon_last_edited'},
    3: {iconClass: 'footer_menu_icon_page_issues'},
    4: {iconClass: 'footer_menu_icon_disambiguation'},
    5: {iconClass: 'footer_menu_icon_coordinate'}
  }
}

class WMFMenuItem {
  constructor(title, subtitle, iconType, clickHandler) {
    this.title = title
    this.subtitle = subtitle
    this.iconType = iconType
    this.clickHandler = clickHandler
  }
}

class WMFMenuItemFragment {
  constructor(wmfMenuItem) {
    var item = document.createElement('div')
    item.className = 'footer_menu_item'

    var containerAnchor = document.createElement('a')
    containerAnchor.addEventListener('click', function(){
      wmfMenuItem.clickHandler()
    }, false)
                
    item.appendChild(containerAnchor)

    if(wmfMenuItem.title){
      var title = document.createElement('div')
      title.className = 'footer_menu_item_title'
      title.innerText = wmfMenuItem.title
      containerAnchor.appendChild(title)
    }

    if(wmfMenuItem.subtitle){
      var subtitle = document.createElement('div')
      subtitle.className = 'footer_menu_item_subtitle'
      subtitle.innerText = wmfMenuItem.subtitle
      containerAnchor.appendChild(subtitle)
    }

    if(wmfMenuItem.iconType){
      var iconClass = IconTypeEnum.properties[wmfMenuItem.iconType].iconClass 
      item.classList.add(iconClass)
    }

    return document.createDocumentFragment().appendChild(item)
  }
}

function addItem(title, subtitle, iconType, containerID, clickHandler) {
  const itemModel = new WMFMenuItem(title, subtitle, iconType, clickHandler)
  const itemFragment = new WMFMenuItemFragment(itemModel)
  document.getElementById(containerID).appendChild(itemFragment)
}

function setHeading(headingString, headingID) {
  document.getElementById(headingID).innerText = headingString
}

exports.IconTypeEnum = IconTypeEnum
exports.setHeading = setHeading
exports.addItem = addItem
},{}],10:[function(require,module,exports){

var _saveButtonClickHandler = null
var _clickHandler = null
var _titlesShownHandler = null
var _saveForLaterString = null
var _savedForLaterString = null
var _saveButtonIDPrefix = 'readmore:save:'
var _readMoreContainer = null

var shownTitles = []

function safelyRemoveEnclosures(string, opener, closer) {
  const enclosureRegex = new RegExp(`\\s?[${opener}][^${opener}${closer}]+[${closer}]`, 'g')
  var previousString = null
  var counter = 0
  const safeMaxTries = 30
  do {
    previousString = string
    string = string.replace(enclosureRegex, '')
    counter++
  } while (previousString !== string && counter < safeMaxTries)
  return string
}

function cleanExtract(string){
  string = safelyRemoveEnclosures(string, '(', ')')
  string = safelyRemoveEnclosures(string, '/', '/')
  return string
}

class WMFPage {
  constructor(title, thumbnail, terms, extract) {
    this.title = title
    this.thumbnail = thumbnail
    this.terms = terms
    this.extract = extract
  }
}

class WMFPageFragment {
  constructor(wmfPage, index) {
      
    var page = document.createElement('div')
    page.id = index
    page.className = 'footer_readmore_page'        
      
    var hasImage = wmfPage.thumbnail && wmfPage.thumbnail.source  
    if(hasImage){
      var image = document.createElement('div')
      image.style.backgroundImage = `url(${wmfPage.thumbnail.source})`
      image.classList.add('footer_readmore_page_image')
      page.appendChild(image)
    }
        
    var container = document.createElement('div')
    container.classList.add('footer_readmore_page_container')
    page.appendChild(container)

    page.addEventListener('click', function(){
      _clickHandler(`/wiki/${encodeURI(wmfPage.title)}`)
    }, false)

    if(wmfPage.title){
      var title = document.createElement('div')
      title.id = index
      title.className = 'footer_readmore_page_title'
      title.innerHTML = wmfPage.title.replace(/_/g, ' ')
      container.appendChild(title)
    }

    var description = null
    if(wmfPage.terms){
      description = wmfPage.terms.description
    }        
    if((description === null || description.length < 10) && wmfPage.extract){
      description = cleanExtract(wmfPage.extract)
    }
    if(description){
      var descriptionEl = document.createElement('div')
      descriptionEl.id = index
      descriptionEl.className = 'footer_readmore_page_description'
      descriptionEl.innerHTML = description
      container.appendChild(descriptionEl)
    }

    var saveButton = document.createElement('div')
    saveButton.id = `${_saveButtonIDPrefix}${encodeURI(wmfPage.title)}`
    saveButton.innerText = 'Save for later'
    saveButton.className = 'footer_readmore_page_save'
    saveButton.addEventListener('click', function(event){
      _saveButtonClickHandler(wmfPage.title)
      event.stopPropagation()
      event.preventDefault()
    }, false)
    container.appendChild(saveButton)

    return document.createDocumentFragment().appendChild(page)
  }
}

function showReadMore(pages){  
  shownTitles.length = 0
  
  pages.forEach(function(page, index){

    const title = page.title.replace(/ /g, '_')
    shownTitles.push(title)

    const pageModel = new WMFPage(title, page.thumbnail, page.terms, page.extract)
    const pageFragment = new WMFPageFragment(pageModel, index)
    _readMoreContainer.appendChild(pageFragment)
  })
  
  _titlesShownHandler(shownTitles)
}

// Leave 'baseURL' null if you don't need to deal with proxying.
function fetchReadMore(baseURL, title, showReadMoreHandler) {
  var xhr = new XMLHttpRequest()
  if (baseURL === null) {
    baseURL = ''
  }
    
  const pageCountToFetch = 3
  const params = {
    action: 'query',
    continue: '',
    exchars: 256,
    exintro: 1,
    exlimit: pageCountToFetch,
    explaintext: '',
    format: 'json',
    generator: 'search',
    gsrinfo: '',
    gsrlimit: pageCountToFetch,
    gsrnamespace: 0,
    gsroffset: 0,
    gsrprop: 'redirecttitle',
    gsrsearch: `morelike:${title}`,
    gsrwhat: 'text',
    ns: 'ppprop',
    pilimit: pageCountToFetch,
    piprop: 'thumbnail',
    pithumbsize: 120,
    prop: 'pageterms|pageimages|pageprops|revisions|extracts',
    rrvlimit: 1,
    rvprop: 'ids',
    wbptterms: 'description',
    formatversion: 2
  }

  const paramsString = Object.keys(params)
      .map(function(key){
        return `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`
      })
      .join('&')
    
  xhr.open('GET', `${baseURL}/w/api.php?${paramsString}`, true)
  xhr.onload = function() {
    if (xhr.readyState === 4) {
      if (xhr.status === 200) {
        showReadMoreHandler(JSON.parse(xhr.responseText).query.pages)
      } else {
          // console.error(xhr.statusText);
      }
    }
  }
    /*
    xhr.onerror = function(e) {
      console.log(`${e}`);
      // console.error(xhr.statusText);
    }
    */
  xhr.send(null)
}

function updateSaveButtonText(button, title, isSaved){
  button.innerText = isSaved ? _savedForLaterString : _saveForLaterString
}

function updateSaveButtonBookmarkIcon(button, title, isSaved){
  button.classList.remove('footer_readmore_bookmark_unfilled')
  button.classList.remove('footer_readmore_bookmark_filled')  
  button.classList.add(isSaved ? 'footer_readmore_bookmark_filled' : 'footer_readmore_bookmark_unfilled')
}

function setTitleIsSaved(title, isSaved){
  const saveButton = document.getElementById(`${_saveButtonIDPrefix}${title}`)
  updateSaveButtonText(saveButton, title, isSaved)
  updateSaveButtonBookmarkIcon(saveButton, title, isSaved)
}

function add(baseURL, title, saveForLaterString, savedForLaterString, containerID, clickHandler, saveButtonClickHandler, titlesShownHandler) {
  _readMoreContainer = document.getElementById(containerID)
  _clickHandler = clickHandler
  _saveButtonClickHandler = saveButtonClickHandler
  _titlesShownHandler = titlesShownHandler  
  _saveForLaterString = saveForLaterString
  _savedForLaterString = savedForLaterString
  
  fetchReadMore(baseURL, title, showReadMore)
}

function setHeading(headingString, headingID) {
  document.getElementById(headingID).innerText = headingString
}

exports.setHeading = setHeading
exports.setTitleIsSaved = setTitleIsSaved
exports.add = add
},{}],11:[function(require,module,exports){

function hideRedlinks( content ) {
  var redLinks = content.querySelectorAll( 'a.new' )
  for ( var i = 0; i < redLinks.length; i++ ) {
    var redLink = redLinks[i]
    redLink.style.color = 'inherit'
  }
}

exports.hideRedlinks = hideRedlinks
},{}],12:[function(require,module,exports){
arguments[4][11][0].apply(exports,arguments)
},{"dup":11}],13:[function(require,module,exports){

function moveFirstGoodParagraphUp( content ) {
    /*
    Instead of moving the infobox down beneath the first P tag,
    move the first good looking P tag *up* (as the first child of
    the first section div). That way the first P text will appear not
    only above infoboxes, but above other tables/images etc too!
    */

  if(content.getElementById( 'mainpage' ))return

  var block_0 = content.getElementById( 'content_block_0' )
  if(!block_0) return

  var allPs = block_0.getElementsByTagName( 'p' )
  if(!allPs) return

  var edit_section_button_0 = content.getElementById( 'edit_section_button_0' )
  if(!edit_section_button_0) return

  function isParagraphGood(p) {
    // Narrow down to first P which is direct child of content_block_0 DIV.
    // (Don't want to yank P from somewhere in the middle of a table!)
    if  (p.parentNode == block_0 ||
            /* HAX: the line below is a temporary fix for <div class="mw-mobilefrontend-leadsection"> temporarily
               leaking into mobileview output - as soon as that div is removed the line below will no longer be needed. */
            p.parentNode.className == 'mw-mobilefrontend-leadsection'
            ){
                // Ensure the P being pulled up has at least a couple lines of text.
                // Otherwise silly things like a empty P or P which only contains a
                // BR tag will get pulled up (see articles on "Chemical Reaction" and
                // "Hawaii").
                // Trick for quickly determining element height:
                //      https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement.offsetHeight
                //      http://stackoverflow.com/a/1343350/135557
      var minHeight = 40
      var pIsTooSmall = p.offsetHeight < minHeight
      return !pIsTooSmall
    }
    return false
      
  }
 
  var firstGoodParagraph = function(){
    return Array.prototype.slice.call( allPs).find(isParagraphGood)
  }()

  if(!firstGoodParagraph) return

  // Move everything between the firstGoodParagraph and the next paragraph to a light-weight fragment.
  var fragmentOfItemsToRelocate = function(){
    var didHitGoodP = false
    var didHitNextP = false

    var shouldElementMoveUp = function(element) {
      if(didHitGoodP && element.tagName === 'P'){
        didHitNextP = true
      }else if(element.isEqualNode(firstGoodParagraph)){
        didHitGoodP = true
      }
      return didHitGoodP && !didHitNextP
    }

    var fragment = document.createDocumentFragment()
    Array.prototype.slice.call(firstGoodParagraph.parentNode.childNodes).forEach(function(element) {
      if(shouldElementMoveUp(element)){
        // appendChild() attaches the element to the fragment *and* removes it from DOM.
        fragment.appendChild(element)
      }
    })
    return fragment
  }()

  // Attach the fragment just after the lead section edit button.
  // insertBefore() on a fragment inserts "the children of the fragment, not the fragment itself."
  // https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
  block_0.insertBefore(fragmentOfItemsToRelocate, edit_section_button_0.nextSibling)
}

exports.moveFirstGoodParagraphUp = moveFirstGoodParagraphUp
},{}],14:[function(require,module,exports){

const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

const isGalleryImage = function(image) {
  // 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
  // WidenImage's maybeWidenImage code will do further checks before it widens an image.
  return image.getAttribute('data-image-gallery') === 'true'    
}

function widenImages(content) {
  Array.from(content.querySelectorAll('img'))
    .filter(isGalleryImage)
    .forEach(maybeWidenImage)
}

exports.widenImages = widenImages
},{"wikimedia-page-library":16}],15:[function(require,module,exports){

// Implementation of https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
function findClosest (el, selector) {
  while ((el = el.parentElement) && !el.matches(selector));
  return el
}

function setLanguage(lang, dir, uidir){
  var html = document.querySelector( 'html' )
  html.lang = lang
  html.dir = dir
  html.classList.add( 'content-' + dir )
  html.classList.add( 'ui-' + uidir )
}

function setPageProtected(isProtected){
  document.querySelector( 'html' ).classList[isProtected ? 'add' : 'remove']('page-protected')
}

function scrollToFragment(fragmentId){
  location.hash = ''
  location.hash = fragmentId
}

function accessibilityCursorToFragment(fragmentId){
    /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
  var focus_element = document.getElementById(fragmentId)
  var other_element = document.body
  other_element.setAttribute('tabindex', 0)
  other_element.focus()
  focus_element.setAttribute('tabindex', 0)
  focus_element.focus()
}

exports.accessibilityCursorToFragment = accessibilityCursorToFragment
exports.scrollToFragment = scrollToFragment
exports.setPageProtected = setPageProtected
exports.setLanguage = setLanguage
exports.findClosest = findClosest
},{}],16:[function(require,module,exports){
'use strict';

// This file exists for CSS packaging only. It imports the CSS which is to be
// packaged in the override CSS build product.

// todo: delete Empty.css when other overrides exist

/**
 * Polyfill function that tells whether a given element matches a selector.
 * @param {!Element} el Element
 * @param {!string} selector Selector to look for
 * @return {!boolean} Whether the element matches the selector
 */
var matchesSelectorCompat = function matchesSelectorCompat(el, selector) {
  if (el.matches) {
    return el.matches(selector);
  }
  if (el.matchesSelector) {
    return el.matchesSelector(selector);
  }
  if (el.webkitMatchesSelector) {
    return el.webkitMatchesSelector(selector);
  }
  return false;
};

/**
 * Returns closest ancestor of element which matches selector.
 * Similar to 'closest' methods as seen here:
 *  https://api.jquery.com/closest/
 *  https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
 * @param  {!Element} el        Element
 * @param  {!string} selector   Selector to look for in ancestors of 'el'
 * @return {?HTMLElement}       Closest ancestor of 'el' matching 'selector'
 */
var findClosestAncestor = function findClosestAncestor(el, selector) {
  var parentElement = void 0;
  for (parentElement = el.parentElement; parentElement && !matchesSelectorCompat(parentElement, selector); parentElement = parentElement.parentElement) {
    // Intentionally empty.
  }
  return parentElement;
};

/**
 * Determines if element has a table ancestor.
 * @param  {!Element}  el   Element
 * @return {boolean}        Whether table ancestor of 'el' is found
 */
var isNestedInTable = function isNestedInTable(el) {
  return Boolean(findClosestAncestor(el, 'table'));
};

var elementUtilities = {
  matchesSelectorCompat: matchesSelectorCompat,
  findClosestAncestor: findClosestAncestor,
  isNestedInTable: isNestedInTable
};

/**
 * Find an array of table header (TH) contents. If there are no TH elements in
 * the table or the header's link matches pageTitle, an empty array is returned.
 * @param {!Element} element
 * @param {?string} pageTitle Unencoded page title; if this title matches the
 *                            contents of the header exactly, it will be omitted.
 * @return {!Array<string>}
 */
var getTableHeader = function getTableHeader(element, pageTitle) {
  var thArray = [];

  if (!element.children) {
    return thArray;
  }

  for (var i = 0; i < element.children.length; i++) {
    var el = element.children[i];

    if (el.tagName === 'TH') {
      // ok, we have a TH element!
      // However, if it contains more than two links, then ignore it, because
      // it will probably appear weird when rendered as plain text.
      var aNodes = el.querySelectorAll('a');
      // todo: these conditionals are very confusing. Rewrite by extracting a
      //       method or simplify.
      if (aNodes.length < 3) {
        // todo: remove nonstandard Element.innerText usage
        // Also ignore it if it's identical to the page title.
        if ((el.innerText && el.innerText.length || el.textContent.length) > 0 && el.innerText !== pageTitle && el.textContent !== pageTitle && el.innerHTML !== pageTitle) {
          thArray.push(el.innerText || el.textContent);
        }
      }
    }

    // if it's a table within a table, don't worry about it
    if (el.tagName === 'TABLE') {
      continue;
    }

    // todo: why do we need to recurse?
    // recurse into children of this element
    var ret = getTableHeader(el, pageTitle);

    // did we get a list of TH from this child?
    if (ret.length > 0) {
      thArray = thArray.concat(ret);
    }
  }

  return thArray;
};

/** Ex: toggleCollapseClickCallback.bind(el, (container) => {
          window.scrollTo(0, container.offsetTop - transformer.getDecorOffset())
        })
    @this HTMLElement
    @param footerDivClickCallback {?(!HTMLElement) => void}
    @return {void} */
var toggleCollapseClickCallback = function toggleCollapseClickCallback(footerDivClickCallback) {
  var container = this.parentNode;
  var header = container.children[0];
  var table = container.children[1];
  var footer = container.children[2];
  var caption = header.querySelector('.app_table_collapsed_caption');
  if (table.style.display !== 'none') {
    table.style.display = 'none';
    header.classList.remove('app_table_collapse_close'); // todo: use app_table_collapsed_collapsed
    header.classList.remove('app_table_collapse_icon'); // todo: use app_table_collapsed_icon
    header.classList.add('app_table_collapsed_open'); // todo: use app_table_collapsed_expanded
    if (caption) {
      caption.style.visibility = 'visible';
    }
    footer.style.display = 'none';
    // if they clicked the bottom div, then scroll back up to the top of the table.
    if (this === footer && footerDivClickCallback) {
      footerDivClickCallback(container);
    }
  } else {
    table.style.display = 'block';
    header.classList.remove('app_table_collapsed_open'); // todo: use app_table_collapsed_expanded
    header.classList.add('app_table_collapse_close'); // todo: use app_table_collapsed_collapsed
    header.classList.add('app_table_collapse_icon'); // todo: use app_table_collapsed_icon
    if (caption) {
      caption.style.visibility = 'hidden';
    }
    footer.style.display = 'block';
  }
};

/**
 * @param {!HTMLElement} table
 * @return {!boolean} true if table should be collapsed, false otherwise.
 */
var shouldTableBeCollapsed = function shouldTableBeCollapsed(table) {
  var classBlacklist = ['navbox', 'vertical-navbox', 'navbox-inner', 'metadata', 'mbox-small'];
  var blacklistIntersects = classBlacklist.some(function (clazz) {
    return table.classList.contains(clazz);
  });
  return table.style.display !== 'none' && !blacklistIntersects;
};

/**
 * @param {!Element} element
 * @return {!boolean} true if element is an infobox, false otherwise.
 */
var isInfobox = function isInfobox(element) {
  return element.classList.contains('infobox');
};

/**
 * @param {!Document} document
 * @param {?string} content HTML string.
 * @return {!HTMLDivElement}
 */
var newCollapsedHeaderDiv = function newCollapsedHeaderDiv(document, content) {
  var div = document.createElement('div');
  div.classList.add('app_table_collapsed_container');
  div.classList.add('app_table_collapsed_open');
  div.innerHTML = content || '';
  return div;
};

/**
 * @param {!Document} document
 * @param {?string} content HTML string.
 * @return {!HTMLDivElement}
 */
var newCollapsedFooterDiv = function newCollapsedFooterDiv(document, content) {
  var div = document.createElement('div');
  div.classList.add('app_table_collapsed_bottom');
  div.classList.add('app_table_collapse_icon'); // todo: use collapsed everywhere
  div.innerHTML = content || '';
  return div;
};

/**
 * @param {!string} title
 * @param {!string[]} headerText
 * @return {!string} HTML string.
 */
var newCaption = function newCaption(title, headerText) {
  var caption = '<strong>' + title + '</strong>';

  caption += '<span class=app_span_collapse_text>';
  if (headerText.length > 0) {
    caption += ': ' + headerText[0];
  }
  if (headerText.length > 1) {
    caption += ', ' + headerText[1];
  }
  if (headerText.length > 0) {
    caption += ' …';
  }
  caption += '</span>';

  return caption;
};

/**
 * @param {!Document} document
 * @param {!Element} content
 * @param {?string} pageTitle
 * @param {?boolean} isMainPage
 * @param {?string} infoboxTitle
 * @param {?string} otherTitle
 * @param {?string} footerTitle
 * @return {void}
 */
var collapseTables = function collapseTables(document, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback) {
  if (isMainPage) {
    return;
  }

  var tables = content.querySelectorAll('table');
  for (var i = 0; i < tables.length; ++i) {
    var table = tables[i];

    if (elementUtilities.findClosestAncestor(table, '.app_table_container') || !shouldTableBeCollapsed(table)) {
      continue;
    }

    // todo: this is actually an array
    var headerText = getTableHeader(table, pageTitle);
    if (!headerText.length && !isInfobox(table)) {
      continue;
    }
    var caption = newCaption(isInfobox(table) ? infoboxTitle : otherTitle, headerText);

    // create the container div that will contain both the original table
    // and the collapsed version.
    var containerDiv = document.createElement('div');
    containerDiv.className = 'app_table_container';
    table.parentNode.insertBefore(containerDiv, table);
    table.parentNode.removeChild(table);

    // remove top and bottom margin from the table, so that it's flush with
    // our expand/collapse buttons
    table.style.marginTop = '0px';
    table.style.marginBottom = '0px';

    var collapsedHeaderDiv = newCollapsedHeaderDiv(document, caption);
    collapsedHeaderDiv.style.display = 'block';

    var collapsedFooterDiv = newCollapsedFooterDiv(document, footerTitle);
    collapsedFooterDiv.style.display = 'none';

    // add our stuff to the container
    containerDiv.appendChild(collapsedHeaderDiv);
    containerDiv.appendChild(table);
    containerDiv.appendChild(collapsedFooterDiv);

    // set initial visibility
    table.style.display = 'none';

    // assign click handler to the collapsed divs
    collapsedHeaderDiv.onclick = toggleCollapseClickCallback.bind(collapsedHeaderDiv);
    collapsedFooterDiv.onclick = toggleCollapseClickCallback.bind(collapsedFooterDiv, footerDivClickCallback);
  }
};

/**
 * If you tap a reference targeting an anchor within a collapsed table, this
 * method will expand the references section. The client can then scroll to the
 * references section.
 *
 * The first reference (an "[A]") in the "enwiki > Airplane" article from ~June
 * 2016 exhibits this issue. (You can copy wikitext from this revision into a
 * test wiki page for testing.)
 * @param  {?Element} element
 * @return {void}
*/
var expandCollapsedTableIfItContainsElement = function expandCollapsedTableIfItContainsElement(element) {
  if (element) {
    var containerSelector = '[class*="app_table_container"]';
    var container = elementUtilities.findClosestAncestor(element, containerSelector);
    if (container) {
      var collapsedDiv = container.firstElementChild;
      if (collapsedDiv && collapsedDiv.classList.contains('app_table_collapsed_open')) {
        collapsedDiv.click();
      }
    }
  }
};

var CollapseTable = {
  toggleCollapseClickCallback: toggleCollapseClickCallback,
  collapseTables: collapseTables,
  expandCollapsedTableIfItContainsElement: expandCollapsedTableIfItContainsElement,
  test: {
    getTableHeader: getTableHeader,
    shouldTableBeCollapsed: shouldTableBeCollapsed,
    isInfobox: isInfobox,
    newCollapsedHeaderDiv: newCollapsedHeaderDiv,
    newCollapsedFooterDiv: newCollapsedFooterDiv,
    newCaption: newCaption
  }
};

/**
 * To widen an image element a css class called 'wideImageOverride' is applied to the image element,
 * however, ancestors of the image element can prevent the widening from taking effect. This method
 * makes minimal adjustments to ancestors of the image element being widened so the image widening
 * can take effect.
 * @param  {!HTMLElement} el Element whose ancestors will be widened
 */
var widenAncestors = function widenAncestors(el) {
  for (var parentElement = el.parentElement; parentElement && !parentElement.classList.contains('content_block'); parentElement = parentElement.parentElement) {
    if (parentElement.style.width) {
      parentElement.style.width = '100%';
    }
    if (parentElement.style.maxWidth) {
      parentElement.style.maxWidth = '100%';
    }
    if (parentElement.style.float) {
      parentElement.style.float = 'none';
    }
  }
};

/**
 * Some images should not be widended. This method makes that determination.
 * @param  {!HTMLElement} image   The image in question
 * @return {boolean}              Whether 'image' should be widened
 */
var shouldWidenImage = function shouldWidenImage(image) {
  // Images within a "<div class='noresize'>...</div>" should not be widened.
  // Example exhibiting links overlaying such an image:
  //   'enwiki > Counties of England > Scope and structure > Local government'
  if (elementUtilities.findClosestAncestor(image, "[class*='noresize']")) {
    return false;
  }

  // Side-by-side images should not be widened. Often their captions mention 'left' and 'right', so
  // we don't want to widen these as doing so would stack them vertically.
  // Examples exhibiting side-by-side images:
  //    'enwiki > Cold Comfort (Inside No. 9) > Casting'
  //    'enwiki > Vincent van Gogh > Letters'
  if (elementUtilities.findClosestAncestor(image, "div[class*='tsingle']")) {
    return false;
  }

  // Imagemaps, which expect images to be specific sizes, should not be widened.
  // Examples can be found on 'enwiki > Kingdom (biology)':
  //    - first non lead image is an image map
  //    - 'Three domains of life > Phylogenetic Tree of Life' image is an image map
  if (image.hasAttribute('usemap')) {
    return false;
  }

  // Images in tables should not be widened - doing so can horribly mess up table layout.
  if (elementUtilities.isNestedInTable(image)) {
    return false;
  }

  return true;
};

/**
 * Removes barriers to images widening taking effect.
 * @param  {!HTMLElement} image   The image in question
 */
var makeRoomForImageWidening = function makeRoomForImageWidening(image) {
  widenAncestors(image);

  // Remove width and height attributes so wideImageOverride width percentages can take effect.
  image.removeAttribute('width');
  image.removeAttribute('height');
};

/**
 * Widens the image.
 * @param  {!HTMLElement} image   The image in question
 */
var widenImage = function widenImage(image) {
  makeRoomForImageWidening(image);
  image.classList.add('wideImageOverride');
};

/**
 * Widens an image if the image is found to be fit for widening.
 * @param  {!HTMLElement} image   The image in question
 * @return {boolean}              Whether or not 'image' was widened
 */
var maybeWidenImage = function maybeWidenImage(image) {
  if (shouldWidenImage(image)) {
    widenImage(image);
    return true;
  }
  return false;
};

var WidenImage = {
  maybeWidenImage: maybeWidenImage,
  test: {
    shouldWidenImage: shouldWidenImage,
    widenAncestors: widenAncestors
  }
};

var pagelib$1 = {
  CollapseTable: CollapseTable,
  WidenImage: WidenImage,
  test: {
    ElementUtilities: elementUtilities
  }
};

// This file exists for CSS packaging only. It imports the override CSS
// JavaScript index file, which also exists only for packaging, as well as the
// real JavaScript, transform/index, it simply re-exports.

module.exports = pagelib$1;


},{}]},{},[1,2,3,4,5,6,7,8,9,10,11,13,14,15]);
