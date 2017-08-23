//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
  return str.indexOf(suffix, str.length - suffix.length) !== -1
}

exports.getImageWithSrc = function(src) {
  var images = document.getElementsByTagName('img')
  for (var i = 0; i < images.length; ++i) {
    if (stringEndsWith(images[i].src, src)) {
      return images[i]
    }
  }
  return null
}

exports.getElementRect = function(element) {
  var rect = element.getBoundingClientRect()
    // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
  return {
    Y: rect.top,
    X: rect.left,
    Width: rect.width,
    Height: rect.height
  }
}

exports.getIndexOfFirstOnScreenElement = function(elementPrefix, elementCount){
  for (var i = 0; i < elementCount; ++i) {
    var div = document.getElementById(elementPrefix + i)
    if (div === null) {
      continue
    }
    var rect = this.getElementRect(div)
    if ( rect.Y >= -1 || rect.Y + rect.Height >= 50) {
      return i
    }
  }
  return -1
}

exports.getElementFromPoint = function(x, y){
  return document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset)
}

exports.isElementTopOnscreen = function(element){
  return element.getBoundingClientRect().top < 0
}

function isElementOnscreen(element) {
  var rect = element.getBoundingClientRect()
  var windowHeight = window.innerHeight
  var bottom = rect.top + rect.height
  return rect.top > 0 && rect.top < windowHeight || bottom > 0 && bottom < windowHeight ||
    rect.top < 0 && bottom > windowHeight
}

exports.getOnScreenElementIndices = function(elementPrefix, elementCount){
  var indexFromElement = function(element) {
    return parseInt(element.id.substring(elementPrefix.length), 10)
  }
  return Array.from(document.querySelectorAll(`[id^=${elementPrefix}]`))
    .filter(isElementOnscreen)
    .map(indexFromElement)
}