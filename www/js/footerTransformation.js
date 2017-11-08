
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