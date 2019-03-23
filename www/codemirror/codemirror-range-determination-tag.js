const ItemRange = require('./codemirror-range-objects').ItemRange
const MarkupItem = require('./codemirror-range-objects').MarkupItem
const ItemLocation = require('./codemirror-range-objects').ItemLocation

const isTokenForTagBracket = (token) => tokenIncludesType(token, 'mw-htmltag-bracket') || tokenIncludesType(token, 'mw-exttag-bracket')
const isTokenStartOfOpenTag = (token) => isTokenForTagBracket(token) && token.string === '<'
const isTokenEndOfOpenTag = (token) => isTokenForTagBracket(token) && token.string === '>'  
const isTokenStartOfCloseTag = (token) => isTokenForTagBracket(token) && token.string === '</'  

const getOpenTagStartTokenIndices = (lineTokens) => {
  let openTagStartTokenIndices = []
  const possiblyRecordOpenTagTokenIndex = (token, index) => {
    if (isTokenStartOfOpenTag(token)) {
      openTagStartTokenIndices.push(index)
    }
  }
  lineTokens.forEach(possiblyRecordOpenTagTokenIndex)
  return openTagStartTokenIndices
}

const getOpenTagEndTokenIndices = (lineTokens, openTagStartTokenIndices) => {
  const getOpenTagEndTokenIndex = (openTagStartTokenIndex) => {
    return lineTokens.findIndex((t, i) => {
      return i > openTagStartTokenIndex && isTokenEndOfOpenTag(t)
    })
  }
  return openTagStartTokenIndices.map(getOpenTagEndTokenIndex)
}

const tagMarkupItemsForLineTokens = (lineTokens, line) => {
  const openTagStartTokenIndices = getOpenTagStartTokenIndices(lineTokens)    
  const tagTypeTokenIndices = openTagStartTokenIndices.map(i => i + 1)
  const openTagEndTokenIndices = getOpenTagEndTokenIndices(lineTokens, openTagStartTokenIndices)

  const closeTagStartTokenIndices = getCloseTagStartTokenIndices(lineTokens, openTagEndTokenIndices)    
  const closeTagEndTokenIndices = closeTagStartTokenIndices.map(i => i + 2)

  let output = []
  const tagCount = openTagStartTokenIndices.length
  
  for (let i = 0; i < tagCount; i++) { 
    const openTagStartTokenIndex = openTagStartTokenIndices[i]
    const tagTypeTokenIndex = tagTypeTokenIndices[i]
    const openTagEndTokenIndex = openTagEndTokenIndices[i]
    const closeTagStartTokenIndex = closeTagStartTokenIndices[i]
    const closeTagEndTokenIndex = closeTagEndTokenIndices[i]

    if (
      openTagStartTokenIndex === undefined ||
      tagTypeTokenIndex === undefined ||
      openTagEndTokenIndex === undefined ||
      closeTagStartTokenIndex === undefined ||
      closeTagEndTokenIndex === undefined
    ) {
      continue
    }

    let outer = new ItemRange(new ItemLocation(line, lineTokens[openTagStartTokenIndex].start), new ItemLocation(line, lineTokens[closeTagEndTokenIndex].end))
    let inner = new ItemRange(new ItemLocation(line, lineTokens[openTagEndTokenIndex].end), new ItemLocation(line, lineTokens[closeTagStartTokenIndex].start))
    let type = lineTokens[tagTypeTokenIndex].string.trim()
    output.push(new MarkupItem(type, inner, outer))
  }
  return output
}

const getCloseTagStartTokenIndices = (lineTokens, openTagEndTokenIndices) => {
  let closeTagStartTokenIndices = []
  
  openTagEndTokenIndices.forEach(openTagEndTokenIndex => {
    let depth = 0
    for (let i = openTagEndTokenIndex + 1; i < lineTokens.length; i++) { 
      let thisToken = lineTokens[i]
      if (isTokenStartOfOpenTag(thisToken)){
        depth = depth + 1
      } else if (isTokenStartOfCloseTag(thisToken)) {
        if (depth === 0) {
          closeTagStartTokenIndices.push(i)
          break
        }
        depth = depth - 1        
      }
    }
    
  })
  
  return closeTagStartTokenIndices
}

exports.tagMarkupItemsForLineTokens = tagMarkupItemsForLineTokens
