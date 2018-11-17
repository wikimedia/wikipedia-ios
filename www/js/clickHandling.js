const referenceCollection = require('wikimedia-page-library').ReferenceCollection
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
    if (referenceCollection.isCitation(this.href)) {
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
 * Use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in
 * native land to convert to CGRect.
 * @param  {!ReferenceItem} referenceItem
 * @return {void}
 */
const reformatReferenceItemRectToBridgeToCGRect = referenceItem => {
  referenceItem.rect = {
    X: referenceItem.rect.left,
    Y: referenceItem.rect.top,
    Width: referenceItem.rect.width,
    Height: referenceItem.rect.height
  }
}

/**
 * Sends message for a reference click.
 * @param  {!Element} target an anchor element
 * @return {void}
 */
const sendMessageForReferenceWithTarget = target => {
  const nearbyReferences = referenceCollection.collectNearbyReferences( document, target )
  nearbyReferences.referencesGroup.forEach(reformatReferenceItemRectToBridgeToCGRect)
  window.webkit.messageHandlers.referenceClicked.postMessage(nearbyReferences)
}

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

  // Handle add title description link.
  if (anchorForTarget.getAttribute( 'data-action' ) === 'add_title_description'){
    window.webkit.messageHandlers.addTitleDescriptionClicked.postMessage('add_title_description')
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