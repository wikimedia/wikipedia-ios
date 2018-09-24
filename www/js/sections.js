
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
  constructor(ismain, title, displayTitle, description, editable, language, addTitleDescriptionString, isTitleDescriptionEditable) {
    this.ismain = ismain
    this.title = title
    this.displayTitle = displayTitle
    this.description = description
    this.editable = editable
    this.language = language
    this.addTitleDescriptionString = addTitleDescriptionString
    this.isTitleDescriptionEditable = isTitleDescriptionEditable
  }
  descriptionElements() {
    if (!this.isTitleDescriptionEditable || this.description !== undefined && this.description.length > 0) {
      return this.existingDescriptionElements()
    }
    return this.descriptionAdditionElements()
  }
  existingDescriptionElements() {
    const p = lazyDocument.createElement('p')
    p.id = 'entity_description'
    p.innerHTML = this.description
    return p
  }
  descriptionAdditionElements() {
    const a = lazyDocument.createElement('a')
    a.href = '#'
    a.setAttribute('data-action', 'add_title_description')
    const p = lazyDocument.createElement('p')
    p.id = 'add_entity_description'
    p.innerHTML = this.addTitleDescriptionString
    a.appendChild(p)
    return a
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
    heading.classList.add('section_heading')
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
      return this.article.descriptionElements()
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
    block.classList.add('content_block')
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

  // Fix bug preventing audio from playing on 1st click of play button.
  fragment.querySelectorAll('audio[preload="none"]').forEach(audio => audio.setAttribute('preload', 'metadata'))
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
