
const intersection = (a, b) => new Set([...a].filter(x => b.has(x)))
const difference = (a, b) => new Set([...a].filter(x => !b.has(x)))
const union = (a, b) => new Set([...a, ...b])

exports.intersection = intersection
exports.difference = difference
exports.union = union
