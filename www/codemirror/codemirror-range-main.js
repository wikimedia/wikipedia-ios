const RangeHelper = {}

RangeHelper.rangeDebugging = require('./codemirror-range-debugging')
RangeHelper.rangeDetermination = require('./codemirror-range-determination')
RangeHelper.rangeObjects = require('./codemirror-range-objects')
RangeHelper.rangeUtilities = require('./codemirror-range-utilities')
RangeHelper.rangeClearFormatting = require('./codemirror-range-clear-formatting')
RangeHelper.getMarkupItemsIntersectingSelection = require('./codemirror-range-utilities').getMarkupItemsIntersectingSelection
RangeHelper.getItemRangeFromSelection = require('./codemirror-range-utilities').getItemRangeFromSelection
RangeHelper.markupItemsForItemRangeLines = require('./codemirror-range-determination').markupItemsForItemRangeLines


window.RangeHelper = RangeHelper