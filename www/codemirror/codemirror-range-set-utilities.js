
// See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set

// Returns set containing items that exist in both sets.
const intersection = (a, b) => new Set([...a].filter(x => b.has(x)))

// Returns set containing items that exist only in the first set and not in both sets.
const difference = (a, b) => new Set([...a].filter(x => !b.has(x)))

// Returns set containing all items from both sets, without dupes.
const union = (a, b) => new Set([...a, ...b])

// Returns true if all items set b are in set a.
const isSuperset = (a, b) => {
  for (let e of b) {
    if (!a.has(e)) {
      return false
    }
  }
  return true
}

// Returns set containing all items from both sets, except items that are present in both sets.
const symmetricDifference = (a, b) => {
  let diff = new Set(a)
  for (let e of b) {
    if (diff.has(e)) {
      diff.delete(e)
    } else {
      diff.add(e)
    }
  }
  return diff
}

exports.intersection = intersection
exports.difference = difference
exports.union = union
exports.isSuperset = isSuperset
exports.symmetricDifference = symmetricDifference
