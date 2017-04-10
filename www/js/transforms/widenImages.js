
const transformer = require('../transformer');
const maybeWidenImage = require('applib').WidenImage.maybeWidenImage;

const isGalleryImage = function(image) {
  // 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
  // WidenImage's maybeWidenImage code will do further checks before it widens an image.
  return (image.getAttribute('data-image-gallery') === 'true');    
};

transformer.register('widenImages', function(content) {
  Array.from(content.querySelectorAll('img'))
    .filter(isGalleryImage)
    .forEach(maybeWidenImage);
});
