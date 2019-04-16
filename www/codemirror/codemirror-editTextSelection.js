
// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }

  selectedWordCount() {
    return this.selectedText.split(' ').length
  }
  
  // If enough selected words there's no need for as many adjacent disambiguation words.
  maxAdjacentWordsToUse() {
    const selectedWordCount = this.selectedWordCount()
    if (selectedWordCount < 4) {
      return 4
    }
    if (selectedWordCount < 6) {
      return 2
    }
    return 1
  }

  regexForLocatingSelectedTextInWikitext(wikitext) {
    const getWorkingRegexWithMostAdjacentWords = (regexGetter) => {
      for (let i = this.maxAdjacentWordsToUse(); i >= 0; i--) {
        const regex = regexGetter(i)
        if (regex.test(wikitext)) {
          return regex
        }    
      }
      return null
    }
    const restrictiveRegex = getWorkingRegexWithMostAdjacentWords(this.getRestrictiveRegex.bind(this))
    if (restrictiveRegex) {
      return restrictiveRegex
    }
    const permissiveRegex = getWorkingRegexWithMostAdjacentWords(this.getPermissiveRegex.bind(this))
    if (permissiveRegex) {
      return permissiveRegex
    }
    return null
  }

  // Faster, less error prone - but has more trouble with skipping past some unexpectedly complicated wiki markup, so more prone to not finding any match.
  getRestrictiveRegex(maxAdjacentWordsToUse) {
    const atLeastOneNonWordPattern = '\\W+'
    return this.regexForLocatingSelectedTextWithPatternForSpace(atLeastOneNonWordPattern, maxAdjacentWordsToUse)
  }
  
  // Slower, more error prone - but has less trouble with skipping past some unexpectedly complicated wiki markup, so less prone to not finding any match.
  getPermissiveRegex(maxAdjacentWordsToUse) {
    const atLeastOneCharPattern = '.+'
    return this.regexForLocatingSelectedTextWithPatternForSpace(atLeastOneCharPattern, maxAdjacentWordsToUse)
  }
    
  regexForLocatingSelectedTextWithPatternForSpace(patternForSpace, maxAdjacentWordsToUse) {
    const replaceSpaceWith = (s, replacement) => s.replace(/\s+/g, replacement)

    // Keep only the last 'maxAdjacentWordsToUse' words of 'textBeforeSelectedText'
    const shouldKeepWordBeforeSelection = (e, i, a) => (a.length - i - 1) < maxAdjacentWordsToUse
    // Keep only the first 'maxAdjacentWordsToUse' words of 'textAfterSelectedText'
    const shouldKeepWordAfterSelection = (e, i) => i < maxAdjacentWordsToUse
    const wordsBefore = this.textBeforeSelectedText.split(' ').filter(shouldKeepWordBeforeSelection).join(' ')
    const wordsAfter = this.textAfterSelectedText.split(' ').filter(shouldKeepWordAfterSelection).join(' ')

    const selectedTextPattern = replaceSpaceWith(this.selectedText, patternForSpace)
    const textBeforeSelectedTextPattern = replaceSpaceWith(wordsBefore, patternForSpace)
    const textAfterSelectedTextPattern = replaceSpaceWith(wordsAfter, patternForSpace)

    // Attempt to locate wikitext selection based on the non-wikitext context strings above.
    const atLeastOneNonWordOrOptionalStringPattern = '(?:\\W+|.*)'
    const pattern = `(${textBeforeSelectedTextPattern.length > 0 ? '.*?' : ''}${textBeforeSelectedTextPattern}${atLeastOneNonWordOrOptionalStringPattern})(${selectedTextPattern})${atLeastOneNonWordOrOptionalStringPattern}${textAfterSelectedTextPattern}`
    const regex = new RegExp(pattern, 's')

    return regex
  }
}

const wikitextRangeForSelectedAndAdjacentText = (selectedAndAdjacentText, wikitext) => {
  const regex = selectedAndAdjacentText.regexForLocatingSelectedTextInWikitext(wikitext)
  if (regex === null) {
    return null
  }
  const match = wikitext.match(regex)
  if (match === null) {
    return null
  }
  const matchedWikitextBeforeSelection = match[1]
  const matchedWikitextSelection = match[2]
  const wikitextRange = getWikitextRangeToSelect(matchedWikitextBeforeSelection, matchedWikitextSelection)
  return wikitextRange
}

const getWikitextRangeToSelect = (wikitextBeforeSelection, wikitextSelection) => {
  const wikitextBeforeSelectionLines = wikitextBeforeSelection.split('\n')
  const startLine = wikitextBeforeSelectionLines.length - 1 
  const startCh = wikitextBeforeSelectionLines.pop().length

  const wikitextSelectionLines = wikitextSelection.split('\n')
  const endLine = startLine + wikitextSelectionLines.length - 1
  const endCh = wikitextSelectionLines.pop().length + (startLine === endLine ? startCh : 0)

  let from = {line: startLine, ch: startCh}
  let to = {line: endLine, ch: endCh}
  
  return {from, to}
}

const scrollToAndHighlightRange = (range, codemirror) => {
  codemirror.setSelection(range.from, range.to, {scroll: false})
  setTimeout(() => { // Slight pause needed to ensure keyboard height is accounted for.
    scrollRangeIntoViewIfNeeded(range.from, range.to)
  }, 250)
    
  /*
  setTimeout(() => {
    marker.clear()
  }, 3000)
  */
}

const highlightAndScrollToWikitextForSelectedAndAdjacentText = (selectedText, textBeforeSelectedText, textAfterSelectedText) => {
  const throwError = () => {throw('Could not determine range to highlight')} // The message doesn't matter here. It's not displayed.
  if (selectedText.trim().length === 0) {
    throwError()
  }
  const selectedAndAdjacentText = new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
  const wikitext = editor.getValue()
  const rangeToHighlight = wikitextRangeForSelectedAndAdjacentText(selectedAndAdjacentText, wikitext)
  if (rangeToHighlight === null) {
    throwError()
  }
  scrollToAndHighlightRange(rangeToHighlight, editor)
}