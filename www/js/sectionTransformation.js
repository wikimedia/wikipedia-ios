/*
 - maybe modify image urls to proxy not by parsing on native side but by using JS transforms once we have doc frag? (they're already parsed anyway)
 - could we prototype any missing fragment objects if a transforms calls something on frag which only exits in document?
 - ensure TOC logic keeps working
 - keep doing getHTMLWrappedInTablesIfNeeded?
 - make sure this works - (void)loadHTMLFromAssetsFile:(NSString *)fileName scrolledToFragment:(NSString *)fragment {
 - use updates from these branches (dropping iOS 9)
    remove-css-cruft
    remove-version-10-checks
 - figure out earliest point at which it's safe to kick off this js
 - paragraph relocation not happening on "enwiki > color"
 - test viewing, say, hebrew article when device lang is EN - ensure footer localized strings are hebrew
*/



// backfill fragments with "createElement" so transforms will work as well with fragments as 
// they do with documents
DocumentFragment.prototype.createElement = name => document.createElement(name)

const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

class LocalizedStrings {
  constructor(tableInfoboxTitle, tableOtherTitle, tableFooterTitle, readMoreHeading, licenseString, licenseSubstitutionString, viewInBrowserString, menuHeading, menuLanguagesTitle, menuLastEditedTitle, menuLastEditedSubtitle, menuTalkPageTitle, menuPageIssuesTitle, menuDisambiguationTitle, menuCoordinateTitle) {
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
  constructor(ismain, title, description, editable, language) {
    this.ismain = ismain
    this.title = title
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
  
  headerTag() {
    if(this.isLeadSection()){
      return `<h1 class='section_heading' ${this.anchorAsElementId()} sectionId='${this.id}'>
                ${this.article.title}
              </h1>${this.article.descriptionParagraph()}`
    }
    return `<h${this.level} class="section_heading" data-id="${this.id}" id="${this.anchor}">
              ${this.line}
            </h${this.level}>`
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
    
  containerDiv() {
    const container = document.createElement('div')
    container.id = `section_heading_and_content_block_${this.id}`
    //TODO clamp section.level to between 1 and 6
    container.innerHTML = `
        ${this.article.ismain ? '' : this.headerTag()}
        <div id="content_block_${this.id}" class="content_block">
            ${this.isNonMainPageLeadSection() ? '<hr id="content_block_0_hr">' : ''}
            ${this.text}
        </div>`
    return container
  }
  
  
}











const processStatus = response => {
    if (response.status === 200) { // can use status 0 if loading local files
        return Promise.resolve(response)
    } 
    return Promise.reject(new Error(response.statusText))
}

const extractJSON = response => response.json()

//TODO probably don't extract all of these at once - do one at a time transforming/appending as we go for faster first paint
const extractSections = (json, article) => json['mobileview']['sections'].map(section => new Section(section.toclevel, section.level, section.line, section.number, section.index, section.fromtitle, section.anchor, section.id, section.text, article))  

const fragmentForSection = section => {
  const fragment = document.createDocumentFragment()
  const container = section.containerDiv() // do not append this to document. keep unattached to main DOM (ie headless) until transforms have been run on the fragment
  fragment.appendChild(container)
  return fragment
}

const applyTransformationsToFragment = (fragment, article, isLead, localizedStrings) => {
  
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
  
  wmf.tables.hideTables(fragment, article.ismain, article.title, localizedStrings.tableInfoboxTitle, localizedStrings.tableOtherTitle, localizedStrings.tableFooterTitle)

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

const transformAndAppendSections = (sections, localizedStrings) => {
  const mainContentDiv = document.querySelector('div.content')
  sections.forEach(function(section){
    transformAndAppendSection(section, mainContentDiv, localizedStrings)
  })
}

const transformAndAppendSection = (section, mainContentDiv, localizedStrings) => {
  const fragment = fragmentForSection(section)
  // Transform the fragments *before* attaching them to the main DOM.
  applyTransformationsToFragment(fragment, section.article, section.isLeadSection(), localizedStrings)
  mainContentDiv.appendChild(fragment)
}





//early page-wide transforms which happen before any sections have been appended
const performEarlyNonSectionTransforms = article => {
  window.wmf.utilities.setPageProtected(!article.editable)
  window.wmf.utilities.setLanguage(article.language.code, article.language.dir, article.language.isRTL ? 'rtl': 'ltr')
}

//late so they won't delay section fragment processing
const performLateNonSectionTransforms = (article, localizedStrings, proxyURL) => {
  //TODO add footer transforms here - 



  //TODO consider switching footer XF to also act on headless fragment
  
  
  // add footer container
  if (window.wmf.footerContainer.isContainerAttached(document) === false) {
      document.querySelector('body').appendChild(window.wmf.footerContainer.containerFragment(document))
      window.webkit.messageHandlers.footerContainerAdded.postMessage('added')
  }
  

  // add dynamic bottom padding
  window.addEventListener('resize', function(){window.wmf.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)})
  window.wmf.footerReadMore.setHeading(localizedStrings.readMoreHeading, 'pagelib_footer_container_readmore_heading', document)


  // add menu footer
  window.wmf.footerMenu.setHeading(localizedStrings.menuHeading, 'pagelib_footer_container_menu_heading', document)



  // add read more footer
  const saveButtonTapHandler = title => window.webkit.messageHandlers.footerReadMoreSaveClicked.postMessage({'title': title})
  const titlesShownHandler = titles => {
    window.webkit.messageHandlers.footerReadMoreTitlesShown.postMessage(titles)
    window.wmf.footerContainer.updateBottomPaddingToAllowReadMoreToScrollToTop(window)
  }
  const readMoreItemCount = 3
  window.wmf.footerReadMore.add(article.title, readMoreItemCount, 'pagelib_footer_container_readmore_pages', proxyURL, saveButtonTapHandler, titlesShownHandler, document)


  // add legal footer
  const licenseLinkClickHandler = () => window.webkit.messageHandlers.footerLegalLicenseLinkClicked.postMessage('linkClicked')
  const viewInBrowserLinkClickHandler = () => window.webkit.messageHandlers.footerBrowserLinkClicked.postMessage('linkClicked')
  window.wmf.footerLegal.add(document, localizedStrings.licenseString, localizedStrings.licenseSubstitutionString, 'pagelib_footer_container_legal', licenseLinkClickHandler, localizedStrings.viewInBrowserString, viewInBrowserLinkClickHandler)



  // 'themes.classifyElements()' needs to happen once after body elements are present. it
  // classifies some tricky elements like math formula images (see 'enwiki > Quadradic formula')
  window.wmf.themes.classifyElements(document)





}


//TODO add JSDocs explaining the article and localizedStrings parameters
const transformAndAppendSectionsToDocument = (proxyURL, apiURL, article, localizedStrings) =>{
  
  performEarlyNonSectionTransforms(article)

  fetch(`${proxyURL}${apiURL}`)
  .then(processStatus)
  .then(extractJSON)
  .then(json => extractSections(json, article))
  .then((sections) => transformAndAppendSections(sections, localizedStrings))
  .then(() => {
    performLateNonSectionTransforms(article, localizedStrings, proxyURL)
  })
  .catch(error => console.log(`Promise was rejected with error: ${error}`))
}

exports.transformAndAppendSectionsToDocument = transformAndAppendSectionsToDocument
exports.Language = Language
exports.Article = Article
exports.LocalizedStrings = LocalizedStrings


















