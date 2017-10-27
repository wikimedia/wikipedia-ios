/*
TODO
 - maybe modify image urls to proxy not by parsing on native side but by using JS transforms once we have doc frag? (they're already parsed anyway)
 - could we prototype any missing fragment objects if a transforms calls something on frag which only exits in document?
 - ensure TOC logic keeps working
 - make sure this works - (void)loadHTMLFromAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment {
 - use updates from these branches (dropping iOS 9)
    remove-css-cruft
    remove-version-10-checks
 - figure out earliest point at which it's safe to kick off this js
 - paragraph relocation not happening on "enwiki > color" and "enwiki > United States"
 - add JSDocs explaining all types
 - consider switching footer XF to also act on headless fragment
*/

// backfill fragments with "createElement" so transforms will work as well with fragments as
// they do with documents
DocumentFragment.prototype.createElement = name => document.createElement(name)

const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

class LocalizedStrings {
  constructor(tableInfoboxTitle, tableOtherTitle, tableFooterTitle, readMoreHeading, licenseString, licenseSubstitutionString, viewInBrowserString, menuHeading, menuLanguagesTitle, menuLastEditedTitle, menuLastEditedSubtitle, menuTalkPageTitle, menuPageIssuesTitle, menuDisambiguationTitle, menuCoordinateTitle, errorMessage) {
    this.tableInfoboxTitle = tableInfoboxTitle
    this.tableOtherTitle = tableOtherTitle
    this.tableFooterTitle = tableFooterTitle
    this.readMoreHeading = readMoreHeading
    this.licenseString = licenseString
    this.licenseSubstitutionString = licenseSubstitutionString
    this.viewInBrowserString = viewInBrowserString
    this.menuHeading = menuHeading
    this.menuLanguagesTitle = menuLanguagesTitle
    this.menuLastEditedTitle = menuLastEditedTitle
    this.menuLastEditedSubtitle = menuLastEditedSubtitle
    this.menuTalkPageTitle = menuTalkPageTitle
    this.menuPageIssuesTitle = menuPageIssuesTitle
    this.menuDisambiguationTitle = menuDisambiguationTitle
    this.menuCoordinateTitle = menuCoordinateTitle
    this.errorMessage = errorMessage
    // Ensure everything is a string
    for (const property in this) {
      if (this.hasOwnProperty(property)) {
        if(this[property] === undefined){
          this[property] = ''
        }
      }
    }
  }
}

class Language {
  constructor(code, dir, isRTL) {
    this.code = code
    this.dir = dir
    this.isRTL = isRTL
  }
}

class Article {
  constructor(ismain, title, description, editable, language, hasReadMore) {
    this.ismain = ismain
    this.title = title
    this.description = description
    this.editable = editable
    this.language = language
    this.hasReadMore = hasReadMore
  }
  descriptionParagraph() {
    if(this.description !== undefined && this.description.length > 0){
      return `<p id='entity_description'>${this.description}</p>`
    }
    return ''
  }
}

class Section {
  constructor(toclevel, level, line, number, index, fromtitle, anchor, id, text, article) {
    this.toclevel = toclevel
    this.level = level
    this.line = line
    this.number = number
    this.index = index
    this.fromtitle = fromtitle
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
                ${this.article.title}
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
    //TODO clamp section.level to between 1 and 6
    container.innerHTML = `
        ${this.article.ismain ? '' : this.headingTag()}
        <div id="content_block_${this.id}" class="content_block">
            ${this.isNonMainPageLeadSection() ? '<hr id="content_block_0_hr">' : ''}
            ${this.html()}
        </div>`
    return container
  }
}

