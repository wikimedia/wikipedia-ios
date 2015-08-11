
var _topElement = null;
var _preRotationOffsetY = null;

function setPreRotationRelativeScrollOffset() {
    _topElement = document.elementFromPoint( window.innerWidth / 2, 0 );
    if (_topElement) {
        var rect = _topElement.getBoundingClientRect();
        _preRotationOffsetY = rect.top / rect.height;
    } else {
        _preRotationOffsetY = null;
    }
}

function getPostRotationScrollOffset() {
    if (_topElement && (_preRotationOffsetY !== null)) {
        var rect = _topElement.getBoundingClientRect();
        _topElement = null;
        return (window.scrollY + rect.top) - (_preRotationOffsetY * rect.height);
    } else {
        _topElement = null;
        return 0;
    }
}

global.setPreRotationRelativeScrollOffset = setPreRotationRelativeScrollOffset;
global.getPostRotationScrollOffset = getPostRotationScrollOffset;
