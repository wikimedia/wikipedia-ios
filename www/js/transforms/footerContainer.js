function updateBottomPaddingToAllowReadMoreToScrollToTop() {
  var div = document.getElementById('footer_container_dynamic_bottom_padding')
  var currentPadding = parseInt(div.style.paddingBottom)
  if (isNaN(currentPadding)) {currentPadding = 0}
  var height = div.clientHeight - currentPadding
  var newPadding = Math.max(0, window.innerHeight - height)
  div.style.paddingBottom = `${newPadding}px`
}

exports.updateBottomPaddingToAllowReadMoreToScrollToTop = updateBottomPaddingToAllowReadMoreToScrollToTop