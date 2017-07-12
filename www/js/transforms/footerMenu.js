
function pageIssuesStringsArray() {
  const tables = document.querySelectorAll( 'div#content_block_0 table.ambox:not(.ambox-multiple_issues):not(.ambox-notice)' )
  // Get the tables into a fragment so we can remove some elements without triggering a layout
  var fragment = document.createDocumentFragment()
  for (var i = 0; i < tables.length; i++) {
    fragment.appendChild(tables[i].cloneNode(true))
  }
  // Remove some element so their text doesn't appear when we use "innerText"
  Array.from(fragment.querySelectorAll( '.hide-when-compact, .collapsed' )).forEach(el => el.remove())
  // Get the innerText
  return Array.from(fragment.querySelectorAll( 'td[class$=mbox-text]' )).map(el => el.innerText)
}

function disambiguationTitlesArray() {
  return Array.from(document.querySelectorAll('div#content_block_0 div.hatnote a[href]:not([href=""]):not([redlink="1"])')).map(el => el.href)
}

var ItemTypeEnum = {
  languages: 1,
  lastEdited: 2,
  pageIssues: 3,
  disambiguation: 4,
  coordinate: 5,
  iconClass: {
    1: 'footer_menu_icon_languages',
    2: 'footer_menu_icon_last_edited',
    3: 'footer_menu_icon_page_issues',
    4: 'footer_menu_icon_disambiguation',
    5: 'footer_menu_icon_coordinate'
  },
  payloadExtractor: {
    1: null,
    2: null,
    3: pageIssuesStringsArray,
    4: disambiguationTitlesArray,
    5: null
  }
}

class WMFMenuItem {
  constructor(title, subtitle, itemType, clickHandler) {
    this.title = title
    this.subtitle = subtitle
    this.itemType = itemType
    this.clickHandler = clickHandler
    this.payload = []
  }
  iconClass(){
    return ItemTypeEnum.iconClass[this.itemType]
  }
  payloadExtractor(){
    return ItemTypeEnum.payloadExtractor[this.itemType]
  }
}

class WMFMenuItemFragment {
  constructor(wmfMenuItem) {
    var item = document.createElement('div')
    item.className = 'footer_menu_item'

    var containerAnchor = document.createElement('a')
    containerAnchor.addEventListener('click', function(){
      wmfMenuItem.clickHandler(wmfMenuItem.payload)
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

    var iconClass = wmfMenuItem.iconClass()
    if(iconClass){
      item.classList.add(iconClass)
    }

    return document.createDocumentFragment().appendChild(item)
  }
}

function maybeAddItem(title, subtitle, itemType, containerID, clickHandler) {
  const item = new WMFMenuItem(title, subtitle, itemType, clickHandler)

  // Items are not added if they have a payload extractor which fails to extract anything.
  if (item.payloadExtractor() !== null){
    item.payload = item.payloadExtractor()()
    if(item.payload.length === 0){
      return
    }
  }

  addItem(item, containerID)
}

function addItem(wmfMenuItem, containerID) {
  const fragment = new WMFMenuItemFragment(wmfMenuItem)
  document.getElementById(containerID).appendChild(fragment)
}

function setHeading(headingString, headingID) {
  const headingElement = document.getElementById(headingID)
  headingElement.innerText = headingString
  headingElement.title = headingString
}

exports.ItemTypeEnum = ItemTypeEnum
exports.setHeading = setHeading
exports.maybeAddItem = maybeAddItem