class Footer {
  constructor(article, menuItems, readMoreItemCount, localizedStrings, proxyURL) {
    this.article = article
    this.menuItems = menuItems
    this.readMoreItemCount = readMoreItemCount
    this.localizedStrings = localizedStrings
    this.proxyURL = proxyURL
  }
  addContainer() {
    if (window.wmf.footerContainer.isContainerAttached(document) === false) {
      document.querySelector('body').appendChild(window.wmf.footerContainer.containerFragment(document))
      window.webkit.messageHandlers.footerContainerAdded.postMessage('added')
    }
  }
  addDynamicBottomPadding() {
    window.addEventListener('resize', function(){window.wmf.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)})
  }
  addMenu() {
    window.wmf.footerMenu.setHeading(this.localizedStrings.menuHeading, 'pagelib_footer_container_menu_heading', document)
    this.menuItems.forEach(item => {
      let title = ''
      let subtitle = ''
      let menuItemTypeString = ''
      switch(item) {
      case window.wmf.footerMenu.MenuItemType.languages:
        menuItemTypeString = 'languages'
        title = this.localizedStrings.menuLanguagesTitle
        break
      case window.wmf.footerMenu.MenuItemType.lastEdited:
        menuItemTypeString = 'lastEdited'
        title = this.localizedStrings.menuLastEditedTitle
        subtitle = this.localizedStrings.menuLastEditedSubtitle
        break
      case window.wmf.footerMenu.MenuItemType.pageIssues:
        menuItemTypeString = 'pageIssues'
        title = this.localizedStrings.menuPageIssuesTitle
        break
      case window.wmf.footerMenu.MenuItemType.disambiguation:
        menuItemTypeString = 'disambiguation'
        title = this.localizedStrings.menuDisambiguationTitle
        break
      case window.wmf.footerMenu.MenuItemType.coordinate:
        menuItemTypeString = 'coordinate'
        title = this.localizedStrings.menuCoordinateTitle
        break
      case window.wmf.footerMenu.MenuItemType.talkPage:
        menuItemTypeString = 'talkPage'
        title = this.localizedStrings.menuTalkPageTitle
        break
      default:
      }
      const itemSelectionHandler = payload => window.webkit.messageHandlers.footerMenuItemClicked.postMessage({'selection': menuItemTypeString, 'payload': payload})
      window.wmf.footerMenu.maybeAddItem(title, subtitle, item, 'pagelib_footer_container_menu_items', itemSelectionHandler, document)
    })
  }
  addReadMore() {
    if (this.article.hasReadMore){
      window.wmf.footerReadMore.setHeading(this.localizedStrings.readMoreHeading, 'pagelib_footer_container_readmore_heading', document)
      const saveButtonTapHandler = title => window.webkit.messageHandlers.footerReadMoreSaveClicked.postMessage({'title': title})
      const titlesShownHandler = titles => {
        window.webkit.messageHandlers.footerReadMoreTitlesShown.postMessage(titles)
        window.wmf.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)
      }
      window.wmf.footerReadMore.add(this.article.title, this.readMoreItemCount, 'pagelib_footer_container_readmore_pages', this.proxyURL, saveButtonTapHandler, titlesShownHandler, document)
    }
  }
  addLegal() {
    const licenseLinkClickHandler = () => window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked')
    const viewInBrowserLinkClickHandler = () => window.webkit.messageHandlers.footerBrowserLinkClicked.postMessage('linkClicked')
    window.wmf.footerLegal.add(document, this.localizedStrings.licenseString, this.localizedStrings.licenseSubstitutionString, 'pagelib_footer_container_legal', licenseLinkClickHandler, this.localizedStrings.viewInBrowserString, viewInBrowserLinkClickHandler)
  }
  add() {
    this.addContainer()
    this.addDynamicBottomPadding()
    this.addMenu()
    this.addReadMore()
    this.addLegal()
  }
}

const processStatus = response => {
  if (response.status === 200) { // can use status 0 if loading local files
    return Promise.resolve(response)
  }
  return Promise.reject(new Error(response.statusText))
}

const extractJSON = response => response.json()

