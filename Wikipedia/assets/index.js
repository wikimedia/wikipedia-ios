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
wmf.redLinks = require('wikimedia-page-library').RedLinks
wmf.paragraphs = require('./js/transforms/relocateFirstParagraph')
wmf.images = require('./js/transforms/widenImages')
wmf.media = require('./js/transforms/media')

window.wmf = wmf

},{"./js/elementLocation":3,"./js/findInPage":4,"./js/transforms/collapseTables":6,"./js/transforms/disableFilePageEdit":7,"./js/transforms/footerLegal":8,"./js/transforms/footerMenu":9,"./js/transforms/footerReadMore":10,"./js/transforms/media":11,"./js/transforms/relocateFirstParagraph":12,"./js/transforms/widenImages":13,"./js/utilities":14,"wikimedia-page-library":15}],2:[function(require,module,exports){
const refs = require('./refs')
const utilities = require('./utilities')
const tableCollapser = require('wikimedia-page-library').CollapseTable

/**
 * Type of items users can click which we may need to handle.
 * @type {!Object}
 */
const ItemType = {
  unknown: 0,
  link: 1,
  image: 2,
  reference: 3
}

/**
 * Model of clicked item.
 * Reminder: separate `target` and `href` properties
 * needed to handle non-anchor targets such as images.
 */
class ClickedItem {
  constructor(target, href) {
    this.target = target
    this.href = href
  }
  /**
   * Determines type of item based on its properties.
   * @return {!ItemType} Type of the item
   */
  type() {
    if (refs.isCitation(this.href)) {
      return ItemType.reference
    } else if (this.target.tagName === 'IMG' && this.target.getAttribute( 'data-image-gallery' ) === 'true') {
      return ItemType.image
    } else if (this.href) {
      return ItemType.link
    }
    return ItemType.unknown
  }
}

/**
 * Send messages to native land for respective click types.
 * @param  {!ClickedItem} item the item which was clicked on
 * @return {Boolean} `true` if a message was sent, otherwise `false`
 */
function sendMessageForClickedItem(item){
  switch(item.type()) {
  case ItemType.link:
    sendMessageForLinkWithHref(item.href)
    break
  case ItemType.image:
    sendMessageForImageWithTarget(item.target)
    break
  case ItemType.reference:
    sendMessageForReferenceWithTarget(item.target)
    break
  default:
    return false
  }
  return true
}

/**
 * Sends message for a link click.
 * @param  {!String} href url
 * @return {void}
 */
function sendMessageForLinkWithHref(href){
  if(href[0] === '#'){
    tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)))
  }
  window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
}

/**
 * Sends message for an image click.
 * @param  {!Element} target an image element
 * @return {void}
 */
function sendMessageForImageWithTarget(target){
  window.webkit.messageHandlers.imageClicked.postMessage({
    'src': target.getAttribute('src'),
    'width': target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
    'height': target.naturalHeight,
    'data-file-width': target.getAttribute('data-file-width'),
    'data-file-height': target.getAttribute('data-file-height')
  })
}

/**
 * Sends message for a reference click.
 * @param  {!Element} target an anchor element
 * @return {void}
 */
function sendMessageForReferenceWithTarget(target){
  refs.sendNearbyReferences( target )
}

/**
 * Handler for the click event.
 * @param  {ClickEvent} event the event being handled
 * @return {void}
 */
function handleClickEvent(event){
  const target = event.target
  if(!target) {
    return
  }
  // Find anchor for non-anchor targets - like images.
  const anchorForTarget = utilities.findClosest(target, 'A') || target
  if(!anchorForTarget) {
    return
  }
  const href = anchorForTarget.getAttribute( 'href' )
  if(!href) {
    return
  }
  sendMessageForClickedItem(new ClickedItem(target, href))
}

/**
 * Associate our custom click handler logic with the document `click` event.
 */
