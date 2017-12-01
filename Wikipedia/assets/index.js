(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.elementLocation = require('./js/elementLocation')
wmf.utilities = require('./js/utilities')
wmf.findInPage = require('./js/findInPage')
wmf.footerReadMore = require('wikimedia-page-library').FooterReadMore
wmf.footerMenu = require('wikimedia-page-library').FooterMenu
wmf.footerContainer = require('wikimedia-page-library').FooterContainer
wmf.imageDimming = require('wikimedia-page-library').DimImagesTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.platform = require('wikimedia-page-library').PlatformTransform
wmf.sections = require('./js/sections')
wmf.footers = require('./js/footers')

window.wmf = wmf
},{"./js/elementLocation":3,"./js/findInPage":4,"./js/footers":5,"./js/sections":7,"./js/utilities":9,"wikimedia-page-library":11}],2:[function(require,module,exports){
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

  // Handle edit links.
  if (anchorForTarget.getAttribute( 'data-action' ) === 'edit_section'){
    window.webkit.messageHandlers.editClicked.postMessage({
      'sectionId': anchorForTarget.getAttribute( 'data-id' )
    })
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
},{"./refs":6,"./utilities":9,"wikimedia-page-library":11}],3:[function(require,module,exports){
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

const requirements = {
  footerReadMore: require('wikimedia-page-library').FooterReadMore,
  footerMenu: require('wikimedia-page-library').FooterMenu,
  footerLegal: require('wikimedia-page-library').FooterLegal,
  footerContainer: require('wikimedia-page-library').FooterContainer
}

class Footer {
  // 'localizedStrings' is object containing the following localized strings key/value pairs: 'readMoreHeading', 'licenseString', 'licenseSubstitutionString', 'viewInBrowserString', 'menuHeading', 'menuLanguagesTitle', 'menuLastEditedTitle', 'menuLastEditedSubtitle', 'menuTalkPageTitle', 'menuPageIssuesTitle', 'menuDisambiguationTitle', 'menuCoordinateTitle'
  constructor(articleTitle, menuItems, hasReadMore, readMoreItemCount, localizedStrings, proxyURL) {
    this.articleTitle = articleTitle
    this.menuItems = menuItems
    this.hasReadMore = hasReadMore
    this.readMoreItemCount = readMoreItemCount
    this.localizedStrings = localizedStrings
    this.proxyURL = proxyURL
  }
  addContainer() {
    if (requirements.footerContainer.isContainerAttached(document) === false) {
      document.querySelector('body').appendChild(requirements.footerContainer.containerFragment(document))
      window.webkit.messageHandlers.footerContainerAdded.postMessage('added')
    }
  }
  addDynamicBottomPadding() {
    window.addEventListener('resize', function(){requirements.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)})
  }
  addMenu() {
    requirements.footerMenu.setHeading(this.localizedStrings.menuHeading, 'pagelib_footer_container_menu_heading', document)
    this.menuItems.forEach(item => {
      let title = ''
      let subtitle = ''
      let menuItemTypeString = ''
      switch(item) {
      case requirements.footerMenu.MenuItemType.languages:
        menuItemTypeString = 'languages'
        title = this.localizedStrings.menuLanguagesTitle
        break
      case requirements.footerMenu.MenuItemType.lastEdited:
        menuItemTypeString = 'lastEdited'
        title = this.localizedStrings.menuLastEditedTitle
        subtitle = this.localizedStrings.menuLastEditedSubtitle
        break
      case requirements.footerMenu.MenuItemType.pageIssues:
        menuItemTypeString = 'pageIssues'
        title = this.localizedStrings.menuPageIssuesTitle
        break
      case requirements.footerMenu.MenuItemType.disambiguation:
        menuItemTypeString = 'disambiguation'
        title = this.localizedStrings.menuDisambiguationTitle
        break
      case requirements.footerMenu.MenuItemType.coordinate:
        menuItemTypeString = 'coordinate'
        title = this.localizedStrings.menuCoordinateTitle
        break
      case requirements.footerMenu.MenuItemType.talkPage:
        menuItemTypeString = 'talkPage'
        title = this.localizedStrings.menuTalkPageTitle
        break
      default:
      }
      const itemSelectionHandler = payload => window.webkit.messageHandlers.footerMenuItemClicked.postMessage({'selection': menuItemTypeString, 'payload': payload})
      requirements.footerMenu.maybeAddItem(title, subtitle, item, 'pagelib_footer_container_menu_items', itemSelectionHandler, document)
    })
  }
  addReadMore() {
    if (this.hasReadMore){
      requirements.footerReadMore.setHeading(this.localizedStrings.readMoreHeading, 'pagelib_footer_container_readmore_heading', document)
      const saveButtonTapHandler = title => window.webkit.messageHandlers.footerReadMoreSaveClicked.postMessage({'title': title})
      const titlesShownHandler = titles => {
        window.webkit.messageHandlers.footerReadMoreTitlesShown.postMessage(titles)
        requirements.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)
      }
      requirements.footerReadMore.add(this.articleTitle, this.readMoreItemCount, 'pagelib_footer_container_readmore_pages', this.proxyURL, saveButtonTapHandler, titlesShownHandler, document)
    }
  }
  addLegal() {
    const licenseLinkClickHandler = () => window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked')
    const viewInBrowserLinkClickHandler = () => window.webkit.messageHandlers.footerBrowserLinkClicked.postMessage('linkClicked')
    requirements.footerLegal.add(document, this.localizedStrings.licenseString, this.localizedStrings.licenseSubstitutionString, 'pagelib_footer_container_legal', licenseLinkClickHandler, this.localizedStrings.viewInBrowserString, viewInBrowserLinkClickHandler)
  }
  add() {
    this.addContainer()
    this.addDynamicBottomPadding()
    this.addMenu()
    this.addReadMore()
    this.addLegal()
  }
}

exports.Footer = Footer
},{"wikimedia-page-library":11}],6:[function(require,module,exports){
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
},{"./elementLocation":3}],7:[function(require,module,exports){

const requirements = {
  editTransform: require('wikimedia-page-library').EditTransform,
  utilities: require('./utilities'),
  tables: require('wikimedia-page-library').CollapseTable,
  themes: require('wikimedia-page-library').ThemeTransform,
  redLinks: require('wikimedia-page-library').RedLinks,
  paragraphs: require('./transforms/relocateFirstParagraph'),
  widenImage: require('wikimedia-page-library').WidenImage,
  location: require('./elementLocation')
}

// backfill fragments with "createElement" so transforms will work as well with fragments as
// they do with documents
DocumentFragment.prototype.createElement = name => document.createElement(name)

const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

class Language {
  constructor(code, dir, isRTL) {
    this.code = code
    this.dir = dir
    this.isRTL = isRTL
  }
}

class Article {
  constructor(ismain, title, displayTitle, description, editable, language) {
    this.ismain = ismain
    this.title = title
    this.displayTitle = displayTitle
    this.description = description
    this.editable = editable
    this.language = language
  }
  descriptionParagraph() {
    if(this.description !== undefined && this.description.length > 0){
      return `<p id='entity_description'>${this.description}</p>`
    }
    return ''
  }
}

class Section {
  constructor(level, line, anchor, id, text, article) {
    this.level = level
    this.line = line
    this.anchor = anchor
    this.id = id
    this.text = text
    this.article = article
  }

  headingTagSize() {
    return Math.max(1, Math.min(parseInt(this.level), 6))
  }

  headingTag() {
    if(this.isLeadSection()){
      return `<h1 class='section_heading' ${this.anchorAsElementId()} sectionId='${this.id}'>
                ${this.article.displayTitle}
              </h1>${this.article.descriptionParagraph()}`
    }
    const hSize = this.headingTagSize()
    return `<h${hSize} class="section_heading" data-id="${this.id}" id="${this.anchor}">
              ${this.line}
            </h${hSize}>`
  }

  isLeadSection() {
    return this.id === 0
  }

  isNonMainPageLeadSection() {
    return this.isLeadSection() && !this.article.ismain
  }

  anchorAsElementId() {
    return this.anchor === undefined || this.anchor.length === 0 ? '' : `id='${this.anchor}'`
  }

  shouldWrapInTable() {
    return ['References', 'External links', 'Notes', 'Further reading', 'Bibliography'].indexOf(this.line) != -1
  }

  html() {
    if(this.shouldWrapInTable()){
      return `<table><th>${this.line}</th><tr><td>${this.text}</td></tr></table>`
    }
    return this.text
  }

  containerDiv() {
    const container = document.createElement('div')
    container.id = `section_heading_and_content_block_${this.id}`
    container.innerHTML = `
        ${this.article.ismain ? '' : this.headingTag()}
        <div id="content_block_${this.id}" class="content_block">
            ${this.isNonMainPageLeadSection() ? '<hr id="content_block_0_hr">' : ''}
            ${this.html()}
        </div>`
    return container
  }
}

const processResponseStatus = response => {
  if (response.status === 200) { // can use status 0 if loading local files
    return Promise.resolve(response)
  }
  return Promise.reject(new Error(response.statusText))
}

const extractResponseJSON = response => response.json()

const fragmentForSection = section => {
  const fragment = document.createDocumentFragment()
  const container = section.containerDiv() // do not append this to document. keep unattached to main DOM (ie headless) until transforms have been run on the fragment
  fragment.appendChild(container)
  return fragment
}

const applyTransformationsToFragment = (fragment, article, isLead) => {
  requirements.redLinks.hideRedLinks(document, fragment)

  if(!article.ismain && isLead){
    requirements.paragraphs.moveFirstGoodParagraphAfterElement('content_block_0_hr', fragment)
  }

  const isFilePage = fragment.querySelector('#filetoc') !== null
  if(!article.ismain && !isFilePage){
    if (isLead){
      // Add lead section edit button after the lead section horizontal rule element.
      const hr = fragment.querySelector('#content_block_0_hr')
      hr.parentNode.insertBefore(
        requirements.editTransform.newEditSectionButton(fragment, 0),
        hr.nextSibling
      )
    }else{
      // Add non-lead section edit buttons inside respective header elements.
      const heading = fragment.querySelector('.section_heading[data-id]')
      heading.appendChild(requirements.editTransform.newEditSectionButton(fragment, heading.getAttribute('data-id')))
    }
  }

  const tableFooterDivClickCallback = container => {
    if(requirements.location.isElementTopOnscreen(container)){
      window.scrollTo( 0, container.offsetTop - 10 )
    }
  }

  // Adds table collapsing header/footers.
  requirements.tables.adjustTables(window, fragment, article.displayTitle, article.ismain, this.collapseTablesInitially, this.collapseTablesLocalizedStrings.tableInfoboxTitle, this.collapseTablesLocalizedStrings.tableOtherTitle, this.collapseTablesLocalizedStrings.tableFooterTitle, tableFooterDivClickCallback)

  // Prevents some collapsed tables from scrolling side-to-side.
  // May want to move this to wikimedia-page-library if there are no issues.
  Array.from(fragment.querySelectorAll('.app_table_container *[class~="nowrap"]')).forEach(function(el) {el.classList.remove('nowrap')})

  // 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
  // WidenImage's maybeWidenImage code will do further checks before it widens an image.
  Array.from(fragment.querySelectorAll('img'))
    .filter(image => image.getAttribute('data-image-gallery') === 'true')
    .forEach(requirements.widenImage.maybeWidenImage)

  // Classifies some tricky elements like math formula images (examples are first images on
  // 'enwiki > Quadradic equation' and 'enwiki > Away colors > Association football'). See the
  // 'classifyElements' method itself for other examples.
  requirements.themes.classifyElements(fragment)
}

const transformAndAppendSection = (section, mainContentDiv) => {
  const fragment = fragmentForSection(section)
  // Transform the fragments *before* attaching them to the main DOM.
  applyTransformationsToFragment(fragment, section.article, section.isLeadSection())
  mainContentDiv.appendChild(fragment)
}

//early page-wide transforms which happen before any sections have been appended
const performEarlyNonSectionTransforms = article => {
  requirements.utilities.setPageProtected(!article.editable)
  requirements.utilities.setLanguage(article.language.code, article.language.dir, article.language.isRTL ? 'rtl': 'ltr')
}

const extractSectionsJSON = json => json['mobileview']['sections']

const transformAndAppendLeadSectionToMainContentDiv = (leadSectionJSON, article, mainContentDiv) => {
  const leadModel = new Section(leadSectionJSON.level, leadSectionJSON.line, leadSectionJSON.anchor, leadSectionJSON.id, leadSectionJSON.text, article)
  transformAndAppendSection(leadModel, mainContentDiv)
}

const transformAndAppendNonLeadSectionsToMainContentDiv = (sectionsJSON, article, mainContentDiv) => {
  sectionsJSON.forEach((sectionJSON, index) => {
    if (index > 0) {
      const sectionModel = new Section(sectionJSON.level, sectionJSON.line, sectionJSON.anchor, sectionJSON.id, sectionJSON.text, article)
      transformAndAppendSection(sectionModel, mainContentDiv)
    }
  })
}

const scrollToSection = hash => {
  if (hash !== '') {
    setTimeout(() => {
      location.hash = ''
      location.hash = hash
    }, 50)
  }
}

const fetchTransformAndAppendSectionsToDocument = (article, articleSectionsURL, hash, successCallback) => {
  performEarlyNonSectionTransforms(article)
  const mainContentDiv = document.querySelector('div.content')
  fetch(articleSectionsURL)
  .then(processResponseStatus)
  .then(extractResponseJSON)
  .then(extractSectionsJSON)
  .then(sectionsJSON => {
    if (sectionsJSON.length > 0) {
      transformAndAppendLeadSectionToMainContentDiv(sectionsJSON[0], article, mainContentDiv)
    }
    // Giving the lead section a tiny head-start speeds up its appearance dramatically.
    const nonLeadDelay = 50
    setTimeout(() => {
      transformAndAppendNonLeadSectionsToMainContentDiv(sectionsJSON, article, mainContentDiv)
      scrollToSection(hash)
      successCallback()
    }, nonLeadDelay)
  })
  .catch(error => console.log(`Promise was rejected with error: ${error}`))
}

// Object containing the following localized strings key/value pairs: 'tableInfoboxTitle', 'tableOtherTitle', 'tableFooterTitle'
exports.collapseTablesLocalizedStrings = undefined
exports.collapseTablesInitially = false

exports.sectionErrorMessageLocalizedString  = undefined
exports.fetchTransformAndAppendSectionsToDocument = fetchTransformAndAppendSectionsToDocument
exports.Language = Language
exports.Article = Article
},{"./elementLocation":3,"./transforms/relocateFirstParagraph":8,"./utilities":9,"wikimedia-page-library":11}],8:[function(require,module,exports){

function moveFirstGoodParagraphAfterElement(preceedingElementID, content ) {
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

  var preceedingElement = content.getElementById( preceedingElementID )
  if(!preceedingElement) return

  function isParagraphGood(p) {
    // Narrow down to first P which is direct child of content_block_0 DIV.
    // (Don't want to yank P from somewhere in the middle of a table!)
    if(p.parentNode == block_0) {
                // Ensure the P being pulled up has at least a couple lines of text.
                // Otherwise silly things like a empty P or P which only contains a
                // BR tag will get pulled up (see articles on "Chemical Reaction",
                // "Hawaii", "United States", "Color" and "Academy (educational
                // institution)").

      if(p.innerHTML.indexOf('id="coordinates"') !== -1) {
        return false
      }

      var minLength = 60
      var pIsTooSmall = p.textContent.length < minLength
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

  // Attach the fragment just after `preceedingElement`.
  // insertBefore() on a fragment inserts "the children of the fragment, not the fragment itself."
  // https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
  block_0.insertBefore(fragmentOfItemsToRelocate, preceedingElement.nextSibling)
}

exports.moveFirstGoodParagraphAfterElement = moveFirstGoodParagraphAfterElement
},{}],9:[function(require,module,exports){

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
},{}],10:[function(require,module,exports){
// This file keeps the same area of the article onscreen after rotate or tablet TOC toggle.
const utilities = require('./utilities')

var topElement = undefined
var relativeYOffset = 0

const relativeYOffsetForElement = function(element) {
  const rect = element.getBoundingClientRect()
  return rect.top / rect.height
}

const recordTopElementAndItsRelativeYOffset = function() {
  topElement = document.elementFromPoint( window.innerWidth / 2, window.innerHeight / 3 )
  topElement = utilities.findClosest(topElement, 'div#content > div') || topElement
  if (topElement) {
    relativeYOffset = relativeYOffsetForElement(topElement)
  } else {
    relativeYOffset = 0
  }
}

const yOffsetFromRelativeYOffsetForElement = function(element) {
  const rect = element.getBoundingClientRect()
  return window.scrollY + rect.top - relativeYOffset * rect.height
}

const scrollToSamePlaceBeforeResize = function() {
  if (!topElement) {
    return
  }
  window.scrollTo(0, yOffsetFromRelativeYOffsetForElement(topElement))
}

window.addEventListener('resize', function (event) {
  setTimeout(scrollToSamePlaceBeforeResize, 50)
})

var timer = null
window.addEventListener('scroll', function() {
  if(timer !== null) {
    clearTimeout(timer)
  }
  timer = setTimeout(recordTopElementAndItsRelativeYOffset, 250)
}, false)
},{"./utilities":9}],11:[function(require,module,exports){
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

/**
 * @param {!Element} element
 * @param {!string} selector
 * @return {!Array.<Element>}
 */
var querySelectorAll = function querySelectorAll(element, selector) {
  return Array.prototype.slice.call(element.querySelectorAll(selector));
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

var Polyfill = {
  matchesSelector: matchesSelector,
  querySelectorAll: querySelectorAll,
  CustomEvent: CustomEvent
};

// todo: drop ancestor consideration and move to Polyfill.closest().
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
 * @param {?Element} element
 * @param {!string} property
 * @return {?Element} The inclusive first element with an inline style or undefined.
 */
var closestInlineStyle = function closestInlineStyle(element, property) {
  for (var el = element; el; el = el.parentElement) {
    if (el.style[property]) {
      return el;
    }
  }
  return undefined;
};

/**
 * Determines if element has a table ancestor.
 * @param  {!Element}  el   Element
 * @return {!boolean}       Whether table ancestor of 'el' is found
 */
var isNestedInTable = function isNestedInTable(el) {
  return Boolean(findClosestAncestor(el, 'table'));
};

/**
 * @param {!HTMLElement} element
 * @return {!boolean} true if element affects layout, false otherwise.
 */
var isVisible = function isVisible(element) {
  return (
    // https://github.com/jquery/jquery/blob/305f193/src/css/hiddenVisibleSelectors.js#L12
    Boolean(element.offsetWidth || element.offsetHeight || element.getClientRects().length)
  );
};

/**
 * Copy existing attributes from source to destination as data-* attributes.
 * @param {!HTMLElement} source
 * @param {!HTMLElement} destination
 * @param {!Array.<string>} attributes
 * @return {void}
 */
var copyAttributesToDataAttributes = function copyAttributesToDataAttributes(source, destination, attributes) {
  attributes.filter(function (attribute) {
    return source.hasAttribute(attribute);
  }).forEach(function (attribute) {
    return destination.setAttribute('data-' + attribute, source.getAttribute(attribute));
  });
};

/**
 * Copy existing data-* attributes from source to destination as attributes.
 * @param {!HTMLElement} source
 * @param {!HTMLElement} destination
 * @param {!Array.<string>} attributes
 * @return {void}
 */
var copyDataAttributesToAttributes = function copyDataAttributesToAttributes(source, destination, attributes) {
  attributes.filter(function (attribute) {
    return source.hasAttribute('data-' + attribute);
  }).forEach(function (attribute) {
    return destination.setAttribute(attribute, source.getAttribute('data-' + attribute));
  });
};

var elementUtilities = {
  findClosestAncestor: findClosestAncestor,
  isNestedInTable: isNestedInTable,
  closestInlineStyle: closestInlineStyle,
  isVisible: isVisible,
  copyAttributesToDataAttributes: copyAttributesToDataAttributes,
  copyDataAttributesToAttributes: copyDataAttributesToAttributes
};

// Elements marked with these classes indicate certain ancestry constraints that are
// difficult to describe as CSS selectors.
var CONSTRAINT = {
  IMAGE_PRESUMES_WHITE_BACKGROUND: 'pagelib_theme_image_presumes_white_background',
  DIV_DO_NOT_APPLY_BASELINE: 'pagelib_theme_div_do_not_apply_baseline'
};

// Theme to CSS classes.
var THEME = {
  DEFAULT: 'pagelib_theme_default',
  DARK: 'pagelib_theme_dark',
  SEPIA: 'pagelib_theme_sepia',
  BLACK: 'pagelib_theme_black'
};

/**
 * @param {!Document} document
 * @param {!string} theme
 * @return {void}
 */
var setTheme = function setTheme(document, theme) {
  var html = document.querySelector('html');

  // Set the new theme.
  html.classList.add(theme);

  // Clear any previous theme.
  for (var key in THEME) {
    if (Object.prototype.hasOwnProperty.call(THEME, key) && THEME[key] !== theme) {
      html.classList.remove(THEME[key]);
    }
  }
};

/**
 * Football template image filename regex.
 * https://en.wikipedia.org/wiki/Template:Football_kit/pattern_list
 * @type {RegExp}
 */
var footballTemplateImageFilenameRegex = new RegExp('Kit_(body|socks|shorts|right_arm|left_arm)(.*).png$');

/* en > Away colours > 793128975 */
/* en > Manchester United F.C. > 793244653 */
/**
 * Determines whether white background should be added to image.
 * @param  {!HTMLImageElement} image
 * @return {!boolean}
 */
var imagePresumesWhiteBackground = function imagePresumesWhiteBackground(image) {
  if (footballTemplateImageFilenameRegex.test(image.src)) {
    return false;
  }
  if (image.classList.contains('mwe-math-fallback-image-inline')) {
    return false;
  }
  return !elementUtilities.closestInlineStyle(image, 'background');
};

/**
 * Annotate elements with CSS classes that can be used by CSS rules. The classes themselves are not
 * theme-dependent so classification only need only occur once after the content is loaded, not
 * every time the theme changes.
 * @param {!Element} element
 * @return {void}
 */
var classifyElements = function classifyElements(element) {
  Polyfill.querySelectorAll(element, 'img').filter(imagePresumesWhiteBackground).forEach(function (image) {
    image.classList.add(CONSTRAINT.IMAGE_PRESUMES_WHITE_BACKGROUND);
  });
  /* en > Away colours > 793128975 */
  /* en > Manchester United F.C. > 793244653 */
  /* en > Pantone > 792312384 */
  /* en > Wikipedia:Graphs_and_charts > 801754530 */
  /* en > PepsiCo > 807406166 */
  /* en > Lua_(programming_language) > 809310207 */
  var selector = ['div.color_swatch div', 'div[style*="position: absolute"]', 'div.barbox table div[style*="background:"]', 'div.chart div[style*="background-color"]', 'div.chart ul li span[style*="background-color"]', 'span.legend-color', 'div.mw-highlight span', 'code.mw-highlight span'].join();
  Polyfill.querySelectorAll(element, selector).forEach(function (element) {
    return element.classList.add(CONSTRAINT.DIV_DO_NOT_APPLY_BASELINE);
  });
};

var ThemeTransform = {
  CONSTRAINT: CONSTRAINT,
  THEME: THEME,
  setTheme: setTheme,
  classifyElements: classifyElements
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
  var headers = Polyfill.querySelectorAll(element, 'th');
  for (var i = 0; i < headers.length; ++i) {
    var header = headers[i];
    var anchors = Polyfill.querySelectorAll(header, 'a');
    if (anchors.length < 3) {
      // Also ignore it if it's identical to the page title.
      if ((header.textContent && header.textContent.length) > 0 && header.textContent !== pageTitle && header.innerHTML !== pageTitle) {
        thArray.push(header.textContent);
      }
    }
    if (thArray.length === 2) {
      // 'newCaption' only ever uses the first 2 items.
      break;
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
 * @param {!Element} container div
 * @param {?Element} trigger element that was clicked or tapped
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {boolean} true if collapsed, false if expanded.
 */
var toggleCollapsedForContainer = function toggleCollapsedForContainer(container, trigger, footerDivClickCallback) {
  var header = container.children[0];
  var table = container.children[1];
  var footer = container.children[2];
  var caption = header.querySelector('.app_table_collapsed_caption');
  var collapsed = table.style.display !== 'none';
  if (collapsed) {
    table.style.display = 'none';
    header.classList.remove('pagelib_collapse_table_collapsed');
    header.classList.remove('pagelib_collapse_table_icon');
    header.classList.add('pagelib_collapse_table_expanded');
    if (caption) {
      caption.style.visibility = 'visible';
    }
    footer.style.display = 'none';
    // if they clicked the bottom div, then scroll back up to the top of the table.
    if (trigger === footer && footerDivClickCallback) {
      footerDivClickCallback(container);
    }
  } else {
    table.style.display = 'block';
    header.classList.remove('pagelib_collapse_table_expanded');
    header.classList.add('pagelib_collapse_table_collapsed');
    header.classList.add('pagelib_collapse_table_icon');
    if (caption) {
      caption.style.visibility = 'hidden';
    }
    footer.style.display = 'block';
  }
  return collapsed;
};

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
  return toggleCollapsedForContainer(container, this, footerDivClickCallback);
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
  div.classList.add('pagelib_collapse_table_collapsed_container');
  div.classList.add('pagelib_collapse_table_expanded');
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
  div.classList.add('pagelib_collapse_table_collapsed_bottom');
  div.classList.add('pagelib_collapse_table_icon');
  div.innerHTML = content || '';
  return div;
};

/**
 * @param {!string} title
 * @param {!Array.<string>} headerText
 * @return {!string} HTML string.
 */
var newCaption = function newCaption(title, headerText) {
  var caption = '<strong>' + title + '</strong>';

  caption += '<span class=pagelib_collapse_table_collapse_text>';
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
 * @param {?boolean} isInitiallyCollapsed
 * @param {?string} infoboxTitle
 * @param {?string} otherTitle
 * @param {?string} footerTitle
 * @param {?FooterDivClickCallback} footerDivClickCallback
 * @return {void}
 */
var adjustTables = function adjustTables(window, content, pageTitle, isMainPage, isInitiallyCollapsed, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback) {
  if (isMainPage) {
    return;
  }

  var tables = content.querySelectorAll('table');

  var _loop = function _loop(i) {
    var table = tables[i];

    if (elementUtilities.findClosestAncestor(table, '.pagelib_collapse_table_container') || !shouldTableBeCollapsed(table)) {
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
    containerDiv.className = 'pagelib_collapse_table_container';
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

    if (!isInitiallyCollapsed) {
      toggleCollapsedForContainer(containerDiv);
    }
  };

  for (var i = 0; i < tables.length; ++i) {
    var _ret = _loop(i);

    if (_ret === 'continue') continue;
  }
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
  adjustTables(window, content, pageTitle, isMainPage, true, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback);
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
    var containerSelector = '[class*="pagelib_collapse_table_container"]';
    var container = elementUtilities.findClosestAncestor(element, containerSelector);
    if (container) {
      var collapsedDiv = container.firstElementChild;
      if (collapsedDiv && collapsedDiv.classList.contains('pagelib_collapse_table_expanded')) {
        collapsedDiv.click();
      }
    }
  }
};

var CollapseTable = {
  SECTION_TOGGLED_EVENT_TYPE: SECTION_TOGGLED_EVENT_TYPE,
  toggleCollapseClickCallback: toggleCollapseClickCallback,
  collapseTables: collapseTables,
  adjustTables: adjustTables,
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

var COMPATIBILITY = {
  FILTER: 'pagelib_compatibility_filter'
};

/**
 * @param {!Document} document
 * @param {!Array.<string>} properties
 * @param {!string} value
 * @return {void}
 */
var isStyleSupported = function isStyleSupported(document, properties, value) {
  var element = document.createElement('span');
  return properties.some(function (property) {
    element.style[property] = value;
    return element.style.cssText;
  });
};

/**
 * @param {!Document} document
 * @return {void}
 */
var isFilterSupported = function isFilterSupported(document) {
  return isStyleSupported(document, ['webkitFilter', 'filter'], 'blur(0)');
};

/**
 * @param {!Document} document
 * @return {void}
 */
var enableSupport = function enableSupport(document) {
  var html = document.querySelector('html');
  if (!isFilterSupported(document)) {
    html.classList.add(COMPATIBILITY.FILTER);
  }
};

var CompatibilityTransform = {
  COMPATIBILITY: COMPATIBILITY,
  enableSupport: enableSupport
};

var CLASS = 'pagelib_dim_images';

// todo: only require a Document
/**
 * @param {!Window} window
 * @param {!boolean} enable
 * @return {void}
 */
var dim = function dim(window, enable) {
  window.document.querySelector('html').classList[enable ? 'add' : 'remove'](CLASS);
};

// todo: only require a Document
/**
 * @param {!Window} window
 * @return {boolean}
 */
var isDim = function isDim(window) {
  return window.document.querySelector('html').classList.contains(CLASS);
};

var DimImagesTransform = {
  CLASS: CLASS,
  isDim: isDim,
  dim: dim
};

var CLASS$1 = {
  CONTAINER: 'pagelib_edit_section_link_container',
  LINK: 'pagelib_edit_section_link',
  PROTECTION: { UNPROTECTED: '', PROTECTED: 'page-protected', FORBIDDEN: 'no-editing' }
};

var DATA_ATTRIBUTE = { SECTION_INDEX: 'data-id', ACTION: 'data-action' };
var ACTION_EDIT_SECTION = 'edit_section';

/**
 * @param {!Document} document
 * @param {!number} index The zero-based index of the section.
 * @return {!HTMLAnchorElement}
 */
var newEditSectionLink = function newEditSectionLink(document, index) {
  var link = document.createElement('a');
  link.href = '';
  link.setAttribute(DATA_ATTRIBUTE.SECTION_INDEX, index);
  link.setAttribute(DATA_ATTRIBUTE.ACTION, ACTION_EDIT_SECTION);
  link.classList.add(CLASS$1.LINK);
  return link;
};

/**
 * @param {!Document} document
 * @param {!number} index The zero-based index of the section.
 * @return {!HTMLSpanElement}
 */
var newEditSectionButton = function newEditSectionButton(document, index) {
  var container = document.createElement('span');
  container.classList.add(CLASS$1.CONTAINER);

  var link = newEditSectionLink(document, index);
  container.appendChild(link);

  return container;
};

var EditTransform = {
  CLASS: CLASS$1,
  newEditSectionButton: newEditSectionButton
};

var classCallCheck = function (instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
};

var createClass = function () {
  function defineProperties(target, props) {
    for (var i = 0; i < props.length; i++) {
      var descriptor = props[i];
      descriptor.enumerable = descriptor.enumerable || false;
      descriptor.configurable = true;
      if ("value" in descriptor) descriptor.writable = true;
      Object.defineProperty(target, descriptor.key, descriptor);
    }
  }

  return function (Constructor, protoProps, staticProps) {
    if (protoProps) defineProperties(Constructor.prototype, protoProps);
    if (staticProps) defineProperties(Constructor, staticProps);
    return Constructor;
  };
}();

/** CSS length value and unit of measure. */
var DimensionUnit = function () {
  createClass(DimensionUnit, null, [{
    key: 'fromElement',

    /**
     * Returns the dimension and units of an Element, usually width or height, as specified by inline
     * style or attribute. This is a pragmatic not bulletproof implementation.
     * @param {!Element} element
     * @param {!string} property
     * @return {?DimensionUnit}
     */
    value: function fromElement(element, property) {
      return element.style.getPropertyValue(property) && DimensionUnit.fromStyle(element.style.getPropertyValue(property)) || element.hasAttribute(property) && new DimensionUnit(element.getAttribute(property)) || undefined;
    }

    /**
     * This is a pragmatic not bulletproof implementation.
     * @param {!string} property
     * @return {!DimensionUnit}
     */

  }, {
    key: 'fromStyle',
    value: function fromStyle(property) {
      var matches = property.match(/(-?\d*\.?\d*)(\D+)?/) || [];
      return new DimensionUnit(matches[1], matches[2]);
    }

    /**
     * @param {!string} value
     * @param {?string} unit Defaults to pixels.
     */

  }]);

  function DimensionUnit(value, unit) {
    classCallCheck(this, DimensionUnit);

    this._value = Number(value);
    this._unit = unit || 'px';
  }

  /** @return {!number} NaN if unknown. */


  createClass(DimensionUnit, [{
    key: 'toString',


    /** @return {!string} */
    value: function toString() {
      return isNaN(this.value) ? '' : '' + this.value + this.unit;
    }
  }, {
    key: 'value',
    get: function get$$1() {
      return this._value;
    }

    /** @return {!string} */

  }, {
    key: 'unit',
    get: function get$$1() {
      return this._unit;
    }
  }]);
  return DimensionUnit;
}();

/** Element width and height dimensions and units. */


var ElementGeometry = function () {
  createClass(ElementGeometry, null, [{
    key: 'from',

    /**
     * @param {!Element} element
     * @return {!ElementGeometry}
     */
    value: function from(element) {
      return new ElementGeometry(DimensionUnit.fromElement(element, 'width'), DimensionUnit.fromElement(element, 'height'));
    }

    /**
     * @param {?DimensionUnit} width
     * @param {?DimensionUnit} height
     */

  }]);

  function ElementGeometry(width, height) {
    classCallCheck(this, ElementGeometry);

    this._width = width;
    this._height = height;
  }

  /**
   * @return {?DimensionUnit}
   */


  createClass(ElementGeometry, [{
    key: 'width',
    get: function get$$1() {
      return this._width;
    }

    /** @return {!number} NaN if unknown. */

  }, {
    key: 'widthValue',
    get: function get$$1() {
      return this._width && !isNaN(this._width.value) ? this._width.value : NaN;
    }

    /** @return {!string} */

  }, {
    key: 'widthUnit',
    get: function get$$1() {
      return this._width && this._width.unit || 'px';
    }

    /**
     * @return {?DimensionUnit}
     */

  }, {
    key: 'height',
    get: function get$$1() {
      return this._height;
    }

    /** @return {!number} NaN if unknown. */

  }, {
    key: 'heightValue',
    get: function get$$1() {
      return this._height && !isNaN(this._height.value) ? this._height.value : NaN;
    }

    /** @return {!string} */

  }, {
    key: 'heightUnit',
    get: function get$$1() {
      return this._height && this._height.unit || 'px';
    }
  }]);
  return ElementGeometry;
}();

/**
 * Ensures the 'Read more' section header can always be scrolled to the top of the screen.
 * @param {!Window} window
 * @return {void}
 */
var updateBottomPaddingToAllowReadMoreToScrollToTop = function updateBottomPaddingToAllowReadMoreToScrollToTop(window) {
  var div = window.document.getElementById('pagelib_footer_container_ensure_can_scroll_to_top');
  var currentPadding = parseInt(div.style.paddingBottom, 10) || 0;
  var height = div.clientHeight - currentPadding;
  var newPadding = Math.max(0, window.innerHeight - height);
  div.style.paddingBottom = newPadding + 'px';
};

/**
 * Allows native code to adjust footer container margins without having to worry about
 * implementation details.
 * @param {!number} margin
 * @param {!Document} document
 * @return {void}
 */
var updateLeftAndRightMargin = function updateLeftAndRightMargin(margin, document) {
  var selectors = ['#pagelib_footer_container_menu_heading', '#pagelib_footer_container_readmore', '#pagelib_footer_container_legal'];
  var elements = Polyfill.querySelectorAll(document, selectors.join());
  elements.forEach(function (element) {
    element.style.marginLeft = margin + 'px';
    element.style.marginRight = margin + 'px';
  });
  var rightOrLeft = document.querySelector('html').dir === 'rtl' ? 'right' : 'left';
  Polyfill.querySelectorAll(document, '.pagelib_footer_menu_item').forEach(function (element) {
    element.style.backgroundPosition = rightOrLeft + ' ' + margin + 'px center';
    element.style.paddingLeft = margin + 'px';
    element.style.paddingRight = margin + 'px';
  });
};

/**
 * Returns a fragment containing structural footer html which may be inserted where needed.
 * @param {!Document} document
 * @return {!DocumentFragment}
 */
var containerFragment = function containerFragment(document) {
  var containerDiv = document.createElement('div');
  var containerFragment = document.createDocumentFragment();
  containerFragment.appendChild(containerDiv);
  containerDiv.innerHTML = '<div id=\'pagelib_footer_container\' class=\'pagelib_footer_container\'>\n    <div id=\'pagelib_footer_container_section_0\'>\n      <div id=\'pagelib_footer_container_menu\'>\n        <div id=\'pagelib_footer_container_menu_heading\' class=\'pagelib_footer_container_heading\'>\n        </div>\n        <div id=\'pagelib_footer_container_menu_items\'>\n        </div>\n      </div>\n    </div>\n    <div id=\'pagelib_footer_container_ensure_can_scroll_to_top\'>\n      <div id=\'pagelib_footer_container_section_1\'>\n        <div id=\'pagelib_footer_container_readmore\'>\n          <div\n            id=\'pagelib_footer_container_readmore_heading\' class=\'pagelib_footer_container_heading\'>\n          </div>\n          <div id=\'pagelib_footer_container_readmore_pages\'>\n          </div>\n        </div>\n      </div>\n      <div id=\'pagelib_footer_container_legal\'></div>\n    </div>\n  </div>';
  return containerFragment;
};

/**
 * Indicates whether container is has already been added.
 * @param {!Document} document
 * @return {boolean}
 */
var isContainerAttached = function isContainerAttached(document) {
  return Boolean(document.querySelector('#pagelib_footer_container'));
};

var FooterContainer = {
  containerFragment: containerFragment,
  isContainerAttached: isContainerAttached, // todo: rename isAttached()?
  updateBottomPaddingToAllowReadMoreToScrollToTop: updateBottomPaddingToAllowReadMoreToScrollToTop,
  updateLeftAndRightMargin: updateLeftAndRightMargin
};

/**
 * @typedef {function} FooterLegalClickCallback
 * @return {void}
 */

/**
  * @typedef {function} FooterBrowserClickCallback
  * @return {void}
  */

/**
 * Adds legal footer html to 'containerID' element.
 * @param {!Element} content
 * @param {?string} licenseString
 * @param {?string} licenseSubstitutionString
 * @param {!string} containerID
 * @param {!FooterLegalClickCallback} licenseLinkClickHandler
 * @param {!string} viewInBrowserString
 * @param {!FooterBrowserClickCallback} browserLinkClickHandler
 * @return {void}
 */
var add = function add(content, licenseString, licenseSubstitutionString, containerID, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler) {
  // todo: don't manipulate the selector. The client can make this an ID if they want it to be.
  var container = content.querySelector('#' + containerID);
  var licenseStringHalves = licenseString.split('$1');

  container.innerHTML = '<div class=\'pagelib_footer_legal_contents\'>\n    <hr class=\'pagelib_footer_legal_divider\'>\n    <span class=\'pagelib_footer_legal_license\'>\n      ' + licenseStringHalves[0] + '\n      <a class=\'pagelib_footer_legal_license_link\'>\n        ' + licenseSubstitutionString + '\n      </a>\n      ' + licenseStringHalves[1] + '\n      <br>\n      <div class="pagelib_footer_browser">\n        <a class=\'pagelib_footer_browser_link\'>\n          ' + viewInBrowserString + '\n        </a>\n      </div>\n    </span>\n  </div>';

  container.querySelector('.pagelib_footer_legal_license_link').addEventListener('click', function () {
    licenseLinkClickHandler();
  });

  container.querySelector('.pagelib_footer_browser_link').addEventListener('click', function () {
    browserLinkClickHandler();
  });
};

var FooterLegal = {
  add: add
};

/**
 * @typedef {function} FooterMenuItemPayloadExtractor
 * @param {!Document} document
 * @return {!Array.<string>} Important - should return empty array if no payload strings.
 */

/**
 * @typedef {function} FooterMenuItemClickCallback
 * @param {!Array.<string>} payload Important - should return empty array if no payload strings.
 * @return {void}
 */

/**
 * @typedef {number} MenuItemType
 */

// eslint-disable-next-line valid-jsdoc
/**
 * Extracts array of no-html page issues strings from document.
 * @type {FooterMenuItemPayloadExtractor}
 */
var pageIssuesStringsArray = function pageIssuesStringsArray(document) {
  var tables = Polyfill.querySelectorAll(document, 'div#content_block_0 table.ambox:not(.ambox-multiple_issues):not(.ambox-notice)');
  // Get the tables into a fragment so we can remove some elements without triggering a layout
  var fragment = document.createDocumentFragment();
  for (var i = 0; i < tables.length; i++) {
    fragment.appendChild(tables[i].cloneNode(true));
  }
  // Remove some element so their text doesn't appear when we use "innerText"
  Polyfill.querySelectorAll(fragment, '.hide-when-compact, .collapsed').forEach(function (el) {
    return el.remove();
  });
  // Get the innerText
  return Polyfill.querySelectorAll(fragment, 'td[class$=mbox-text]').map(function (el) {
    return el.innerText;
  });
};

// eslint-disable-next-line valid-jsdoc
/**
 * Extracts array of disambiguation page urls from document.
 * @type {FooterMenuItemPayloadExtractor}
 */
var disambiguationTitlesArray = function disambiguationTitlesArray(document) {
  return Polyfill.querySelectorAll(document, 'div#content_block_0 div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function (el) {
    return el.href;
  });
};

/**
 * Type representing kinds of menu items.
 * @enum {MenuItemType}
 */
var MenuItemType = {
  languages: 1,
  lastEdited: 2,
  pageIssues: 3,
  disambiguation: 4,
  coordinate: 5,
  talkPage: 6
};

/**
 * Menu item model.
 */

var MenuItem = function () {
  /**
   * MenuItem constructor.
   * @param {!string} title
   * @param {?string} subtitle
   * @param {!MenuItemType} itemType
   * @param {FooterMenuItemClickCallback} clickHandler
   * @return {void}
   */
  function MenuItem(title, subtitle, itemType, clickHandler) {
    classCallCheck(this, MenuItem);

    this.title = title;
    this.subtitle = subtitle;
    this.itemType = itemType;
    this.clickHandler = clickHandler;
    this.payload = [];
  }

  /**
   * Returns icon CSS class for this menu item based on its type.
   * @return {!string}
   */


  createClass(MenuItem, [{
    key: 'iconClass',
    value: function iconClass() {
      switch (this.itemType) {
        case MenuItemType.languages:
          return 'pagelib_footer_menu_icon_languages';
        case MenuItemType.lastEdited:
          return 'pagelib_footer_menu_icon_last_edited';
        case MenuItemType.talkPage:
          return 'pagelib_footer_menu_icon_talk_page';
        case MenuItemType.pageIssues:
          return 'pagelib_footer_menu_icon_page_issues';
        case MenuItemType.disambiguation:
          return 'pagelib_footer_menu_icon_disambiguation';
        case MenuItemType.coordinate:
          return 'pagelib_footer_menu_icon_coordinate';
        default:
          return '';
      }
    }

    /**
     * Returns reference to function for extracting payload when this menu item is tapped.
     * @return {?FooterMenuItemPayloadExtractor}
     */

  }, {
    key: 'payloadExtractor',
    value: function payloadExtractor() {
      switch (this.itemType) {
        case MenuItemType.pageIssues:
          return pageIssuesStringsArray;
        case MenuItemType.disambiguation:
          return disambiguationTitlesArray;
        default:
          return undefined;
      }
    }
  }]);
  return MenuItem;
}();

/**
 * Makes document fragment for a menu item.
 * @param {!MenuItem} menuItem
 * @param {!Document} document
 * @return {!DocumentFragment}
 */


var documentFragmentForMenuItem = function documentFragmentForMenuItem(menuItem, document) {
  var item = document.createElement('div');
  item.className = 'pagelib_footer_menu_item';

  var containerAnchor = document.createElement('a');
  containerAnchor.addEventListener('click', function () {
    menuItem.clickHandler(menuItem.payload);
  });

  item.appendChild(containerAnchor);

  if (menuItem.title) {
    var title = document.createElement('div');
    title.className = 'pagelib_footer_menu_item_title';
    title.innerText = menuItem.title;
    containerAnchor.title = menuItem.title;
    containerAnchor.appendChild(title);
  }

  if (menuItem.subtitle) {
    var subtitle = document.createElement('div');
    subtitle.className = 'pagelib_footer_menu_item_subtitle';
    subtitle.innerText = menuItem.subtitle;
    containerAnchor.appendChild(subtitle);
  }

  var iconClass = menuItem.iconClass();
  if (iconClass) {
    item.classList.add(iconClass);
  }

  return document.createDocumentFragment().appendChild(item);
};

/**
 * Adds a MenuItem to a container.
 * @param {!MenuItem} menuItem
 * @param {!string} containerID
 * @param {!Document} document
 * @return {void}
 */
var addItem = function addItem(menuItem, containerID, document) {
  document.getElementById(containerID).appendChild(documentFragmentForMenuItem(menuItem, document));
};

/**
 * Conditionally adds a MenuItem to a container.
 * @param {!string} title
 * @param {!string} subtitle
 * @param {!MenuItemType} itemType
 * @param {!string} containerID
 * @param {FooterMenuItemClickCallback} clickHandler
 * @param {!Document} document
 * @return {void}
 */
var maybeAddItem = function maybeAddItem(title, subtitle, itemType, containerID, clickHandler, document) {
  var item = new MenuItem(title, subtitle, itemType, clickHandler);

  // Items are not added if they have a payload extractor which fails to extract anything.
  var extractor = item.payloadExtractor();
  if (extractor) {
    item.payload = extractor(document);
    if (item.payload.length === 0) {
      return;
    }
  }

  addItem(item, containerID, document);
};

/**
 * Sets heading element string.
 * @param {!string} headingString
 * @param {!string} headingID
 * @param {!Document} document
 * @return {void}
 */
var setHeading = function setHeading(headingString, headingID, document) {
  var headingElement = document.getElementById(headingID);
  headingElement.innerText = headingString;
  headingElement.title = headingString;
};

var FooterMenu = {
  MenuItemType: MenuItemType, // todo: rename to just ItemType?
  setHeading: setHeading,
  maybeAddItem: maybeAddItem
};

/**
 * @typedef {function} SaveButtonClickHandler
 * @param {!string} title
 * @return {void}
 */

/**
 * @typedef {function} TitlesShownHandler
 * @param {!Array.<string>} titles
 * @return {void}
 */

/**
 * Display fetched read more pages.
 * @typedef {function} ShowReadMorePagesHandler
 * @param {!Array.<object>} pages
 * @param {!string} containerID
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!TitlesShownHandler} titlesShownHandler
 * @param {!Document} document
 * @return {void}
 */

var SAVE_BUTTON_ID_PREFIX = 'pagelib_footer_read_more_save_';

/**
 * Removes parenthetical enclosures from string.
 * @param {!string} string
 * @param {!string} opener
 * @param {!string} closer
 * @return {!string}
 */
var safelyRemoveEnclosures = function safelyRemoveEnclosures(string, opener, closer) {
  var enclosureRegex = new RegExp('\\s?[' + opener + '][^' + opener + closer + ']+[' + closer + ']', 'g');
  var counter = 0;
  var safeMaxTries = 30;
  var stringToClean = string;
  var previousString = '';
  do {
    previousString = stringToClean;
    stringToClean = stringToClean.replace(enclosureRegex, '');
    counter++;
  } while (previousString !== stringToClean && counter < safeMaxTries);
  return stringToClean;
};

/**
 * Removes '(...)' and '/.../' parenthetical enclosures from string.
 * @param {!string} string
 * @return {!string}
 */
var cleanExtract = function cleanExtract(string) {
  var stringToClean = string;
  stringToClean = safelyRemoveEnclosures(stringToClean, '(', ')');
  stringToClean = safelyRemoveEnclosures(stringToClean, '/', '/');
  return stringToClean;
};

/**
 * Read more page model.
 */

var ReadMorePage =
/**
 * ReadMorePage constructor.
 * @param {!string} title
 * @param {?string} thumbnail
 * @param {?object} terms
 * @param {?string} extract
 * @return {void}
 */
function ReadMorePage(title, thumbnail, terms, extract) {
  classCallCheck(this, ReadMorePage);

  this.title = title;
  this.thumbnail = thumbnail;
  this.terms = terms;
  this.extract = extract;
};

/**
 * Makes document fragment for a read more page.
 * @param {!ReadMorePage} readMorePage
 * @param {!number} index
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!Document} document
 * @return {!DocumentFragment}
 */


var documentFragmentForReadMorePage = function documentFragmentForReadMorePage(readMorePage, index, saveButtonClickHandler, document) {
  var outerAnchorContainer = document.createElement('a');
  outerAnchorContainer.id = index;
  outerAnchorContainer.className = 'pagelib_footer_readmore_page';

  var hasImage = readMorePage.thumbnail && readMorePage.thumbnail.source;
  if (hasImage) {
    var image = document.createElement('div');
    image.style.backgroundImage = 'url(' + readMorePage.thumbnail.source + ')';
    image.classList.add('pagelib_footer_readmore_page_image');
    outerAnchorContainer.appendChild(image);
  }

  var innerDivContainer = document.createElement('div');
  innerDivContainer.classList.add('pagelib_footer_readmore_page_container');
  outerAnchorContainer.appendChild(innerDivContainer);
  outerAnchorContainer.href = '/wiki/' + encodeURI(readMorePage.title);

  if (readMorePage.title) {
    var title = document.createElement('div');
    title.id = index;
    title.className = 'pagelib_footer_readmore_page_title';
    var displayTitle = readMorePage.title.replace(/_/g, ' ');
    title.innerHTML = displayTitle;
    outerAnchorContainer.title = displayTitle;
    innerDivContainer.appendChild(title);
  }

  var description = void 0;
  if (readMorePage.terms) {
    description = readMorePage.terms.description[0];
  }
  if ((!description || description.length < 10) && readMorePage.extract) {
    description = cleanExtract(readMorePage.extract);
  }
  if (description) {
    var descriptionEl = document.createElement('div');
    descriptionEl.id = index;
    descriptionEl.className = 'pagelib_footer_readmore_page_description';
    descriptionEl.innerHTML = description;
    innerDivContainer.appendChild(descriptionEl);
  }

  var saveButton = document.createElement('div');
  saveButton.id = '' + SAVE_BUTTON_ID_PREFIX + encodeURI(readMorePage.title);
  saveButton.className = 'pagelib_footer_readmore_page_save';
  saveButton.addEventListener('click', function (event) {
    event.stopPropagation();
    event.preventDefault();
    saveButtonClickHandler(readMorePage.title);
  });
  innerDivContainer.appendChild(saveButton);

  return document.createDocumentFragment().appendChild(outerAnchorContainer);
};

// eslint-disable-next-line valid-jsdoc
/**
 * @type {ShowReadMorePagesHandler}
 */
var showReadMorePages = function showReadMorePages(pages, containerID, saveButtonClickHandler, titlesShownHandler, document) {
  var shownTitles = [];
  var container = document.getElementById(containerID);
  pages.forEach(function (page, index) {
    var title = page.title.replace(/ /g, '_');
    shownTitles.push(title);
    var pageModel = new ReadMorePage(title, page.thumbnail, page.terms, page.extract);
    var pageFragment = documentFragmentForReadMorePage(pageModel, index, saveButtonClickHandler, document);
    container.appendChild(pageFragment);
  });
  titlesShownHandler(shownTitles);
};

/**
 * Makes 'Read more' query parameters object for a title.
 * @param {!string} title
 * @param {!number} count
 * @return {!object}
 */
var queryParameters = function queryParameters(title, count) {
  return {
    action: 'query',
    format: 'json',
    formatversion: 2,
    prop: 'extracts|pageimages|pageterms',

    // https://www.mediawiki.org/wiki/API:Search
    // https://www.mediawiki.org/wiki/Help:CirrusSearch
    generator: 'search',
    gsrlimit: count, // Limit search results by count.
    gsrprop: 'redirecttitle', // Include a a parsed snippet of the redirect title property.
    gsrsearch: 'morelike:' + title, // Weight search with the title.
    gsrwhat: 'text', // Search the text then titles of pages.

    // https://www.mediawiki.org/wiki/Extension:TextExtracts
    exchars: 256, // Limit number of characters returned.
    exintro: '', // Only content before the first section.
    exlimit: count, // Limit extract results by count.
    explaintext: '', // Strip HTML.

    // https://www.mediawiki.org/wiki/Extension:PageImages
    pilicense: 'any', // Include non-free images.
    pilimit: count, // Limit thumbnail results by count.
    piprop: 'thumbnail', // Include URL and dimensions of thumbnail.
    pithumbsize: 120, // Limit thumbnail dimensions.

    // https://en.wikipedia.org/w/api.php?action=help&modules=query%2Bpageterms
    wbptterms: 'description'
  };
};

/**
 * Converts query parameter object to string.
 * @param {!object} parameters
 * @return {!string}
 */
var stringFromQueryParameters = function stringFromQueryParameters(parameters) {
  return Object.keys(parameters).map(function (key) {
    return encodeURIComponent(key) + '=' + encodeURIComponent(parameters[key]);
  }).join('&');
};

/**
 * URL for retrieving 'Read more' pages for a given title.
 * Leave 'baseURL' null if you don't need to deal with proxying.
 * @param {!string} title
 * @param {!number} count Number of `Read more` items to fetch for this title
 * @param {?string} baseURL
 * @return {!sring}
 */
var readMoreQueryURL = function readMoreQueryURL(title, count, baseURL) {
  return (baseURL || '') + '/w/api.php?' + stringFromQueryParameters(queryParameters(title, count));
};

/**
 * Fetch error handler.
 * @param {!string} statusText
 * @return {void}
 */
var fetchErrorHandler = function fetchErrorHandler(statusText) {
  // TODO: figure out if we want to hide the 'Read more' header in cases when fetch fails.
  console.log('statusText = ' + statusText); // eslint-disable-line no-console
};

/**
 * Fetches 'Read more' pages.
 * @param {!string} title
 * @param {!number} count
 * @param {!string} containerID
 * @param {?string} baseURL
 * @param {!ShowReadMorePagesHandler} showReadMorePagesHandler
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!TitlesShownHandler} titlesShownHandler
 * @param {!Document} document
 * @return {void}
 */
var fetchReadMore = function fetchReadMore(title, count, containerID, baseURL, showReadMorePagesHandler, saveButtonClickHandler, titlesShownHandler, document) {
  var xhr = new XMLHttpRequest(); // eslint-disable-line no-undef
  xhr.open('GET', readMoreQueryURL(title, count, baseURL), true);
  xhr.onload = function () {
    if (xhr.readyState === XMLHttpRequest.DONE) {
      // eslint-disable-line no-undef
      if (xhr.status === 200) {
        showReadMorePagesHandler(JSON.parse(xhr.responseText).query.pages, containerID, saveButtonClickHandler, titlesShownHandler, document);
      } else {
        fetchErrorHandler(xhr.statusText);
      }
    }
  };
  xhr.onerror = function () {
    return fetchErrorHandler(xhr.statusText);
  };
  try {
    xhr.send();
  } catch (error) {
    fetchErrorHandler(error.toString());
  }
};

/**
 * Updates save button bookmark icon for saved state.
 * @param {!HTMLDivElement} button
 * @param {!boolean} isSaved
 * @return {void}
 */
var updateSaveButtonBookmarkIcon = function updateSaveButtonBookmarkIcon(button, isSaved) {
  var unfilledClass = 'pagelib_footer_readmore_bookmark_unfilled';
  var filledClass = 'pagelib_footer_readmore_bookmark_filled';
  button.classList.remove(filledClass, unfilledClass);
  button.classList.add(isSaved ? filledClass : unfilledClass);
};

/**
 * Updates save button text and bookmark icon for saved state.
 * @param {!string} title
 * @param {!string} text
 * @param {!boolean} isSaved
 * @param {!Document} document
 * @return {void}
*/
var updateSaveButtonForTitle = function updateSaveButtonForTitle(title, text, isSaved, document) {
  var saveButton = document.getElementById('' + SAVE_BUTTON_ID_PREFIX + title);
  saveButton.innerText = text;
  saveButton.title = text;
  updateSaveButtonBookmarkIcon(saveButton, isSaved);
};

/**
 * Adds 'Read more' for 'title' to 'containerID' element.
 * Leave 'baseURL' null if you don't need to deal with proxying.
 * @param {!string} title
 * @param {!number} count
 * @param {!string} containerID
 * @param {?string} baseURL
 * @param {!SaveButtonClickHandler} saveButtonClickHandler
 * @param {!TitlesShownHandler} titlesShownHandler
 * @param {!Document} document
 * @return {void}
 */
var add$1 = function add(title, count, containerID, baseURL, saveButtonClickHandler, titlesShownHandler, document) {
  fetchReadMore(title, count, containerID, baseURL, showReadMorePages, saveButtonClickHandler, titlesShownHandler, document);
};

/**
 * Sets heading element string.
 * @param {!string} headingString
 * @param {!string} headingID
 * @param {!Document} document
 * @return {void}
 */
var setHeading$1 = function setHeading(headingString, headingID, document) {
  var headingElement = document.getElementById(headingID);
  headingElement.innerText = headingString;
  headingElement.title = headingString;
};

var FooterReadMore = {
  add: add$1,
  setHeading: setHeading$1,
  updateSaveButtonForTitle: updateSaveButtonForTitle,
  test: {
    cleanExtract: cleanExtract,
    safelyRemoveEnclosures: safelyRemoveEnclosures
  }
};

/** Function rate limiter. */
var Throttle = function () {
  createClass(Throttle, null, [{
    key: "wrap",

    /**
     * Wraps a function in a Throttle.
     * @param {!Window} window
     * @param {!number} period The nonnegative minimum number of milliseconds between function
     *                         invocations.
     * @param {!function} funktion The function to invoke when not throttled.
     * @return {!function} A function wrapped in a Throttle.
     */
    value: function wrap(window, period, funktion) {
      var throttle = new Throttle(window, period, funktion);
      var throttled = function Throttled() {
        return throttle.queue(this, arguments);
      };
      throttled.result = function () {
        return throttle.result;
      };
      throttled.pending = function () {
        return throttle.pending();
      };
      throttled.delay = function () {
        return throttle.delay();
      };
      throttled.cancel = function () {
        return throttle.cancel();
      };
      throttled.reset = function () {
        return throttle.reset();
      };
      return throttled;
    }

    /**
     * @param {!Window} window
     * @param {!number} period The nonnegative minimum number of milliseconds between function
     *                         invocations.
     * @param {!function} funktion The function to invoke when not throttled.
     */

  }]);

  function Throttle(window, period, funktion) {
    classCallCheck(this, Throttle);

    this._window = window;
    this._period = period;
    this._function = funktion;

    // The upcoming invocation's context and arguments.
    this._context = undefined;
    this._arguments = undefined;

    // The previous invocation's result, timeout identifier, and last run timestamp.
    this._result = undefined;
    this._timeout = 0;
    this._timestamp = 0;
  }

  /**
   * The return value of the initial run is always undefined. The return value of subsequent runs is
   * always a previous result. The context and args used by a future invocation are always the most
   * recently supplied. Invocations, even if immediately eligible, are dispatched.
   * @param {?any} context
   * @param {?any} args The arguments passed to the underlying function.
   * @return {?any} The cached return value of the underlying function.
   */


  createClass(Throttle, [{
    key: "queue",
    value: function queue(context, args) {
      var _this = this;

      // Always update the this and arguments to the latest supplied.
      this._context = context;
      this._arguments = args;

      if (!this.pending()) {
        // Queue a new invocation.
        this._timeout = this._window.setTimeout(function () {
          _this._timeout = 0;
          _this._timestamp = Date.now();
          _this._result = _this._function.apply(_this._context, _this._arguments);
        }, this.delay());
      }

      // Always return the previous result.
      return this.result;
    }

    /** @return {?any} The cached return value of the underlying function. */

  }, {
    key: "pending",


    /** @return {!boolean} true if an invocation is queued. */
    value: function pending() {
      return Boolean(this._timeout);
    }

    /**
     * @return {!number} The nonnegative number of milliseconds until an invocation is eligible to
     *                   run.
     */

  }, {
    key: "delay",
    value: function delay() {
      if (!this._timestamp) {
        return 0;
      }
      return Math.max(0, this._period - (Date.now() - this._timestamp));
    }

    /**
     * Clears any pending invocation but doesn't clear time last invoked or prior result.
     * @return {void}
     */

  }, {
    key: "cancel",
    value: function cancel() {
      if (this._timeout) {
        this._window.clearTimeout(this._timeout);
      }
      this._timeout = 0;
    }

    /**
     * Clears any pending invocation, time last invoked, and prior result.
     * @return {void}
     */

  }, {
    key: "reset",
    value: function reset() {
      this.cancel();
      this._result = undefined;
      this._timestamp = 0;
    }
  }, {
    key: "result",
    get: function get$$1() {
      return this._result;
    }
  }]);
  return Throttle;
}();

var RESIZE_EVENT_TYPE = 'resize';
var RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS = 100;

var ID_CONTAINER = 'pagelib_footer_container';
var ID_LEGAL_CONTAINER = 'pagelib_footer_container_legal';

var ID_READ_MORE_CONTAINER = 'pagelib_footer_container_readmore_pages';
var ID_READ_MORE_HEADER = 'pagelib_footer_container_readmore_heading';

/** */

var _class = function () {
  /** */
  function _class() {
    classCallCheck(this, _class);

    this._resizeListener = undefined;
  }

  /**
   * @param {!Window} window
   * @param {!Element} container
   * @param {!string} baseURL
   * @param {!string} title
   * @param {!string} readMoreHeader
   * @param {!number} readMoreLimit
   * @param {!string} license
   * @param {!string} licenseSubstitutionString
   * @param {!FooterLegalClickCallback} licenseLinkClickHandler
   * @param {!string} viewInBrowserString
   * @param {!FooterBrowserClickCallback} browserLinkClickHandler
   * @param {!TitlesShownHandler} titlesShownHandler
   * @param {!SaveButtonClickHandler} saveButtonClickHandler
   * @return {void}
   */


  createClass(_class, [{
    key: 'add',
    value: function add(window, container, baseURL, title, readMoreHeader, readMoreLimit, license, licenseSubstitutionString, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler, titlesShownHandler, saveButtonClickHandler) {
      this.remove(window);
      container.appendChild(FooterContainer.containerFragment(window.document));

      FooterLegal.add(window.document, license, licenseSubstitutionString, ID_LEGAL_CONTAINER, licenseLinkClickHandler, viewInBrowserString, browserLinkClickHandler);

      FooterReadMore.setHeading(readMoreHeader, ID_READ_MORE_HEADER, window.document);
      FooterReadMore.add(title, readMoreLimit, ID_READ_MORE_CONTAINER, baseURL, saveButtonClickHandler, function (titles) {
        FooterContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window);
        titlesShownHandler(titles);
      }, window.document);

      this._resizeListener = Throttle.wrap(window, RESIZE_LISTENER_THROTTLE_PERIOD_MILLISECONDS, function () {
        return FooterContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window);
      });
      window.addEventListener(RESIZE_EVENT_TYPE, this._resizeListener);
    }

    /**
     * @param {!Window} window
     * @return {void}
     */

  }, {
    key: 'remove',
    value: function remove(window) {
      if (this._resizeListener) {
        window.removeEventListener(RESIZE_EVENT_TYPE, this._resizeListener);
        this._resizeListener.cancel();
        this._resizeListener = undefined;
      }

      var footer = window.document.getElementById(ID_CONTAINER);
      if (footer) {
        // todo: support recycling.
        footer.parentNode.removeChild(footer);
      }
    }
  }]);
  return _class;
}();

// CSS classes used to identify and present lazily loaded images. Placeholders are members of
// PLACEHOLDER_CLASS and one state class: pending, loading, or error. Images are members of either
// loading or loaded state classes. Class names should match those in LazyLoadTransform.css.
var PLACEHOLDER_CLASS = 'pagelib_lazy_load_placeholder';
var PLACEHOLDER_PENDING_CLASS = 'pagelib_lazy_load_placeholder_pending'; // Download pending.
var PLACEHOLDER_LOADING_CLASS = 'pagelib_lazy_load_placeholder_loading'; // Download started.
var PLACEHOLDER_ERROR_CLASS = 'pagelib_lazy_load_placeholder_error'; // Download failure.
var IMAGE_LOADING_CLASS = 'pagelib_lazy_load_image_loading'; // Download started.
var IMAGE_LOADED_CLASS = 'pagelib_lazy_load_image_loaded'; // Download completed.

// Attributes copied from images to placeholders via data-* attributes for later restoration. The
// image's classes and dimensions are also set on the placeholder.
var COPY_ATTRIBUTES = ['class', 'style', 'src', 'srcset', 'width', 'height', 'alt'];

// Small images, especially icons, are quickly downloaded and may appear in many places. Lazily
// loading these images degrades the experience with little gain. Always eagerly load these images.
// Example: flags in the medal count for the "1896 Summer Olympics medal table."
// https://en.m.wikipedia.org/wiki/1896_Summer_Olympics_medal_table?oldid=773498394#Medal_count
var UNIT_TO_MINIMUM_LAZY_LOAD_SIZE = {
  px: 50, // https://phabricator.wikimedia.org/diffusion/EMFR/browse/master/includes/MobileFormatter.php;c89f371ea9e789d7e1a827ddfec7c8028a549c12$22
  ex: 10, // ''
  em: 5 // 1ex ≈ .5em; https://developer.mozilla.org/en-US/docs/Web/CSS/length#Units
};

/**
 * Replace an image with a placeholder.
 * @param {!Document} document
 * @param {!HTMLImageElement} image The image to be replaced.
 * @return {!HTMLSpanElement} The placeholder replacing image.
 */
var convertImageToPlaceholder = function convertImageToPlaceholder(document, image) {
  // There are a number of possible implementations for placeholders including:
  //
  // - [MobileFrontend] Replace the original image with a span and replace the span with a new
  //   downloaded image.
  //   This option has a good fade-in but has some CSS concerns for the placeholder, particularly
  //   `max-width`, and causes significant reflows when used with image widening.
  //
  // - [Previous] Replace the original image with a span and append a new downloaded image to the
  //   span.
  //   This option has the best cross-fading and extensibility but makes duplicating all the CSS
  //   rules for the appended image impractical.
  //
  // - [Previous] Replace the original image's source with a transparent image and update the source
  //   from a new downloaded image.
  //   This option has a good fade-in and minimal CSS concerns for the placeholder and image but
  //   causes significant reflows when used with image widening.
  //
  // - [Current] Replace the original image with a couple spans and replace the spans with a new
  //   downloaded image.
  //   This option is about the same as MobileFrontend but supports image widening without reflows.

  // Create the root placeholder.
  var placeholder = document.createElement('span');

  // Copy the image's classes and append the placeholder and current state (pending) classes.
  if (image.hasAttribute('class')) {
    placeholder.setAttribute('class', image.getAttribute('class'));
  }
  placeholder.classList.add(PLACEHOLDER_CLASS);
  placeholder.classList.add(PLACEHOLDER_PENDING_CLASS);

  // Match the image's width, if specified. If image widening is used, this width will be overridden
  // by !important priority.
  var geometry = ElementGeometry.from(image);
  if (geometry.width) {
    placeholder.style.setProperty('width', '' + geometry.width);
  }

  // Save the image's attributes to data-* attributes for later restoration.
  elementUtilities.copyAttributesToDataAttributes(image, placeholder, COPY_ATTRIBUTES);

  // Create a spacer and match the aspect ratio of the original image, if determinable. If image
  // widening is used, this spacer will scale with the width proportionally.
  var spacing = document.createElement('span');
  if (geometry.width && geometry.height) {
    // Assume units are identical.
    var ratio = geometry.heightValue / geometry.widthValue;
    spacing.style.setProperty('padding-top', ratio * 100 + '%');
  }

  // Append the spacer to the placeholder and replace the image with the placeholder.
  placeholder.appendChild(spacing);
  image.parentNode.replaceChild(placeholder, image);

  return placeholder;
};

/**
 * @param {!HTMLImageElement} image The image to be considered.
 * @return {!boolean} true if image download can be deferred, false if image should be eagerly
 *                    loaded.
 */
var isLazyLoadable = function isLazyLoadable(image) {
  var geometry = ElementGeometry.from(image);
  if (!geometry.width || !geometry.height) {
    return true;
  }
  return geometry.widthValue >= UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.widthUnit] && geometry.heightValue >= UNIT_TO_MINIMUM_LAZY_LOAD_SIZE[geometry.heightUnit];
};

/**
 * @param {!Element} element
 * @return {!Array.<HTMLImageElement>} Convertible images descendent from but not including element.
 */
var queryLazyLoadableImages = function queryLazyLoadableImages(element) {
  return Polyfill.querySelectorAll(element, 'img').filter(function (image) {
    return isLazyLoadable(image);
  });
};

/**
 * Convert images with placeholders. The transformation is inverted by calling loadImage().
 * @param {!Document} document
 * @param {!Array.<HTMLImageElement>} images The images to lazily load.
 * @return {!Array.<HTMLSpanElement>} The placeholders replacing images.
 */
var convertImagesToPlaceholders = function convertImagesToPlaceholders(document, images) {
  return images.map(function (image) {
    return convertImageToPlaceholder(document, image);
  });
};

/**
 * Start downloading image resources associated with a given placeholder and replace the placeholder
 * with a new image element when the download is complete.
 * @param {!Document} document
 * @param {!HTMLSpanElement} placeholder
 * @return {!HTMLImageElement} A new image element.
 */
var loadPlaceholder = function loadPlaceholder(document, placeholder) {
  placeholder.classList.add(PLACEHOLDER_LOADING_CLASS);
  placeholder.classList.remove(PLACEHOLDER_PENDING_CLASS);

  var image = document.createElement('img');

  var retryListener = function retryListener(event) {
    // eslint-disable-line require-jsdoc
    image.setAttribute('src', image.getAttribute('src'));
    event.stopPropagation();
    event.preventDefault();
  };

  // Add the download listener prior to setting the src attribute to avoid missing the load event.
  image.addEventListener('load', function () {
    placeholder.removeEventListener('click', retryListener);
    placeholder.parentNode.replaceChild(image, placeholder);
    image.classList.add(IMAGE_LOADED_CLASS);
    image.classList.remove(IMAGE_LOADING_CLASS);
  }, { once: true });

  image.addEventListener('error', function () {
    placeholder.classList.add(PLACEHOLDER_ERROR_CLASS);
    placeholder.classList.remove(PLACEHOLDER_LOADING_CLASS);
    placeholder.addEventListener('click', retryListener);
  }, { once: true });

  // Set src and other attributes, triggering a download.
  elementUtilities.copyDataAttributesToAttributes(placeholder, image, COPY_ATTRIBUTES);

  // Append to the class list after copying over any preexisting classes.
  image.classList.add(IMAGE_LOADING_CLASS);

  return image;
};

var LazyLoadTransform = {
  queryLazyLoadableImages: queryLazyLoadableImages,
  convertImagesToPlaceholders: convertImagesToPlaceholders,
  loadPlaceholder: loadPlaceholder
};

var EVENT_TYPES = ['scroll', 'resize', CollapseTable.SECTION_TOGGLED_EVENT_TYPE];
var THROTTLE_PERIOD_MILLISECONDS = 100;

/**
 * This class subscribes to key page events, applying lazy load transforms or inversions as
 * applicable. It has external dependencies on the section-toggled custom event and the following
 * standard browser events: resize, scroll.
 */

var _class$1 = function () {
  /**
   * @param {!Window} window
   * @param {!number} loadDistanceMultiplier Images within this multiple of the screen height are
   *                                         loaded in either direction.
   */
  function _class(window, loadDistanceMultiplier) {
    var _this = this;

    classCallCheck(this, _class);

    this._window = window;
    this._loadDistanceMultiplier = loadDistanceMultiplier;

    this._placeholders = [];
    this._registered = false;
    this._throttledLoadPlaceholders = Throttle.wrap(window, THROTTLE_PERIOD_MILLISECONDS, function () {
      return _this._loadPlaceholders();
    });
  }

  /**
   * Convert images with placeholders. Calling this function may register this instance to listen to
   * page events.
   * @param {!Element} element
   * @return {void}
   */


  createClass(_class, [{
    key: 'convertImagesToPlaceholders',
    value: function convertImagesToPlaceholders(element) {
      var images = LazyLoadTransform.queryLazyLoadableImages(element);
      var placeholders = LazyLoadTransform.convertImagesToPlaceholders(this._window.document, images);
      this._placeholders = this._placeholders.concat(placeholders);
      this._register();
    }

    /**
     * Manually trigger a load images check. Calling this function may deregister this instance from
     * listening to page events.
     * @return {void}
     */

  }, {
    key: 'loadPlaceholders',
    value: function loadPlaceholders() {
      this._throttledLoadPlaceholders();
    }

    /**
     * This method may be safely called even when already unregistered. This function clears the
     * record of placeholders.
     * @return {void}
     */

  }, {
    key: 'deregister',
    value: function deregister() {
      var _this2 = this;

      if (!this._registered) {
        return;
      }

      EVENT_TYPES.forEach(function (eventType) {
        return _this2._window.removeEventListener(eventType, _this2._throttledLoadPlaceholders);
      });
      this._throttledLoadPlaceholders.reset();

      this._placeholders = [];
      this._registered = false;
    }

    /**
     * This method may be safely called even when already registered.
     * @return {void}
     */

  }, {
    key: '_register',
    value: function _register() {
      var _this3 = this;

      if (this._registered || !this._placeholders.length) {
        return;
      }
      this._registered = true;

      EVENT_TYPES.forEach(function (eventType) {
        return _this3._window.addEventListener(eventType, _this3._throttledLoadPlaceholders);
      });
    }

    /** @return {void} */

  }, {
    key: '_loadPlaceholders',
    value: function _loadPlaceholders() {
      var _this4 = this;

      this._placeholders = this._placeholders.filter(function (placeholder) {
        var pending = true;
        if (_this4._isPlaceholderEligibleToLoad(placeholder)) {
          LazyLoadTransform.loadPlaceholder(_this4._window.document, placeholder);
          pending = false;
        }
        return pending;
      });

      if (this._placeholders.length === 0) {
        this.deregister();
      }
    }

    /**
     * @param {!HTMLSpanElement} placeholder
     * @return {!boolean}
     */

  }, {
    key: '_isPlaceholderEligibleToLoad',
    value: function _isPlaceholderEligibleToLoad(placeholder) {
      return elementUtilities.isVisible(placeholder) && this._isPlaceholderWithinLoadDistance(placeholder);
    }

    /**
     * @param {!HTMLSpanElement} placeholder
     * @return {!boolean}
     */

  }, {
    key: '_isPlaceholderWithinLoadDistance',
    value: function _isPlaceholderWithinLoadDistance(placeholder) {
      var bounds = placeholder.getBoundingClientRect();
      var range = this._window.innerHeight * this._loadDistanceMultiplier;
      return !(bounds.top > range || bounds.bottom < -range);
    }
  }]);
  return _class;
}();

var CLASS$2 = { ANDROID: 'pagelib_platform_android', IOS: 'pagelib_platform_ios' };

// Regular expressions from https://phabricator.wikimedia.org/diffusion/EMFR/browse/master/resources/mobile.startup/browser.js;c89f371ea9e789d7e1a827ddfec7c8028a549c12.
/**
 * @param {!Window} window
 * @return {!boolean} true if the user agent is Android, false otherwise.
 */
var isAndroid = function isAndroid(window) {
  return (/android/i.test(window.navigator.userAgent)
  );
};

/**
 * @param {!Window} window
 * @return {!boolean} true if the user agent is iOS, false otherwise.
 */
var isIOs = function isIOs(window) {
  return (/ipad|iphone|ipod/i.test(window.navigator.userAgent)
  );
};

/**
 * @param {!Window} window
 * @return {void}
 */
var classify = function classify(window) {
  var html = window.document.querySelector('html');
  if (isAndroid(window)) {
    html.classList.add(CLASS$2.ANDROID);
  }
  if (isIOs(window)) {
    html.classList.add(CLASS$2.IOS);
  }
};

var PlatformTransform = {
  CLASS: CLASS$2,
  classify: classify
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
 * @return {!Array.<HTMLAnchorElement>} Array of zero or more red link anchors.
 */
var redLinkAnchorsInContent = function redLinkAnchorsInContent(content) {
  return Polyfill.querySelectorAll(content, 'a.new');
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
 * To widen an image element a css class called 'pagelib_widen_image_override' is applied to the
 * image element, however, ancestors of the image element can prevent the widening from taking
 * effect. This method makes minimal adjustments to ancestors of the image element being widened so
 * the image widening can take effect.
 * @param  {!HTMLElement} el Element whose ancestors will be widened
 * @return {void}
 */
var widenAncestors = function widenAncestors(el) {
  for (var parentElement = el.parentElement; parentElement && !parentElement.classList.contains('content_block'); parentElement = parentElement.parentElement) {
    if (parentElement.style.width) {
      parentElement.style.width = '100%';
    }
    if (parentElement.style.height) {
      parentElement.style.height = 'auto';
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
 * Widens the image.
 * @param  {!HTMLElement} image   The image in question
 * @return {void}
 */
var widenImage = function widenImage(image) {
  widenAncestors(image);
  image.classList.add('pagelib_widen_image_override');
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

/* eslint-disable sort-imports */

// We want the theme transform to be first. This is because the theme transform CSS has to use
// some '!important' CSS modifiers to reliably set themes on elements which may contain inline
// styles. Moving it to the top of the file is necessary so other transforms can override
// these '!important' themes transform CSS bits if needed. Note - if other transforms have trouble
// overriding things changed by theme transform remember to match or exceed the selector specificity
// used by the theme transform for whatever it is you are trying to override.
var pagelib$1 = {
  // todo: rename CollapseTableTransform.
  CollapseTable: CollapseTable,
  CompatibilityTransform: CompatibilityTransform,
  DimImagesTransform: DimImagesTransform,
  EditTransform: EditTransform,
  // todo: rename Footer.ContainerTransform, Footer.LegalTransform, Footer.MenuTransform,
  //       Footer.ReadMoreTransform.
  FooterContainer: FooterContainer,
  FooterLegal: FooterLegal,
  FooterMenu: FooterMenu,
  FooterReadMore: FooterReadMore,
  FooterTransformer: _class,
  LazyLoadTransform: LazyLoadTransform,
  LazyLoadTransformer: _class$1,
  PlatformTransform: PlatformTransform,
  // todo: rename RedLinkTransform.
  RedLinks: RedLinks,
  ThemeTransform: ThemeTransform,
  // todo: rename WidenImageTransform.
  WidenImage: WidenImage,
  test: {
    ElementGeometry: ElementGeometry,
    ElementUtilities: elementUtilities,
    Polyfill: Polyfill,
    Throttle: Throttle
  }
};

// This file exists for CSS packaging only. It imports the override CSS
// JavaScript index file, which also exists only for packaging, as well as the
// real JavaScript, transform/index, it simply re-exports.

return pagelib$1;

})));


},{}]},{},[1,2,3,4,5,6,7,8,9,10]);
