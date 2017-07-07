function updateBottomPaddingToAllowReadMoreToScrollToTop() {
  var div = document.getElementById('footer_container_dynamic_bottom_padding')
  var currentPadding = parseInt(div.style.paddingBottom)
  if (isNaN(currentPadding)) {currentPadding = 0}
  var height = div.clientHeight - currentPadding
  var newPadding = Math.max(0, window.innerHeight - height)
  div.style.paddingBottom = `${newPadding}px`
}

function updateLeftAndRightMargin(margin) {
  Array.from(document.querySelectorAll('#footer_container_menu_heading, #footer_container_readmore, #footer_container_legal'))
      .forEach(function(element) {
        element.style.marginLeft = `${margin}px`
        element.style.marginRight = `${margin}px`
      })
  var rightOrLeft = document.querySelector( 'html' ).dir == 'rtl' ? 'right' : 'left'
  Array.from(document.querySelectorAll('.footer_menu_item'))
        .forEach(function(element) {
          element.style.backgroundPosition = `${rightOrLeft} ${margin}px center`
          element.style.paddingLeft = `${margin}px`
          element.style.paddingRight = `${margin}px`
        })
}

exports.updateBottomPaddingToAllowReadMoreToScrollToTop = updateBottomPaddingToAllowReadMoreToScrollToTop
exports.updateLeftAndRightMargin = updateLeftAndRightMargin