document.addEventListener('click', function (event) {
  event.preventDefault()
  handleClickEvent(event)
}, false)
},{"./refs":5,"./utilities":14,"wikimedia-page-library":15}],3:[function(require,module,exports){
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
},{}],4:[function(require,module,exports){
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
},{}],5:[function(require,module,exports){
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
},{"./elementLocation":3}],6:[function(require,module,exports){
const tableCollapser = require('wikimedia-page-library').CollapseTable
var location = require('../elementLocation')

function footerDivClickCallback(container) {
  if(location.isElementTopOnscreen(container)){
    window.scrollTo( 0, container.offsetTop - 10 )
  }
}

function hideTables(content, isMainPage, pageTitle, infoboxTitle, otherTitle, footerTitle) {
  tableCollapser.collapseTables(window, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback)
}

exports.hideTables = hideTables
},{"../elementLocation":3,"wikimedia-page-library":15}],7:[function(require,module,exports){

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
      containerAnchor.title = wmfMenuItem.title
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
  const headingElement = document.getElementById(headingID)
  headingElement.innerText = headingString
  headingElement.title = headingString
}

exports.IconTypeEnum = IconTypeEnum
exports.setHeading = setHeading
exports.addItem = addItem
},{}],10:[function(require,module,exports){

var _saveButtonClickHandler = null
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

    var outerAnchorContainer = document.createElement('a')
    outerAnchorContainer.id = index
    outerAnchorContainer.className = 'footer_readmore_page'

    var hasImage = wmfPage.thumbnail && wmfPage.thumbnail.source
    if(hasImage){
      var image = document.createElement('div')
      image.style.backgroundImage = `url(${wmfPage.thumbnail.source})`
      image.classList.add('footer_readmore_page_image')
      outerAnchorContainer.appendChild(image)
    }

    var innerDivContainer = document.createElement('div')
    innerDivContainer.classList.add('footer_readmore_page_container')
    outerAnchorContainer.appendChild(innerDivContainer)
    outerAnchorContainer.href = `/wiki/${encodeURI(wmfPage.title)}`

    if(wmfPage.title){
      var title = document.createElement('div')
      title.id = index
      title.className = 'footer_readmore_page_title'
      var displayTitle = wmfPage.title.replace(/_/g, ' ')
      title.innerHTML = displayTitle
      outerAnchorContainer.title = displayTitle
      innerDivContainer.appendChild(title)
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
      innerDivContainer.appendChild(descriptionEl)
    }

    var saveButton = document.createElement('div')
    saveButton.id = `${_saveButtonIDPrefix}${encodeURI(wmfPage.title)}`
    saveButton.innerText = _saveForLaterString
    saveButton.title = _saveForLaterString
    saveButton.className = 'footer_readmore_page_save'
    saveButton.addEventListener('click', function(event){
      event.stopPropagation()
      event.preventDefault()
      _saveButtonClickHandler(wmfPage.title)
    }, false)
    innerDivContainer.appendChild(saveButton)

    return document.createDocumentFragment().appendChild(outerAnchorContainer)
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
  const text = isSaved ? _savedForLaterString : _saveForLaterString
  button.innerText = text
  button.title = text
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

function add(baseURL, title, saveForLaterString, savedForLaterString, containerID, saveButtonClickHandler, titlesShownHandler) {
  _readMoreContainer = document.getElementById(containerID)
  _saveButtonClickHandler = saveButtonClickHandler
  _titlesShownHandler = titlesShownHandler
  _saveForLaterString = saveForLaterString
  _savedForLaterString = savedForLaterString

  fetchReadMore(baseURL, title, showReadMore)
}

function setHeading(headingString, headingID) {
  const headingElement = document.getElementById(headingID)
  headingElement.innerText = headingString
  headingElement.title = headingString
}

exports.setHeading = setHeading
exports.setTitleIsSaved = setTitleIsSaved
exports.add = add
},{}],11:[function(require,module,exports){

function sendMediaWithTarget(target) {
  window.webkit.messageHandlers.mediaClicked.postMessage({'media':target.alt})
}

function handleMediaClickEvent(event){
  const target = event.target;
  if(!target) {
    return
  }
  const file = target.getAttribute('alt');
  if(!file) {
    return
  }
  sendMediaWithTarget(target)
}

function install() {
  Array.prototype.slice.call(document.querySelectorAll('img[alt^="File:"],[alt$=".ogv"]')).forEach(function(element){
    element.addEventListener('click',function(event){
      event.preventDefault();
      handleMediaClickEvent(event)
    },false)
  })
}

exports.install = install;

},{}],12:[function(require,module,exports){

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
},{}],13:[function(require,module,exports){

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
},{"wikimedia-page-library":15}],14:[function(require,module,exports){

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
},{}],14:[function(require,module,exports){
(function (global, factory) {
	typeof exports === 'object' && typeof module !== 'undefined' ? module.exports = factory() :
	typeof define === 'function' && define.amd ? define(factory) :
	(global.pagelib = factory());
}(this, (function () { 'use strict';

// This file exists for CSS packaging only. It imports the CSS which is to be
// packaged in the override CSS build product.

// todo: delete Empty.css when other overrides exist

/**
 * Polyfill function that tells whether a given element matches a selector.
 * @param {!Element} el Element
 * @param {!string} selector Selector to look for
 * @return {!boolean} Whether the element matches the selector
 */
var matchesSelector = function matchesSelector(el, selector) {
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

// https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent/CustomEvent#Polyfill
// Required by Android API 16 AOSP Nexus S emulator.
// eslint-disable-next-line no-undef
var CustomEvent = typeof window !== 'undefined' && window.CustomEvent || function (type) {
  var parameters = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : { bubbles: false, cancelable: false, detail: undefined };

  // eslint-disable-next-line no-undef
  var event = document.createEvent('CustomEvent');
  event.initCustomEvent(type, parameters.bubbles, parameters.cancelable, parameters.detail);
  return event;
};

var Polyfill = { matchesSelector: matchesSelector, CustomEvent: CustomEvent };

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
  for (parentElement = el.parentElement; parentElement && !Polyfill.matchesSelector(parentElement, selector); parentElement = parentElement.parentElement) {
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
  findClosestAncestor: findClosestAncestor,
  isNestedInTable: isNestedInTable
};

var SECTION_TOGGLED_EVENT_TYPE = 'section-toggled';

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

/**
 * @typedef {function} FooterDivClickCallback
 * @param {!HTMLElement}
 * @return {void}
 */

/**
 * Ex: toggleCollapseClickCallback.bind(el, (container) => {
 *       window.scrollTo(0, container.offsetTop - transformer.getDecorOffset())
 *     })
 * @this HTMLElement
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {boolean} true if collapsed, false if expanded.
 */
var toggleCollapseClickCallback = function toggleCollapseClickCallback(footerDivClickCallback) {
  var container = this.parentNode;
  var header = container.children[0];
  var table = container.children[1];
  var footer = container.children[2];
  var caption = header.querySelector('.app_table_collapsed_caption');
  var collapsed = table.style.display !== 'none';
  if (collapsed) {
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
  return collapsed;
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
 * @param {!Window} window
 * @param {!Element} content
 * @param {?string} pageTitle
 * @param {?boolean} isMainPage
 * @param {?string} infoboxTitle
 * @param {?string} otherTitle
 * @param {?string} footerTitle
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {void}
 */
var collapseTables = function collapseTables(window, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback) {
  if (isMainPage) {
    return;
  }

  var tables = content.querySelectorAll('table');

  var _loop = function _loop(i) {
    var table = tables[i];

    if (elementUtilities.findClosestAncestor(table, '.app_table_container') || !shouldTableBeCollapsed(table)) {
      return 'continue';
    }

    // todo: this is actually an array
    var headerText = getTableHeader(table, pageTitle);
    if (!headerText.length && !isInfobox(table)) {
      return 'continue';
    }
    var caption = newCaption(isInfobox(table) ? infoboxTitle : otherTitle, headerText);

    // create the container div that will contain both the original table
    // and the collapsed version.
    var containerDiv = window.document.createElement('div');
    containerDiv.className = 'app_table_container';
    table.parentNode.insertBefore(containerDiv, table);
    table.parentNode.removeChild(table);

    // remove top and bottom margin from the table, so that it's flush with
    // our expand/collapse buttons
    table.style.marginTop = '0px';
    table.style.marginBottom = '0px';

    var collapsedHeaderDiv = newCollapsedHeaderDiv(window.document, caption);
    collapsedHeaderDiv.style.display = 'block';

    var collapsedFooterDiv = newCollapsedFooterDiv(window.document, footerTitle);
    collapsedFooterDiv.style.display = 'none';

    // add our stuff to the container
    containerDiv.appendChild(collapsedHeaderDiv);
    containerDiv.appendChild(table);
    containerDiv.appendChild(collapsedFooterDiv);

    // set initial visibility
    table.style.display = 'none';

    // eslint-disable-next-line require-jsdoc, no-loop-func
    var dispatchSectionToggledEvent = function dispatchSectionToggledEvent(collapsed) {
      return (
        // eslint-disable-next-line no-undef
        window.dispatchEvent(new Polyfill.CustomEvent(SECTION_TOGGLED_EVENT_TYPE, { collapsed: collapsed }))
      );
    };

    // assign click handler to the collapsed divs
    collapsedHeaderDiv.onclick = function () {
      var collapsed = toggleCollapseClickCallback.bind(collapsedHeaderDiv)();
      dispatchSectionToggledEvent(collapsed);
    };
    collapsedFooterDiv.onclick = function () {
      var collapsed = toggleCollapseClickCallback.bind(collapsedFooterDiv, footerDivClickCallback)();
      dispatchSectionToggledEvent(collapsed);
    };
  };

  for (var i = 0; i < tables.length; ++i) {
    var _ret = _loop(i);

    if (_ret === 'continue') continue;
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
  SECTION_TOGGLED_EVENT_TYPE: SECTION_TOGGLED_EVENT_TYPE,
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
 * Configures span to be suitable replacement for red link anchor.
 * @param {!HTMLSpanElement} span The span element to configure as anchor replacement.
 * @param {!HTMLAnchorElement} anchor The anchor element being replaced.
 * @return {void}
 */
var configureRedLinkTemplate = function configureRedLinkTemplate(span, anchor) {
  span.innerHTML = anchor.innerHTML;
  span.setAttribute('class', anchor.getAttribute('class'));
};

/**
 * Finds red links in a document or document fragment.
 * @param {!(Document|DocumentFragment)} content Document or fragment in which to seek red links.
 * @return {!HTMLAnchorElement[]} Array of zero or more red link anchors.
 */
var redLinkAnchorsInContent = function redLinkAnchorsInContent(content) {
  return Array.prototype.slice.call(content.querySelectorAll('a.new'));
};

/**
 * Makes span to be used as cloning template for red link anchor replacements.
 * @param  {!Document} document Document to use to create span element. Reminder: this can't be a
 * document fragment because fragments don't implement 'createElement'.
 * @return {!HTMLSpanElement} Span element suitable for use as template for red link anchor
 * replacements.
 */
var newRedLinkTemplate = function newRedLinkTemplate(document) {
  return document.createElement('span');
};

/**
 * Replaces anchor with span.
 * @param  {!HTMLAnchorElement} anchor Anchor element.
 * @param  {!HTMLSpanElement} span Span element.
 * @return {void}
 */
var replaceAnchorWithSpan = function replaceAnchorWithSpan(anchor, span) {
  return anchor.parentNode.replaceChild(span, anchor);
};

/**
 * Hides red link anchors in either a document or a document fragment so they are unclickable and
 * unfocusable.
 * @param {!Document} document Document in which to hide red links.
 * @param {?DocumentFragment} fragment If specified, red links are hidden in the fragment and the
 * document is used only for span cloning.
 * @return {void}
 */
var hideRedLinks = function hideRedLinks(document, fragment) {
  var spanTemplate = newRedLinkTemplate(document);
  var content = fragment !== undefined ? fragment : document;
  redLinkAnchorsInContent(content).forEach(function (redLink) {
    var span = spanTemplate.cloneNode(false);
    configureRedLinkTemplate(span, redLink);
    replaceAnchorWithSpan(redLink, span);
  });
};

var RedLinks = {
  hideRedLinks: hideRedLinks,
  test: {
    configureRedLinkTemplate: configureRedLinkTemplate,
    redLinkAnchorsInContent: redLinkAnchorsInContent,
    newRedLinkTemplate: newRedLinkTemplate,
    replaceAnchorWithSpan: replaceAnchorWithSpan
  }
};

/**
 * To widen an image element a css class called 'wideImageOverride' is applied to the image element,
 * however, ancestors of the image element can prevent the widening from taking effect. This method
 * makes minimal adjustments to ancestors of the image element being widened so the image widening
 * can take effect.
 * @param  {!HTMLElement} el Element whose ancestors will be widened
 * @return {void}
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
 * Some images should not be widened. This method makes that determination.
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
 * @return {void}
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
 * @return {void}
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
  RedLinks: RedLinks,
  WidenImage: WidenImage,
  test: {
    ElementUtilities: elementUtilities, Polyfill: Polyfill
  }
};

// This file exists for CSS packaging only. It imports the override CSS
// JavaScript index file, which also exists only for packaging, as well as the
// real JavaScript, transform/index, it simply re-exports.

return pagelib$1;

})));


},{}]},{},[1,2,3,4,5,6,7,8,9,10,11,12,13,14]);
