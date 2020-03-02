const utilities = require('./utilities')

class SelectedTextEditInfo {
  constructor(selectedAndAdjacentText, isSelectedTextInTitleDescription, sectionID) {
    this.selectedAndAdjacentText = selectedAndAdjacentText
    this.isSelectedTextInTitleDescription = isSelectedTextInTitleDescription
    this.sectionID = sectionID
  }
}

const getClosestFromSelection = (selection, selector) => {
  if (!selection) {
    return null
  }
  if (!selection.anchorNode) {
    return null
  }
  if (!selection.anchorNode.parentElement) {
    return null
  }
  return selection.anchorNode.parentElement.closest(selector)
}

const isSelectedTextInTitleDescription = selection => getClosestFromSelection(selection, 'p#pcs-edit-section-title-description') != null

const isSelectedTextInArticleTitle = selection  => getClosestFromSelection(selection, 'h1.pcs-edit-section-title') != null

const getSelectedTextSectionID = selection => {
  const section = getClosestFromSelection(selection, 'section[data-mw-section-id]')
  if (!section) {
    return null
  }
  const sectionIDString = section.getAttribute('data-mw-section-id')
  if (sectionIDString == null) {
    return null
  }
  return parseInt(sectionIDString)
}

const getSelectedTextEditInfo = () => {
  const selection = window.getSelection()

  const isTitleDescriptionSelection = isSelectedTextInTitleDescription(selection)
  let sectionID = 0
  if (!isTitleDescriptionSelection) {
    sectionID = getSelectedTextSectionID(selection)
  }

  let selectedAndAdjacentText = isSelectedTextInArticleTitle(selection) ? new SelectedAndAdjacentText('', '', '') : getSelectedAndAdjacentText().reducedToSpaceSeparatedWordsOnly()

  selection.removeAllRanges()
  selection.empty()

  return new SelectedTextEditInfo(
    selectedAndAdjacentText,
    isTitleDescriptionSelection,
    sectionID
  )
}

const stringWithoutParenthesisForString = s => s.replace(/\([^\(\)]*\)/g, ' ')
const stringWithoutReferenceForString = s => s.replace(/\[[^\[\]]*\]/g, ' ')

// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `codemirror-editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
  // Reduces to space separated words only and only keeps a couple adjacent before and after words.
  reducedToSpaceSeparatedWordsOnly() {
    const separator = ' '
    const wordsOnlyForString = s => stringWithoutParenthesisForString(stringWithoutReferenceForString(s)).replace(/[\W]+/g, separator).trim().split(separator)

    return new SelectedAndAdjacentText(
      wordsOnlyForString(this.selectedText).join(separator),
      wordsOnlyForString(this.textBeforeSelectedText).join(separator),
      wordsOnlyForString(this.textAfterSelectedText).join(separator)
    )
  }
}

const getSelectedAndAdjacentText = () => {
  const selection = window.getSelection()
  const range = selection.getRangeAt(0)
  const selectedText = range.toString()
  selection.modify('extend', 'backward', 'sentenceboundary')
  const textBeforeSelectedText = window.getSelection().getRangeAt(0).toString().slice(0, -selectedText.length)
  selection.modify('extend', 'forward', 'sentenceboundary')
  const textAfterSelectedText = window.getSelection().getRangeAt(0).toString()
  window.getSelection().removeAllRanges()
  window.getSelection().addRange(range)
  return new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
}

exports.getSelectedTextEditInfo = getSelectedTextEditInfo