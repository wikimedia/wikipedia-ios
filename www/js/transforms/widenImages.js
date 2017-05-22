
const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

const isGalleryImage = function(image) {
  // 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
  // WidenImage's maybeWidenImage code will do further checks before it widens an image.
  return image.getAttribute('data-image-gallery') === 'true'    
}

function widenImages(content) {
  Array.from(content.querySelectorAll('img'))
    .filter(isGalleryImage)
    .forEach(maybeWidenImage)
}

exports.widenImages = widenImages