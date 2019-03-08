
// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }

  regexForLocatingSelectedTextInWikitext(wikitext) {
    const maxAdjacentWordsToUse = 4
    const getWorkingRegexWithMostAdjacentWords = (regexGetter) => {
      for (let i = maxAdjacentWordsToUse; i > 0; i--) {
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
  codemirror.setCursor(range.to)

  let marker = null
  marker = codemirror.markText(range.from, range.to, {
    css: 'background-color: rgba(255, 204, 51, 0.4)', // Can use 'className' (vs 'css') if needed.
    clearOnEnter: true,
    inclusiveLeft: true,
    inclusiveRight: true
  })

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
  const wikitext = editor.getValue()
  const selectedAndAdjacentText = new SelectedAndAdjacentText(selectedText, textBeforeSelectedText, textAfterSelectedText)
  const rangeToHighlight = wikitextRangeForSelectedAndAdjacentText(selectedAndAdjacentText, wikitext)
  if (rangeToHighlight === null) {
    return null
  }
  scrollToAndHighlightRange(rangeToHighlight, editor)
}