const fragmentForSection = section => {
  const fragment = document.createDocumentFragment()
  const container = section.containerDiv() // do not append this to document. keep unattached to main DOM (ie headless) until transforms have been run on the fragment
  fragment.appendChild(container)
  return fragment
}

const applyTransformationsToFragment = (fragment, article, isLead) => {
  //TODO if/when all transform calls happen happen here, will no longer need 'wmf' object or index-main.js/preview-main.js files
  const wmf = window.wmf

  wmf.redLinks.hideRedLinks(document, fragment)

  wmf.filePages.disableFilePageEdit(fragment)

  if(!article.ismain){
    if (isLead){
      //TODO fix height heuristic in paragraph relocation xf
      wmf.paragraphs.moveFirstGoodParagraphAfterElement( 'content_block_0_hr', fragment )
      wmf.editButtons.addEditButtonAfterElement('#content_block_0_hr', 0, fragment)
    }else{
      wmf.editButtons.addEditButtonsToElements('.section_heading[data-id]:not([data-id=""]):not([data-id="0"])', 'data-id', fragment)
    }
  }

  wmf.tables.hideTables(fragment, article.ismain, article.title, this.localizedStrings.tableInfoboxTitle, this.localizedStrings.tableOtherTitle, this.localizedStrings.tableFooterTitle)

  //TODO when proxy delivers section html ensure it sets both data-image-gallery and image variant widths! (at moment variant width isnt' set so images
  //dont get widened even though i'm forcing "data-image-gallery" to true here - the css *is* being changed though)
  const images = fragment.querySelectorAll('img').forEach(function(image){
    // maybeWidenImage(image)
    const isGallery = parseInt(image.width) > 70 ? 'true' : 'false'
    image.setAttribute('data-image-gallery', isGallery)
  })
  wmf.images.widenImages(fragment)
  //TODO handle other transforms here

}

const transformAndAppendSection = (section, mainContentDiv) => {
  const fragment = fragmentForSection(section)
  // Transform the fragments *before* attaching them to the main DOM.
  applyTransformationsToFragment(fragment, section.article, section.isLeadSection())
  mainContentDiv.appendChild(fragment)
}

//early page-wide transforms which happen before any sections have been appended
const performEarlyNonSectionTransforms = article => {
  window.wmf.utilities.setPageProtected(!article.editable)
  window.wmf.utilities.setLanguage(article.language.code, article.language.dir, article.language.isRTL ? 'rtl': 'ltr')
}

//late so they won't delay section fragment processing
const performLateNonSectionTransforms = (article, proxyURL) => {
  const footer = new Footer(article, this.menuItems, 3, this.localizedStrings, proxyURL)
  footer.add()
  // 'themes.classifyElements()' needs to happen once after body elements are present. it
  // classifies some tricky elements like math formula images (see 'enwiki > Quadradic formula')
  window.wmf.themes.classifyElements(document)
}

const transformAndAppendSectionsToDocument = (json, article) => {
  const mainContentDiv = document.querySelector('div.content')
  const sections = json['mobileview']['sections']
  sections.forEach(section => {
    const sectionModel = new Section(section.toclevel, section.level, section.line, section.number, section.index, section.fromtitle, section.anchor, section.id, section.text, article)
    transformAndAppendSection(sectionModel, mainContentDiv)
  })
}

const fetchTransformAndAppendSectionsToDocument = (article, proxyURL, apiURL) =>{
  performEarlyNonSectionTransforms(article)

  fetch(apiURL)
  .then(processStatus)
  .then(extractJSON)
  .then(json => transformAndAppendSectionsToDocument(json, article))
  .then(() => performLateNonSectionTransforms(article, proxyURL))
  .catch(error => console.log(`Promise was rejected with error: ${error}`))
}

exports.fetchTransformAndAppendSectionsToDocument = fetchTransformAndAppendSectionsToDocument
exports.Language = Language
exports.Article = Article
exports.LocalizedStrings = LocalizedStrings
exports.localizedStrings = undefined
exports.menuItems = undefined