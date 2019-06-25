
// Reminder: after we start using broswerify for code mirror bits DRY this up with the `SelectedAndAdjacentText` class in `editTextSelection.js`
class SelectedAndAdjacentText {
  constructor(selectedText, textBeforeSelectedText, textAfterSelectedText) {
    this.selectedText = selectedText
    this.textBeforeSelectedText = textBeforeSelectedText
    this.textAfterSelectedText = textAfterSelectedText
  }
}

const getNumberOfWordsFromBeginningOfString = (string, wordCount) => string.split(' ').slice(0, wordCount)
const getNumberOfWordsFromEndOfString = (string, wordCount) => string.split(' ').slice(-wordCount)

const calculateScore = (wordsFromHTML, wordsFromWikitext) => wordsFromHTML.reduce((score, htmlWord, htmlWordIndex) => {
  const indexOfHTMLWordInWikitextWords = wordsFromWikitext.indexOf(htmlWord);
  const distance = indexOfHTMLWordInWikitextWords - htmlWordIndex; 
  const wordScore = indexOfHTMLWordInWikitextWords === -1 ? 0 : (wordsFromWikitext.length - htmlWordIndex - distance);
  return score + wordScore 
}, 0) 

const wordsOnly = string => string.replace(/\(.*?\)/g, '').replace(/{{.*}}/g, '').replace(/\W+/g, ' ').trim()
const adjacentComparisonWordCount = 6
const adjacentCharsToGather = 200

const scoreForMatch = (match, lastIndex, wordsBeforeFromHTML, wordsAfterFromHTML) => {
  const wordsBeforeFromWikitext = getNumberOfWordsFromEndOfString(wordsOnly(match.input.substring(Math.max(0, match.index - adjacentCharsToGather), match.index)), adjacentComparisonWordCount)
  const wordsAfterFromWikitext = getNumberOfWordsFromBeginningOfString(wordsOnly(match.input.substring(lastIndex, lastIndex + adjacentCharsToGather)), adjacentComparisonWordCount)
  const wordsAfterScore = calculateScore(wordsAfterFromHTML, wordsAfterFromWikitext)
  const wordsBeforeScore = calculateScore(wordsBeforeFromHTML.slice().reverse(), wordsBeforeFromWikitext.slice().reverse())
  return wordsBeforeScore + wordsAfterScore
}

const wikitextRangeForSelectedAndAdjacentText = (selectedAndAdjacentText, wikitext) => {
  const wordsBeforeFromHTML = getNumberOfWordsFromEndOfString(selectedAndAdjacentText.textBeforeSelectedText, adjacentComparisonWordCount)
  const wordsAfterFromHTML = getNumberOfWordsFromBeginningOfString(selectedAndAdjacentText.textAfterSelectedText, adjacentComparisonWordCount)
  const selectedTextRegexPattern = `(${selectedAndAdjacentText.selectedText.replace(/\s+/g, '(?:(?:\\[\\[[^\\]\\|]+\\|)|{{[^}]*}}|<[^>]*>|\\W)+')})`
  const selectedTextRegex = new RegExp(selectedTextRegexPattern, 'gs')

  let bestScoredMatch = null
  while ((match = selectedTextRegex.exec(wikitext)) !== null) {
    const thisMatchScore = scoreForMatch(match, selectedTextRegex.lastIndex, wordsBeforeFromHTML, wordsAfterFromHTML)
    if (bestScoredMatch === null || thisMatchScore > bestScoredMatch.score) {
      bestScoredMatch = {
        match, 
        score: thisMatchScore,
        matchedWikitextBeforeSelection: {start: 0, end: match.index},
        matchedWikitextSelection: {start: match.index, end: selectedTextRegex.lastIndex}
      }    
    }
  }

  if (bestScoredMatch === null) {
    return null
  }

  const matchedWikitextBeforeSelection = bestScoredMatch.match.input.substring(bestScoredMatch.matchedWikitextBeforeSelection.start, bestScoredMatch.matchedWikitextBeforeSelection.end)
  const matchedWikitextSelection = bestScoredMatch.match.input.substring(bestScoredMatch.matchedWikitextSelection.start, bestScoredMatch.matchedWikitextSelection.end)

  return getWikitextRangeToSelect(matchedWikitextBeforeSelection, matchedWikitextSelection)
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

  // Calling `setSelection` triggers our codemirror `cursorActivity` event, which will call our
  // scrolling code as needed.
  editor.setSelection(rangeToHighlight.from, rangeToHighlight.to, {scroll: false})
}