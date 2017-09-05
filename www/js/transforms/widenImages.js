
const maybeWidenImage = require('wikimedia-page-library').WidenImage.maybeWidenImage

// 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
// WidenImage's maybeWidenImage code will do further checks before it widens an image.
const isGalleryImage = image => image.getAttribute('data-image-gallery') === 'true'

const widenImages = content => {
  Array.from(content.querySelectorAll('img'))
    .filter(isGalleryImage)
    .forEach(maybeWidenImage)
}

exports.widenImages = widenImages