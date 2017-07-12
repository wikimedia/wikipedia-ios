
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
