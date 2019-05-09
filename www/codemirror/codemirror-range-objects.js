
class MarkupItem {
  constructor(type, innerRange, outerRange) {
    this.type = type
    this.innerRange = innerRange
    this.outerRange = outerRange
    this.buttonName = MarkupItem.buttonNameForType(type)
  }
  isComplete() {
    return this.innerRange.isComplete() && this.outerRange.isComplete()
  }
  static buttonNameForType(type) {
    if (type === 'mw-apostrophes-bold') {
      return 'bold'
    }
    if (type === 'mw-section-header') {
      return 'header'
    }
    if (type === 'mw-link-bracket') {
      return 'link'
    }
    if (type === 'mw-template-bracket') {
      return 'template'
    }
    if (type === 'mw-template-argument-name') {
      return 'template-argument'
    }
    if (type === 'mw-template-name') {
      return 'template-name'
    }
    if (type == 'mw-template-delimiter') {
      return 'template-delimiter'
    }
    if (type === 'mw-apostrophes-italic') {
      return 'italic'
    }
    if (type === 'ref') {
      return 'reference'
    }
    return type  
  }
  
  openingMarkupRange() {
    return new ItemRange(
      this.outerRange.startLocation, 
      this.innerRange.startLocation
    )
  }
  
  closingMarkupRange() {
    return new ItemRange(
      this.innerRange.endLocation, 
      this.outerRange.endLocation
    )    
  }

  innerRangeStartsOrEndsInRange(range, allowEdgeOverlap = false) {
    return this.innerRange.startsInsideRange(range, allowEdgeOverlap) || this.innerRange.endsInsideRange(range, allowEdgeOverlap)
  }
}

class ItemRange {
  constructor(startLocation, endLocation) {
    this.startLocation = startLocation
    this.endLocation = endLocation
  }
  isComplete() {
    return this.startLocation.isComplete() && this.endLocation.isComplete()
  }

  endsInsideRange(range, allowEdgeOverlap = false) {
    return allowEdgeOverlap ?
      this.endLocation.greaterThanOrEquals(range.startLocation) && this.endLocation.lessThanOrEquals(range.endLocation) :
      this.endLocation.greaterThan(range.startLocation) && this.endLocation.lessThan(range.endLocation)
  }
  
  startsInsideRange(range, allowEdgeOverlap = false) {
    return allowEdgeOverlap ? 
      this.startLocation.greaterThanOrEquals(range.startLocation) && this.startLocation.lessThanOrEquals(range.endLocation) :
      this.startLocation.greaterThan(range.startLocation) && this.startLocation.lessThan(range.endLocation)
  }

  intersectsRange(range, allowEdgeOverlap = false) {
    return (
      this.endsInsideRange(range, allowEdgeOverlap)
      ||
      this.startsInsideRange(range, allowEdgeOverlap)
      ||
      range.endsInsideRange(this, allowEdgeOverlap)
      ||
      range.startsInsideRange(this, allowEdgeOverlap)
    )
  }

  isZeroLength() {
    return this.startLocation.line === this.endLocation.line && this.startLocation.ch === this.endLocation.ch
  }
  
  lineNumbers() {
    const startLine = this.startLocation.line
    const endLine = this.endLocation.line
    return new Array(endLine - startLine + 1).fill().map((d, i) => i + startLine)
  }
}

class ItemLocation {
  constructor(line, ch) {
    this.line = line
    this.ch = ch
  }
  isComplete() {
    return this.line !== -1 && this.ch !== -1
  }
  greaterThan(location) {
    if (this.line < location.line) {
      return false
    }
    if (this.line === location.line && this.ch <= location.ch) {
      return false
    }
    return true
  }
  lessThan(location) {
    if (this.line > location.line) {
      return false
    }
    if (this.line === location.line && this.ch >= location.ch) {
      return false
    }
    return true
  }
  equals(location) {
    return (this.line === location.line && this.ch === location.ch)
  }
  greaterThanOrEquals(location) {
    return this.greaterThan(location) || this.equals(location)
  }
  lessThanOrEquals(location) {
    return this.lessThan(location) || this.equals(location)
  }
  withOffset(line, ch) {
    return new ItemLocation(this.line + line, this.ch + ch)
  }
}

exports.ItemRange = ItemRange
exports.MarkupItem = MarkupItem
exports.ItemLocation = ItemLocation
