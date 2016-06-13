//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

function getZoomLevel() {
    // From: http://stackoverflow.com/a/5078596/135557
    var deviceWidth = (Math.abs(window.orientation) === 90) ? screen.height : screen.width;
    var zoom = deviceWidth / window.innerWidth;
    return zoom;
}

exports.getImageWithSrc = function(src) {
    var images = document.getElementsByTagName('img');
    for (var i = 0; i < images.length; ++i) {
        if (stringEndsWith(images[i].src, src)) {
            return images[i];
        }
    }
    return null;
};

exports.getElementRect = function(element) {
    var rect = element.getBoundingClientRect();
    var zoom = getZoomLevel();
    // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
    var zoomedRect = {
        Y: rect.top * zoom,
        X: rect.left * zoom,
        Width: rect.width * zoom,
        Height: rect.height * zoom
    };
    return zoomedRect;
};

exports.getIndexOfFirstOnScreenElement = function(elementPrefix, elementCount){
    for (var i = 0; i < elementCount; ++i) {
        var div = document.getElementById(elementPrefix + i);
        if (div === null) {
            continue;
        }
        var rect = this.getElementRect(div);
        if ( (rect.Y >= -1) || ((rect.Y + rect.Height) >= 50)) {
            return i;
        }
    }
    return -1;
};

exports.getElementFromPoint = function(x, y){
    return document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset);
};

exports.getURLForElementAtPoint = function (x, y){
    return this.getElementFromPoint(x, y).href;
};

