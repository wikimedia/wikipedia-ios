
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

var MenuItemType = {
  languages: 1,
  lastEdited: 2,
  pageIssues: 3,
  disambiguation: 4,
  coordinate: 5
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
    switch(this.itemType){
    case MenuItemType.languages:
      return 'footer_menu_icon_languages'
    case MenuItemType.lastEdited:
      return 'footer_menu_icon_last_edited'
    case MenuItemType.pageIssues:
      return 'footer_menu_icon_page_issues'
    case MenuItemType.disambiguation:
      return 'footer_menu_icon_disambiguation'
    case MenuItemType.coordinate:
      return 'footer_menu_icon_coordinate'
    }
  }
  payloadExtractor(){
    switch(this.itemType){
    case MenuItemType.languages:
      return null
    case MenuItemType.lastEdited:
      return null
    case MenuItemType.pageIssues:
      return pageIssuesStringsArray
    case MenuItemType.disambiguation:
      return disambiguationTitlesArray
    case MenuItemType.coordinate:
      return null
    }
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

exports.MenuItemType = MenuItemType
exports.setHeading = setHeading
exports.maybeAddItem = maybeAddItem