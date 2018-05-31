(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
const wmf = {}

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
},{"./js/elementLocation":3,"./js/findInPage":4,"./js/footers":5,"./js/sections":7,"./js/utilities":8,"wikimedia-page-library":10}],2:[function(require,module,exports){
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
  imagePlaceholder: 3,
  reference: 4
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
    } else if (this.target.tagName === 'SPAN' && this.target.parentElement.getAttribute( 'data-data-image-gallery' ) === 'true') {
      return ItemType.imagePlaceholder
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
const sendMessageForClickedItem = item => {
  switch(item.type()) {
  case ItemType.link:
    sendMessageForLinkWithHref(item.href)
    break
  case ItemType.image:
    sendMessageForImageWithTarget(item.target)
    break
  case ItemType.imagePlaceholder:
    sendMessageForImagePlaceholderWithTarget(item.target)
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
const sendMessageForLinkWithHref = href => {
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
const sendMessageForImageWithTarget = target => {
  window.webkit.messageHandlers.imageClicked.postMessage({
    'src': target.getAttribute('src'),
    'width': target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
    'height': target.naturalHeight,
    'data-file-width': target.getAttribute('data-file-width'),
    'data-file-height': target.getAttribute('data-file-height')
  })
}

/**
 * Sends message for a lazy load image placeholder click.
 * @param  {!Element} innerPlaceholderSpan
 * @return {void}
 */
const sendMessageForImagePlaceholderWithTarget = innerPlaceholderSpan => {
  const outerSpan = innerPlaceholderSpan.parentElement
  window.webkit.messageHandlers.imageClicked.postMessage({
    'src': outerSpan.getAttribute('data-src'),
    'width': outerSpan.getAttribute('data-width'),
    'height': outerSpan.getAttribute('data-height'),
    'data-file-width': outerSpan.getAttribute('data-data-file-width'),
    'data-file-height': outerSpan.getAttribute('data-data-file-height')
  })
}

/**
 * Sends message for a reference click.
 * @param  {!Element} target an anchor element
 * @return {void}
 */
const sendMessageForReferenceWithTarget = target => refs.sendNearbyReferences( target )

/**
 * Handler for the click event.
 * @param  {ClickEvent} event the event being handled
 * @return {void}
 */
const handleClickEvent = event => {
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
document.addEventListener('click', event => {
  event.preventDefault()
  handleClickEvent(event)
}, false)
},{"./refs":6,"./utilities":8,"wikimedia-page-library":10}],3:[function(require,module,exports){
//  Used by methods in "UIWebView+ElementLocation.h" category.

const stringEndsWith = (str, suffix) => str.indexOf(suffix, str.length - suffix.length) !== -1

exports.getImageWithSrc = src => document.querySelector(`img[src$="${src}"]`)

exports.getElementRect = element => {
  const rect = element.getBoundingClientRect()
    // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
  return {
    Y: rect.top,
    X: rect.left,
    Width: rect.width,
    Height: rect.height
  }
}

exports.getIndexOfFirstOnScreenElement = (elementPrefix, elementCount) => {
  for (let i = 0; i < elementCount; ++i) {
    const div = document.getElementById(elementPrefix + i)
    if (div === null) {
      continue
    }
    const rect = this.getElementRect(div)
    if (rect.Y >= -1 || rect.Y + rect.Height >= 50) {
      return i
    }
  }
  return -1
}

exports.getElementFromPoint = (x, y) => document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)

exports.isElementTopOnscreen = element => element.getBoundingClientRect().top < 0
},{}],4:[function(require,module,exports){
// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

let FindInPageResultCount = 0
let FindInPageResultMatches = []
let FindInPagePreviousFocusMatchSpanId = null

const recursivelyHighlightSearchTermInTextNodesStartingWithElement = (element, searchTerm) => {
  if (element) {
    if (element.nodeType == 3) {            // Text node
      while (true) {
        const value = element.nodeValue  // Search for searchTerm in text node
        const idx = value.toLowerCase().indexOf(searchTerm)

        if (idx < 0) break

        const span = document.createElement('span')
        let text = document.createTextNode(value.substr(idx, searchTerm.length))
        span.appendChild(text)
        span.setAttribute('class', 'findInPageMatch')

        text = document.createTextNode(value.substr(idx + searchTerm.length))
        element.deleteData(idx, value.length - idx)
        const next = element.nextSibling
        element.parentNode.insertBefore(span, next)
        element.parentNode.insertBefore(text, next)
        element = text
        FindInPageResultCount++
      }
    } else if (element.nodeType == 1) {     // Element node
      if (element.style.display != 'none' && element.nodeName.toLowerCase() != 'select') {
        for (let i = element.childNodes.length - 1; i >= 0; i--) {
          recursivelyHighlightSearchTermInTextNodesStartingWithElement(element.childNodes[i], searchTerm)
        }
      }
    }
  }
}

const recursivelyRemoveSearchTermHighlightsStartingWithElement = element => {
  if (element) {
    if (element.nodeType == 1) {
      if (element.getAttribute('class') == 'findInPageMatch') {
        const text = element.removeChild(element.firstChild)
        element.parentNode.insertBefore(text, element)
        element.parentNode.removeChild(element)
        return true
      }
      let normalize = false
      for (let i = element.childNodes.length - 1; i >= 0; i--) {
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

const deFocusPreviouslyFocusedSpan = () => {
  if(FindInPagePreviousFocusMatchSpanId){
    document.getElementById(FindInPagePreviousFocusMatchSpanId).classList.remove('findInPageMatch_Focus')
    FindInPagePreviousFocusMatchSpanId = null
  }
}

const removeSearchTermHighlights = () => {
  FindInPageResultCount = 0
  FindInPageResultMatches = []
  deFocusPreviouslyFocusedSpan()
  recursivelyRemoveSearchTermHighlightsStartingWithElement(document.body)
}

const findAndHighlightAllMatchesForSearchTerm = searchTerm => {
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
  const orderedMatchElements = document.getElementsByClassName('findInPageMatch')
  FindInPageResultMatches.length = orderedMatchElements.length
  for (let i = 0; i < orderedMatchElements.length; i++) {
    const matchSpanId = 'findInPageMatchID|' + i
    orderedMatchElements[i].setAttribute('id', matchSpanId)
        // For now our results message to native land will be just an array of match span ids.
    FindInPageResultMatches[i] = matchSpanId
  }

  window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches)
}

const useFocusStyleForHighlightedSearchTermWithId = id => {
  deFocusPreviouslyFocusedSpan()
  setTimeout(() => {
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
},{"wikimedia-page-library":10}],6:[function(require,module,exports){
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
},{"./elementLocation":3}],7:[function(require,module,exports){

const requirements = {
  editTransform: require('wikimedia-page-library').EditTransform,
  utilities: require('./utilities'),
  tables: require('wikimedia-page-library').CollapseTable,
  themes: require('wikimedia-page-library').ThemeTransform,
  redLinks: require('wikimedia-page-library').RedLinks,
  leadIntroductionTransform: require('wikimedia-page-library').LeadIntroductionTransform,
  widenImage: require('wikimedia-page-library').WidenImage,
  lazyLoadTransformer: require('wikimedia-page-library').LazyLoadTransformer,
  location: require('./elementLocation')
}

// Documents attached to Window will attempt eager pre-fetching of image element resources as soon
// as image elements appear in DOM of such documents. So for lazy image loading transform to work
// (without the images being eagerly pre-fetched) our section fragments need to be created on a
// document not attached to window - `lazyDocument`. The `live` document's `mainContentDiv` is only
// used when we append our transformed fragments to it. See this Android commit message for details:
// https://github.com/wikimedia/apps-android-wikipedia/commit/620538d961221942e340ca7ac7f429393d1309d6
const lazyDocument = document.implementation.createHTMLDocument()
const lazyImageLoadViewportDistanceMultiplier = 2 // Load images on the current screen up to one ahead.
const lazyImageLoadingTransformer = new requirements.lazyLoadTransformer(window, lazyImageLoadViewportDistanceMultiplier)
const liveDocument = document

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
      const p = lazyDocument.createElement('p')
      p.id = 'entity_description'
      p.innerHTML = this.description
      return p
    }
    return undefined
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

  addAnchorAsIdToHeading(heading) {
    if (this.anchor === undefined || this.anchor.length === 0) {
      return
    }

    // TODO: consider renaming this 'id' to 'anchor' for clarity - would need to update native
    // code as well - used when TOC sections made to jump to sections.
    // If we make this change this method should probably be renamed to 'addAnchorToHeading'.
    heading.id = this.anchor
  }

  leadSectionHeading() {
    const heading = lazyDocument.createElement('h1')
    heading.class = 'section_heading'
    this.addAnchorAsIdToHeading(heading)
    heading.sectionId = this.id
    heading.innerHTML = this.article.displayTitle
    return heading
  }

  nonLeadSectionHeading() {
    // Non-lead section edit pencils are added as part of the heading via `newEditSectionHeader`
    // because it provides a heading correctly aligned with the edit pencil. (Lead section edit
    // pencils are added in `applyTransformationsToFragment` because they need to be added after
    // the `moveLeadIntroductionUp` has finished.)
    const heading = requirements.editTransform.newEditSectionHeader(lazyDocument, this.id, this.level, this.line)
    this.addAnchorAsIdToHeading(heading)
    return heading
  }

  heading() {
    return this.isLeadSection() ? this.leadSectionHeading() : this.nonLeadSectionHeading()
  }

  isLeadSection() {
    return this.id === 0
  }

  isNonMainPageLeadSection() {
    return this.isLeadSection() && !this.article.ismain
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

  description() {
    if(this.isLeadSection()){
      return this.article.descriptionParagraph()
    }
    return undefined
  }

  containerDiv() {
    const container = lazyDocument.createElement('div')
    container.id = `section_heading_and_content_block_${this.id}`

    if(!this.article.ismain){
      container.appendChild(this.heading())

      const description = this.description()
      if(description){
        container.appendChild(description)
      }

      if(this.isLeadSection()){
        const hr = lazyDocument.createElement('hr')
        hr.id = 'content_block_0_hr'
        container.appendChild(hr)
      }
    }

    const block = lazyDocument.createElement('div')
    block.id = `content_block_${this.id}`
    block.class = 'content_block'
    block.innerHTML = this.html()

    container.appendChild(block)

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

// Backfill fragments with `createElement` and `createDocumentFragment` so transforms
// requiring `Document` parameters will also work if passed a `DocumentFragment`.
// Reminder: didn't use 'prototype' because it extends all instances.
const enrichFragment = fragment => {
  fragment.createElement = name => lazyDocument.createElement(name)
  fragment.createDocumentFragment = () => lazyDocument.createDocumentFragment()
  fragment.createTextNode = text => lazyDocument.createTextNode(text)
}

const fragmentForSection = section => {
  const fragment = lazyDocument.createDocumentFragment()
  enrichFragment(fragment)
  const container = section.containerDiv() // do not append this to document. keep unattached to main DOM (ie headless) until transforms have been run on the fragment
  fragment.appendChild(container)
  return fragment
}

const applyTransformationsToFragment = (fragment, article, isLead) => {
  requirements.redLinks.hideRedLinks(fragment)

  if(!article.ismain && isLead){
    requirements.leadIntroductionTransform.moveLeadIntroductionUp(fragment, 'content_block_0')
  }

  const isFilePage = fragment.querySelector('#filetoc') !== null
  const needsLeadEditPencil = !article.ismain && !isFilePage && isLead
  if(needsLeadEditPencil){
    // Add lead section edit pencil before the section html. Lead section edit pencil must be
    // added after `moveLeadIntroductionUp` has finished. (Other edit pencils are constructed
    // in `nonLeadSectionHeading()`.)
    const leadSectionEditButton = requirements.editTransform.newEditSectionButton(fragment, 0)
    leadSectionEditButton.style.float = article.language.isRTL ? 'left': 'right'
    const firstContentBlock = fragment.getElementById('content_block_0')
    firstContentBlock.insertBefore(leadSectionEditButton, firstContentBlock.firstChild)
  }
  fragment.querySelectorAll('a.pagelib_edit_section_link').forEach(anchor => {anchor.href = 'WMFEditPencil'})

  const tableFooterDivClickCallback = container => {
    if(requirements.location.isElementTopOnscreen(container)){
      window.scrollTo( 0, container.offsetTop - 10 )
    }
  }

  // Adds table collapsing header/footers.
  requirements.tables.adjustTables(window, fragment, article.title, article.ismain, this.collapseTablesInitially, this.collapseTablesLocalizedStrings.tableInfoboxTitle, this.collapseTablesLocalizedStrings.tableOtherTitle, this.collapseTablesLocalizedStrings.tableFooterTitle, tableFooterDivClickCallback)

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

  lazyImageLoadingTransformer.convertImagesToPlaceholders(fragment)
  lazyImageLoadingTransformer.loadPlaceholders()
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
  const mainContentDiv = liveDocument.querySelector('div.content')
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
},{"./elementLocation":3,"./utilities":8,"wikimedia-page-library":10}],8:[function(require,module,exports){

// Implementation of https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
const findClosest = (el, selector) => {
  while ((el = el.parentElement) && !el.matches(selector));
  return el
}

const setLanguage = (lang, dir, uidir) => {
  const html = document.querySelector( 'html' )
  html.lang = lang
  html.dir = dir
  html.classList.add( 'content-' + dir )
  html.classList.add( 'ui-' + uidir )
}

const setPageProtected =
  isProtected => document.querySelector( 'html' ).classList[isProtected ? 'add' : 'remove']('page-protected')

const scrollToFragment = fragmentId => {
  location.hash = ''
  location.hash = fragmentId
}

const accessibilityCursorToFragment = fragmentId => {
    /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
  const focus_element = document.getElementById(fragmentId)
  const other_element = document.body
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
},{}],9:[function(require,module,exports){
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
},{"./utilities":8}],10:[function(require,module,exports){
!function(e,t){"object"==typeof exports&&"object"==typeof module?module.exports=t():"function"==typeof define&&define.amd?define([],t):"object"==typeof exports?exports.pagelib=t():e.pagelib=t()}(window,function(){return function(e){var t={};function n(i){if(t[i])return t[i].exports;var a=t[i]={i:i,l:!1,exports:{}};return e[i].call(a.exports,a,a.exports,n),a.l=!0,a.exports}return n.m=e,n.c=t,n.d=function(e,t,i){n.o(e,t)||Object.defineProperty(e,t,{configurable:!1,enumerable:!0,get:i})},n.r=function(e){Object.defineProperty(e,"__esModule",{value:!0})},n.n=function(e){var t=e&&e.__esModule?function(){return e.default}:function(){return e};return n.d(t,"a",t),t},n.o=function(e,t){return Object.prototype.hasOwnProperty.call(e,t)},n.p="",n(n.s=44)}([function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i="undefined"!=typeof window&&window.CustomEvent||function(e){var t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{bubbles:!1,cancelable:!1,detail:void 0},n=document.createEvent("CustomEvent");return n.initCustomEvent(e,t.bubbles,t.cancelable,t.detail),n};t.default={matchesSelector:function(e,t){return e.matches?e.matches(t):e.matchesSelector?e.matchesSelector(t):!!e.webkitMatchesSelector&&e.webkitMatchesSelector(t)},querySelectorAll:function(e,t){return Array.prototype.slice.call(e.querySelectorAll(t))},CustomEvent:i}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,a=n(0),r=(i=a)&&i.__esModule?i:{default:i};var o=function(e,t){var n=void 0;for(n=e.parentElement;n&&!r.default.matchesSelector(n,t);n=n.parentElement);return n};t.default={findClosestAncestor:o,isNestedInTable:function(e){return Boolean(o(e,"table"))},closestInlineStyle:function(e,t){for(var n=e;n;n=n.parentElement)if(n.style[t])return n},isVisible:function(e){return Boolean(e.offsetWidth||e.offsetHeight||e.getClientRects().length)},copyAttributesToDataAttributes:function(e,t,n){n.filter(function(t){return e.hasAttribute(t)}).forEach(function(n){return t.setAttribute("data-"+n,e.getAttribute(n))})},copyDataAttributesToAttributes:function(e,t,n){n.filter(function(t){return e.hasAttribute("data-"+t)}).forEach(function(n){return t.setAttribute(n,e.getAttribute("data-"+n))})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}();var a=function(){function e(t,n,i){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this._window=t,this._period=n,this._function=i,this._context=void 0,this._arguments=void 0,this._result=void 0,this._timeout=0,this._timestamp=0}return i(e,null,[{key:"wrap",value:function(t,n,i){var a=new e(t,n,i),r=function(){return a.queue(this,arguments)};return r.result=function(){return a.result},r.pending=function(){return a.pending()},r.delay=function(){return a.delay()},r.cancel=function(){return a.cancel()},r.reset=function(){return a.reset()},r}}]),i(e,[{key:"queue",value:function(e,t){var n=this;return this._context=e,this._arguments=t,this.pending()||(this._timeout=this._window.setTimeout(function(){n._timeout=0,n._timestamp=Date.now(),n._result=n._function.apply(n._context,n._arguments)},this.delay())),this.result}},{key:"pending",value:function(){return Boolean(this._timeout)}},{key:"delay",value:function(){return this._timestamp?Math.max(0,this._period-(Date.now()-this._timestamp)):0}},{key:"cancel",value:function(){this._timeout&&this._window.clearTimeout(this._timeout),this._timeout=0}},{key:"reset",value:function(){this.cancel(),this._result=void 0,this._timestamp=0}},{key:"result",get:function(){return this._result}}]),e}();t.default=a},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(20);var i=o(n(7)),a=o(n(1)),r=o(n(0));function o(e){return e&&e.__esModule?e:{default:e}}var l=["class","style","src","srcset","width","height","alt","usemap","data-file-width","data-file-height","data-image-gallery"],s={px:50,ex:10,em:5};t.default={queryLazyLoadableImages:function(e){return r.default.querySelectorAll(e,"img").filter(function(e){return function(e){var t=i.default.from(e);return!t.width||!t.height||t.widthValue>=s[t.widthUnit]&&t.heightValue>=s[t.heightUnit]}(e)})},convertImagesToPlaceholders:function(e,t){return t.map(function(t){return function(e,t){var n=e.createElement("span");t.hasAttribute("class")&&n.setAttribute("class",t.getAttribute("class")),n.classList.add("pagelib_lazy_load_placeholder"),n.classList.add("pagelib_lazy_load_placeholder_pending");var r=i.default.from(t);r.width&&n.style.setProperty("width",""+r.width),a.default.copyAttributesToDataAttributes(t,n,l);var o=e.createElement("span");if(r.width&&r.height){var s=r.heightValue/r.widthValue;o.style.setProperty("padding-top",100*s+"%")}return n.appendChild(o),t.parentNode.replaceChild(n,t),n}(e,t)})},loadPlaceholder:function(e,t){t.classList.add("pagelib_lazy_load_placeholder_loading"),t.classList.remove("pagelib_lazy_load_placeholder_pending");var n=e.createElement("img"),i=function(e){n.setAttribute("src",n.getAttribute("src")),e.stopPropagation(),e.preventDefault()};return n.addEventListener("load",function(){t.removeEventListener("click",i),t.parentNode.replaceChild(n,t),n.classList.add("pagelib_lazy_load_image_loaded"),n.classList.remove("pagelib_lazy_load_image_loading")},{once:!0}),n.addEventListener("error",function(){t.classList.add("pagelib_lazy_load_placeholder_error"),t.classList.remove("pagelib_lazy_load_placeholder_loading"),t.addEventListener("click",i)},{once:!0}),a.default.copyDataAttributesToAttributes(t,n,l),n.classList.add("pagelib_lazy_load_image_loading"),n}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(23);var i=function(e,t,n){var i=new RegExp("\\s?["+t+"][^"+t+n+"]+["+n+"]","g"),a=0,r=e,o="";do{o=r,r=r.replace(i,""),a++}while(o!==r&&a<30);return r},a=function(e){var t=e;return t=i(t,"(",")"),t=i(t,"/","/")},r=function e(t,n,i,a,r){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this.title=t,this.displayTitle=n,this.thumbnail=i,this.description=a,this.extract=r},o=function(e,t,n,i,o){var l=[],s=o.getElementById(t);e.forEach(function(e,t){var i=e.title.replace(/ /g,"_");l.push(i);var u=function(e,t,n,i){var r=i.createElement("a");if(r.id=t,r.className="pagelib_footer_readmore_page",e.thumbnail&&e.thumbnail.source){var o=i.createElement("div");o.style.backgroundImage="url("+e.thumbnail.source+")",o.classList.add("pagelib_footer_readmore_page_image"),r.appendChild(o)}var l=i.createElement("div");l.classList.add("pagelib_footer_readmore_page_container"),r.appendChild(l),r.href="/wiki/"+encodeURI(e.title)+"?event_logging_label=read_more";var s=void 0;if(e.displayTitle?s=e.displayTitle:e.title&&(s=e.title),s){var u=i.createElement("div");u.id=t,u.className="pagelib_footer_readmore_page_title",u.innerHTML=s.replace(/_/g," "),r.title=e.title.replace(/_/g," "),l.appendChild(u)}var c=void 0;if(e.description&&(c=e.description),(!c||c.length<10)&&e.extract&&(c=a(e.extract)),c){var d=i.createElement("div");d.id=t,d.className="pagelib_footer_readmore_page_description",d.innerHTML=c,l.appendChild(d)}var f=i.createElement("div");return f.id="pagelib_footer_read_more_save_"+encodeURI(e.title),f.className="pagelib_footer_readmore_page_save",f.addEventListener("click",function(t){t.stopPropagation(),t.preventDefault(),n(e.title)}),l.appendChild(f),i.createDocumentFragment().appendChild(r)}(new r(i,e.pageprops.displaytitle,e.thumbnail,e.description,e.extract),t,n,o);s.appendChild(u)}),i(l)},l=function(e,t,n){return(n||"")+"/w/api.php?"+(i=function(e,t){return{action:"query",format:"json",formatversion:2,prop:"extracts|pageimages|description|pageprops",generator:"search",gsrlimit:t,gsrprop:"redirecttitle",gsrsearch:"morelike:"+e,gsrwhat:"text",exchars:256,exintro:"",exlimit:t,explaintext:"",pilicense:"any",pilimit:t,piprop:"thumbnail",pithumbsize:120}}(e,t),Object.keys(i).map(function(e){return encodeURIComponent(e)+"="+encodeURIComponent(i[e])}).join("&"));var i},s=function(e){console.log("statusText = "+e)};t.default={add:function(e,t,n,i,a,r,u){!function(e,t,n,i,a,r,o,u){var c=new XMLHttpRequest;c.open("GET",l(e,t,i),!0),c.onload=function(){c.readyState===XMLHttpRequest.DONE&&(200===c.status?a(JSON.parse(c.responseText).query.pages,n,r,o,u):s(c.statusText))},c.onerror=function(){return s(c.statusText)};try{c.send()}catch(e){s(e.toString())}}(e,t,n,i,o,a,r,u)},setHeading:function(e,t,n){var i=n.getElementById(t);i.innerText=e,i.title=e},updateSaveButtonForTitle:function(e,t,n,i){var a=i.getElementById("pagelib_footer_read_more_save_"+encodeURI(e));a&&(a.innerText=t,a.title=t,function(e,t){var n="pagelib_footer_readmore_bookmark_unfilled",i="pagelib_footer_readmore_bookmark_filled";e.classList.remove(i,n),e.classList.add(t?i:n)}(a,n))},test:{cleanExtract:a,safelyRemoveEnclosures:i}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(28);t.default={add:function(e,t,n,i,a,r,o){var l=e.querySelector("#"+i),s=t.split("$1");l.innerHTML="<div class='pagelib_footer_legal_contents'>\n    <hr class='pagelib_footer_legal_divider'>\n    <span class='pagelib_footer_legal_license'>\n      "+s[0]+"\n      <a class='pagelib_footer_legal_license_link'>\n        "+n+"\n      </a>\n      "+s[1]+"\n      <br>\n      <div class=\"pagelib_footer_browser\">\n        <a class='pagelib_footer_browser_link'>\n          "+r+"\n        </a>\n      </div>\n    </span>\n  </div>",l.querySelector(".pagelib_footer_legal_license_link").addEventListener("click",function(){a()}),l.querySelector(".pagelib_footer_browser_link").addEventListener("click",function(){o()})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(30);var i,a=n(0),r=(i=a)&&i.__esModule?i:{default:i};t.default={containerFragment:function(e){var t=e.createElement("div"),n=e.createDocumentFragment();return n.appendChild(t),t.innerHTML="<div id='pagelib_footer_container' class='pagelib_footer_container'>\n    <div id='pagelib_footer_container_section_0'>\n      <div id='pagelib_footer_container_menu'>\n        <div id='pagelib_footer_container_menu_heading' class='pagelib_footer_container_heading'>\n        </div>\n        <div id='pagelib_footer_container_menu_items'>\n        </div>\n      </div>\n    </div>\n    <div id='pagelib_footer_container_ensure_can_scroll_to_top'>\n      <div id='pagelib_footer_container_section_1'>\n        <div id='pagelib_footer_container_readmore'>\n          <div\n            id='pagelib_footer_container_readmore_heading' class='pagelib_footer_container_heading'>\n          </div>\n          <div id='pagelib_footer_container_readmore_pages'>\n          </div>\n        </div>\n      </div>\n      <div id='pagelib_footer_container_legal'></div>\n    </div>\n  </div>",n},isContainerAttached:function(e){return Boolean(e.querySelector("#pagelib_footer_container"))},updateBottomPaddingToAllowReadMoreToScrollToTop:function(e){var t=e.document.getElementById("pagelib_footer_container_ensure_can_scroll_to_top"),n=parseInt(t.style.paddingBottom,10)||0,i=t.clientHeight-n,a=Math.max(0,e.innerHeight-i);t.style.paddingBottom=a+"px"},updateLeftAndRightMargin:function(e,t){r.default.querySelectorAll(t,["#pagelib_footer_container_menu_heading","#pagelib_footer_container_readmore","#pagelib_footer_container_legal"].join()).forEach(function(t){t.style.marginLeft=e+"px",t.style.marginRight=e+"px"});var n="rtl"===t.querySelector("html").dir?"right":"left";r.default.querySelectorAll(t,".pagelib_footer_menu_item").forEach(function(t){t.style.backgroundPosition=n+" "+e+"px center",t.style.paddingLeft=e+"px",t.style.paddingRight=e+"px"})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}();function a(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}var r=function(){function e(t,n){a(this,e),this._value=Number(t),this._unit=n||"px"}return i(e,null,[{key:"fromElement",value:function(t,n){return t.style.getPropertyValue(n)&&e.fromStyle(t.style.getPropertyValue(n))||t.hasAttribute(n)&&new e(t.getAttribute(n))||void 0}},{key:"fromStyle",value:function(t){var n=t.match(/(-?\d*\.?\d*)(\D+)?/)||[];return new e(n[1],n[2])}}]),i(e,[{key:"toString",value:function(){return isNaN(this.value)?"":""+this.value+this.unit}},{key:"value",get:function(){return this._value}},{key:"unit",get:function(){return this._unit}}]),e}(),o=function(){function e(t,n){a(this,e),this._width=t,this._height=n}return i(e,null,[{key:"from",value:function(t){return new e(r.fromElement(t,"width"),r.fromElement(t,"height"))}}]),i(e,[{key:"width",get:function(){return this._width}},{key:"widthValue",get:function(){return this._width&&!isNaN(this._width.value)?this._width.value:NaN}},{key:"widthUnit",get:function(){return this._width&&this._width.unit||"px"}},{key:"height",get:function(){return this._height}},{key:"heightValue",get:function(){return this._height&&!isNaN(this._height.value)?this._height.value:NaN}},{key:"heightUnit",get:function(){return this._height&&this._height.unit||"px"}}]),e}();t.default=o},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,a=n(0),r=(i=a)&&i.__esModule?i:{default:i};var o=function(e,t){if(!t)return[];var n=r.default.querySelectorAll(t,"table.ambox:not(.ambox-multiple_issues):not(.ambox-notice)"),i=e.createDocumentFragment();return n.forEach(function(e){return i.appendChild(e.cloneNode(!0))}),r.default.querySelectorAll(i,".hide-when-compact, .collapsed").forEach(function(e){return e.remove()}),r.default.querySelectorAll(i,"td[class*=mbox-text] > *[class*=mbox-text]")};t.default={collectDisambiguationTitles:function(e){return e?r.default.querySelectorAll(e,'div.hatnote a[href]:not([href=""]):not([redlink="1"])').map(function(e){return e.href}):[]},collectDisambiguationHTML:function(e){return e?r.default.querySelectorAll(e,"div.hatnote").map(function(e){return e.innerHTML}):[]},collectPageIssuesHTML:function(e,t){return o(e,t).map(function(e){return e.innerHTML})},collectPageIssuesText:function(e,t){return o(e,t).map(function(e){return e.textContent.trim()})},test:{collectPageIssues:o}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(40);var i=r(n(0)),a=r(n(1));function r(e){return e&&e.__esModule?e:{default:e}}var o=function(e){return e.childNodes&&i.default.querySelectorAll(e,"a").length<3},l=function(e){return e&&e.replace(/[\s0-9]/g,"").length>0},s=function(e){var t=e.match(/\w+/);if(t)return t[0]},u=function(e,t){var n=s(t),i=s(e.textContent);return!(!n||!i)&&n.toLowerCase()===i.toLowerCase()},c=function(e){return 1===e.nodeType||3===e.nodeType},d=function(e){return e.trim().replace(/\s/g," ")},f=function(e){return 1===e.nodeType&&"BR"===e.tagName},_=function(e,t){return t.parentNode.replaceChild(e.createTextNode(" "),t)},p=function(e,t,n){if(!o(t))return null;var a=e.createDocumentFragment();a.appendChild(t.cloneNode(!0));var r=a.querySelector("th");i.default.querySelectorAll(r,".geo, .coordinates, sup.reference, ol, ul").forEach(function(e){return e.remove()});var s=Array.prototype.slice.call(r.childNodes);n&&s.filter(c).filter(function(e){return u(e,n)}).forEach(function(e){return e.remove()}),s.filter(f).forEach(function(t){return _(e,t)});var p=r.textContent;return l(p)?d(p):null},h=function(e,t){var n=e.hasAttribute("scope"),i=t.hasAttribute("scope");return n&&i?0:n?-1:i?1:0},g=function(e,t,n){var a=[],r=i.default.querySelectorAll(t,"th");r.sort(h);for(var o=0;o<r.length;++o){var l=p(e,r[o],n);if(l&&-1===a.indexOf(l)&&(a.push(l),2===a.length))break}return a},m=function(e,t,n){var i=e.children[0],a=e.children[1],r=e.children[2],o=i.querySelector(".app_table_collapsed_caption"),l="none"!==a.style.display;return l?(a.style.display="none",i.classList.remove("pagelib_collapse_table_collapsed"),i.classList.remove("pagelib_collapse_table_icon"),i.classList.add("pagelib_collapse_table_expanded"),o&&(o.style.visibility="visible"),r.style.display="none",t===r&&n&&n(e)):(a.style.display="block",i.classList.remove("pagelib_collapse_table_expanded"),i.classList.add("pagelib_collapse_table_collapsed"),i.classList.add("pagelib_collapse_table_icon"),o&&(o.style.visibility="hidden"),r.style.display="block"),l},v=function(e){var t=this.parentNode;return m(t,this,e)},b=function(e){var t=["navbox","vertical-navbox","navbox-inner","metadata","mbox-small"].some(function(t){return e.classList.contains(t)});return"none"!==e.style.display&&!t},y=function(e){return e.classList.contains("infobox")},E=function(e,t){var n=e.createElement("div");return n.classList.add("pagelib_collapse_table_collapsed_container"),n.classList.add("pagelib_collapse_table_expanded"),n.appendChild(t),n},T=function(e,t){var n=e.createElement("div");return n.classList.add("pagelib_collapse_table_collapsed_bottom"),n.classList.add("pagelib_collapse_table_icon"),n.innerHTML=t||"",n},L=function(e,t,n){var i=e.createDocumentFragment(),a=e.createElement("strong");a.innerHTML=t,i.appendChild(a);var r=e.createElement("span");return r.classList.add("pagelib_collapse_table_collapse_text"),n.length>0&&r.appendChild(e.createTextNode(": "+n[0])),n.length>1&&r.appendChild(e.createTextNode(", "+n[1])),n.length>0&&r.appendChild(e.createTextNode(" …")),i.appendChild(r),i},w=function(e,t,n,r,o,l,s,u,c){if(!r)for(var d=t.querySelectorAll("table"),f=function(r){var f=d[r];if(a.default.findClosestAncestor(f,".pagelib_collapse_table_container")||!b(f))return"continue";var _=g(t,f,n);if(!_.length&&!y(f))return"continue";var p=L(t,y(f)?l:s,_),h=t.createElement("div");h.className="pagelib_collapse_table_container",f.parentNode.insertBefore(h,f),f.parentNode.removeChild(f),f.style.marginTop="0px",f.style.marginBottom="0px";var w=E(t,p);w.style.display="block";var C=T(t,u);C.style.display="none",h.appendChild(w),h.appendChild(f),h.appendChild(C),f.style.display="none";var x=function(t){return e.dispatchEvent(new i.default.CustomEvent("section-toggled",{collapsed:t}))};w.onclick=function(){var e=v.bind(w)();x(e)},C.onclick=function(){var e=v.bind(C,c)();x(e)},o||m(h)},_=0;_<d.length;++_)f(_)};t.default={SECTION_TOGGLED_EVENT_TYPE:"section-toggled",toggleCollapseClickCallback:v,collapseTables:function(e,t,n,i,a,r,o,l){w(e,t,n,i,!0,a,r,o,l)},adjustTables:w,expandCollapsedTableIfItContainsElement:function(e){if(e){var t=a.default.findClosestAncestor(e,'[class*="pagelib_collapse_table_container"]');if(t){var n=t.firstElementChild;n&&n.classList.contains("pagelib_collapse_table_expanded")&&n.click()}}},test:{elementScopeComparator:h,extractEligibleHeaderText:p,firstWordFromString:s,getTableHeaderTextArray:g,shouldTableBeCollapsed:b,isHeaderEligible:o,isHeaderTextEligible:l,isInfobox:y,newCollapsedHeaderDiv:E,newCollapsedFooterDiv:T,newCaptionFragment:L,isNodeTextContentSimilarToPageTitle:u,stringWithNormalizedWhitespace:d,replaceNodeWithBreakingSpaceTextNode:_}}},,,,,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(14);var i,a=n(1),r=(i=a)&&i.__esModule?i:{default:i};var o=function(e){for(var t=[],n=e;n.parentElement&&!(n=n.parentElement).classList.contains("content_block");)t.push(n);return t},l=function(e,t,n){e[t]=n},s=function(e,t,n){Boolean(e[t])&&l(e,t,n)},u={width:"100%",height:"auto",maxWidth:"100%",float:"none"},c=function(e){Object.keys(u).forEach(function(t){return s(e.style,t,u[t])})},d=function(e){Object.keys(u).forEach(function(t){return l(e.style,t,u[t])})},f=function(e){o(e).forEach(c);var t=r.default.findClosestAncestor(e,"a.image");t&&d(t)},_=function(e){return!r.default.findClosestAncestor(e,"[class*='noresize']")&&(!r.default.findClosestAncestor(e,"div[class*='tsingle']")&&(!e.hasAttribute("usemap")&&!r.default.isNestedInTable(e)))};t.default={maybeWidenImage:function(e){return!!_(e)&&(function(e){f(e),e.classList.add("pagelib_widen_image_override")}(e),!0)},test:{ancestorsToWiden:o,shouldWidenImage:_,updateExistingStyleValue:s,widenAncestors:f,widenElementByUpdatingExistingStyles:c,widenElementByUpdatingStyles:d}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,a=n(0),r=(i=a)&&i.__esModule?i:{default:i};var o=function(e,t){e.innerHTML=t.innerHTML,e.setAttribute("class",t.getAttribute("class"))},l=function(e){return r.default.querySelectorAll(e,"a.new")},s=function(e){return e.createElement("span")},u=function(e,t){return e.parentNode.replaceChild(t,e)};t.default={hideRedLinks:function(e){var t=s(e);l(e).forEach(function(e){var n=t.cloneNode(!1);o(n,e),u(e,n)})},test:{configureRedLinkTemplate:o,redLinkAnchorsInDocument:l,newRedLinkTemplate:s,replaceAnchorWithSpan:u}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i={ANDROID:"pagelib_platform_android",IOS:"pagelib_platform_ios"};t.default={CLASS:i,classify:function(e){var t=e.document.querySelector("html");(function(e){return/android/i.test(e.navigator.userAgent)})(e)&&t.classList.add(i.ANDROID),function(e){return/ipad|iphone|ipod/i.test(e.navigator.userAgent)}(e)&&t.classList.add(i.IOS)}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}(),a=s(n(9)),r=s(n(1)),o=s(n(3)),l=s(n(2));function s(e){return e&&e.__esModule?e:{default:e}}var u=["scroll","resize",a.default.SECTION_TOGGLED_EVENT_TYPE],c=100,d=function(){function e(t,n){var i=this;!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this._window=t,this._loadDistanceMultiplier=n,this._placeholders=[],this._registered=!1,this._throttledLoadPlaceholders=l.default.wrap(t,c,function(){return i._loadPlaceholders()})}return i(e,[{key:"convertImagesToPlaceholders",value:function(e){var t=o.default.queryLazyLoadableImages(e),n=o.default.convertImagesToPlaceholders(this._window.document,t);this._placeholders=this._placeholders.concat(n),this._register()}},{key:"loadPlaceholders",value:function(){this._throttledLoadPlaceholders()}},{key:"deregister",value:function(){var e=this;this._registered&&(u.forEach(function(t){return e._window.removeEventListener(t,e._throttledLoadPlaceholders)}),this._throttledLoadPlaceholders.reset(),this._placeholders=[],this._registered=!1)}},{key:"_register",value:function(){var e=this;!this._registered&&this._placeholders.length&&(this._registered=!0,u.forEach(function(t){return e._window.addEventListener(t,e._throttledLoadPlaceholders)}))}},{key:"_loadPlaceholders",value:function(){var e=this;this._placeholders=this._placeholders.filter(function(t){var n=!0;return e._isPlaceholderEligibleToLoad(t)&&(o.default.loadPlaceholder(e._window.document,t),n=!1),n}),0===this._placeholders.length&&this.deregister()}},{key:"_isPlaceholderEligibleToLoad",value:function(e){return r.default.isVisible(e)&&this._isPlaceholderWithinLoadDistance(e)}},{key:"_isPlaceholderWithinLoadDistance",value:function(e){var t=e.getBoundingClientRect(),n=this._window.innerHeight*this._loadDistanceMultiplier;return!(t.top>n||t.bottom<-n)}}]),e}();t.default=d},,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}(),a=s(n(6)),r=s(n(5)),o=s(n(4)),l=s(n(2));function s(e){return e&&e.__esModule?e:{default:e}}var u=function(){function e(){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this._resizeListener=void 0}return i(e,[{key:"add",value:function(e,t,n,i,s,u,c,d,f,_,p,h,g){this.remove(e),t.appendChild(a.default.containerFragment(e.document)),r.default.add(e.document,c,d,"pagelib_footer_container_legal",f,_,p),o.default.setHeading(s,"pagelib_footer_container_readmore_heading",e.document),o.default.add(i,u,"pagelib_footer_container_readmore_pages",n,g,function(t){a.default.updateBottomPaddingToAllowReadMoreToScrollToTop(e),h(t)},e.document),this._resizeListener=l.default.wrap(e,100,function(){return a.default.updateBottomPaddingToAllowReadMoreToScrollToTop(e)}),e.addEventListener("resize",this._resizeListener)}},{key:"remove",value:function(e){this._resizeListener&&(e.removeEventListener("resize",this._resizeListener),this._resizeListener.cancel(),this._resizeListener=void 0);var t=e.document.getElementById("pagelib_footer_container");t&&t.parentNode.removeChild(t)}}]),e}();t.default=u},,function(e,t,n){},,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=function(){function e(e,t){for(var n=0;n<t.length;n++){var i=t[n];i.enumerable=i.enumerable||!1,i.configurable=!0,"value"in i&&(i.writable=!0),Object.defineProperty(e,i.key,i)}}return function(t,n,i){return n&&e(t.prototype,n),i&&e(t,i),t}}();n(25);var a,r=n(8),o=(a=r)&&a.__esModule?a:{default:a};var l={languages:1,lastEdited:2,pageIssues:3,disambiguation:4,coordinate:5,talkPage:6},s=function(){function e(t,n,i,a){!function(e,t){if(!(e instanceof t))throw new TypeError("Cannot call a class as a function")}(this,e),this.title=t,this.subtitle=n,this.itemType=i,this.clickHandler=a,this.payload=[]}return i(e,[{key:"iconClass",value:function(){switch(this.itemType){case l.languages:return"pagelib_footer_menu_icon_languages";case l.lastEdited:return"pagelib_footer_menu_icon_last_edited";case l.talkPage:return"pagelib_footer_menu_icon_talk_page";case l.pageIssues:return"pagelib_footer_menu_icon_page_issues";case l.disambiguation:return"pagelib_footer_menu_icon_disambiguation";case l.coordinate:return"pagelib_footer_menu_icon_coordinate";default:return""}}},{key:"payloadExtractor",value:function(){switch(this.itemType){case l.pageIssues:return o.default.collectPageIssuesText;case l.disambiguation:return function(e,t){return o.default.collectDisambiguationTitles(t)};default:return}}}]),e}();t.default={MenuItemType:l,setHeading:function(e,t,n){var i=n.getElementById(t);i.innerText=e,i.title=e},maybeAddItem:function(e,t,n,i,a,r){var o=new s(e,t,n,a),l=o.payloadExtractor();l&&(o.payload=l(r,r.querySelector("div#content_block_0")),0===o.payload.length)||function(e,t,n){n.getElementById(t).appendChild(function(e,t){var n=t.createElement("div");n.className="pagelib_footer_menu_item";var i=t.createElement("a");if(i.addEventListener("click",function(){e.clickHandler(e.payload)}),n.appendChild(i),e.title){var a=t.createElement("div");a.className="pagelib_footer_menu_item_title",a.innerText=e.title,i.title=e.title,i.appendChild(a)}if(e.subtitle){var r=t.createElement("div");r.className="pagelib_footer_menu_item_subtitle",r.innerText=e.subtitle,i.appendChild(r)}var o=e.iconClass();return o&&n.classList.add(o),t.createDocumentFragment().appendChild(n)}(e,n))}(o,i,r)}}},,function(e,t,n){},,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i,a=n(0),r=(i=a)&&i.__esModule?i:{default:i};var o=function(e){var t=e.querySelector('[id="coordinates"]'),n=t?t.textContent.length:0;return e.textContent.length-n>=50},l=function(e){var t=[],n=e;do{t.push(n),n=n.nextSibling}while(n&&(1!==n.nodeType||"P"!==n.tagName));return t},s=function(e,t){return r.default.querySelectorAll(e,"#"+t+" > p").find(o)};t.default={moveLeadIntroductionUp:function(e,t,n){var i=s(e,t);if(i){var a=e.createDocumentFragment();l(i).forEach(function(e){return a.appendChild(e)});var r=e.getElementById(t),o=n?n.nextSibling:r.firstChild;r.insertBefore(a,o)}},test:{isParagraphEligible:o,extractLeadIntroductionNodes:l,getEligibleParagraph:s}}},,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(33);var i={SECTION_HEADER:"pagelib_edit_section_header",TITLE:"pagelib_edit_section_title",LINK_CONTAINER:"pagelib_edit_section_link_container",LINK:"pagelib_edit_section_link",PROTECTION:{UNPROTECTED:"",PROTECTED:"page-protected",FORBIDDEN:"no-editing"}},a="data-id",r="data-action",o=function(e,t){var n=e.createElement("span");n.classList.add(i.LINK_CONTAINER);var o=function(e,t){var n=e.createElement("a");return n.href="",n.setAttribute(a,t),n.setAttribute(r,"edit_section"),n.classList.add(i.LINK),n}(e,t);return n.appendChild(o),n};t.default={CLASS:i,newEditSectionButton:o,newEditSectionHeader:function(e,t,n,r){var l=e.createElement("div");l.className=i.SECTION_HEADER;var s=e.createElement("h"+n);s.innerHTML=r||"",s.className=i.TITLE,s.setAttribute(a,t),l.appendChild(s);var u=o(e,t);return l.appendChild(u),l}}},,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(36);var i="pagelib_dim_images";t.default={CLASS:i,isDim:function(e){return e.document.querySelector("html").classList.contains(i)},dim:function(e,t){e.document.querySelector("html").classList[t?"add":"remove"](i)}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i={FILTER:"pagelib_compatibility_filter"};t.default={COMPATIBILITY:i,enableSupport:function(e){var t=e.querySelector("html");(function(e){return function(e,t,n){var i=e.createElement("span");return t.some(function(e){return i.style[e]=n,i.style.cssText})}(e,["webkitFilter","filter"],"blur(0)")})(e)||t.classList.add(i.FILTER)}}},,function(e,t,n){},,function(e,t,n){},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),n(42);var i=r(n(1)),a=r(n(0));function r(e){return e&&e.__esModule?e:{default:e}}var o={IMAGE_PRESUMES_WHITE_BACKGROUND:"pagelib_theme_image_presumes_white_background",DIV_DO_NOT_APPLY_BASELINE:"pagelib_theme_div_do_not_apply_baseline"},l={DEFAULT:"pagelib_theme_default",DARK:"pagelib_theme_dark",SEPIA:"pagelib_theme_sepia",BLACK:"pagelib_theme_black"},s=new RegExp("Kit_(body|socks|shorts|right_arm|left_arm)(.*).png$"),u=function(e){return!s.test(e.src)&&(!e.classList.contains("mwe-math-fallback-image-inline")&&!i.default.closestInlineStyle(e,"background"))};t.default={CONSTRAINT:o,THEME:l,setTheme:function(e,t){var n=e.querySelector("html");for(var i in n.classList.add(t),l)Object.prototype.hasOwnProperty.call(l,i)&&l[i]!==t&&n.classList.remove(l[i])},classifyElements:function(e){a.default.querySelectorAll(e,"img").filter(u).forEach(function(e){e.classList.add(o.IMAGE_PRESUMES_WHITE_BACKGROUND)});var t=["div.color_swatch div",'div[style*="position: absolute"]','div.barbox table div[style*="background:"]','div.chart div[style*="background-color"]','div.chart ul li span[style*="background-color"]',"span.legend-color","div.mw-highlight span","code.mw-highlight span"].join();a.default.querySelectorAll(e,t).forEach(function(e){return e.classList.add(o.DIV_DO_NOT_APPLY_BASELINE)})}}},function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0});var i=w(n(43)),a=w(n(9)),r=w(n(8)),o=w(n(38)),l=w(n(37)),s=w(n(34)),u=w(n(7)),c=w(n(1)),d=w(n(31)),f=w(n(6)),_=w(n(5)),p=w(n(26)),h=w(n(4)),g=w(n(21)),m=w(n(3)),v=w(n(18)),b=w(n(17)),y=w(n(0)),E=w(n(16)),T=w(n(2)),L=w(n(15));function w(e){return e&&e.__esModule?e:{default:e}}t.default={CollapseTable:a.default,CollectionUtilities:r.default,CompatibilityTransform:o.default,DimImagesTransform:l.default,EditTransform:s.default,LeadIntroductionTransform:d.default,FooterContainer:f.default,FooterLegal:_.default,FooterMenu:p.default,FooterReadMore:h.default,FooterTransformer:g.default,LazyLoadTransform:m.default,LazyLoadTransformer:v.default,PlatformTransform:b.default,RedLinks:E.default,ThemeTransform:i.default,WidenImage:L.default,test:{ElementGeometry:u.default,ElementUtilities:c.default,Polyfill:y.default,Throttle:T.default}}}]).default});

},{}]},{},[1,2,3,4,5,6,7,8,9]);
