
function getDictionaryFromSrcset(srcset) {
    /*
    Returns dictionary with density (without "x") as keys and urls as values.
    Parameter 'srcset' string:
        '//image1.jpg 1.5x, //image2.jpg 2x, //image3.jpg 3x'
    Returns dictionary:
        {1.5: '//image1.jpg', 2: '//image2.jpg', 3: '//image3.jpg'}
    */
    var sets = srcset.split(',').map(function(set) {
        return set.trim().split(' ');
    });
    var output = {};
    sets.forEach(function(set) {
        output[set[1].replace('x', '')] = set[0];
    });
    return output;
}

function firstDivAncestor (el) {
    while ((el = el.parentElement)){
        if(el.tagName === 'DIV'){
            return el;
        }
    }
    return null;
}

function firstAncestorWithMultipleChildren (el) {
    while ((el = el.parentElement) && (el.childElementCount == 1));
    return el;
}

// From: http://stackoverflow.com/a/22119674/135557
function findAncestor (el, cls) {
    while ((el = el.parentElement) && !el.classList.contains(cls));
    return el;
}

function httpGetSync(theUrl) {
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", theUrl, false );
    xmlHttp.send( null );
    return xmlHttp.responseText;
}

function isNestedInTable(el) {
    while ((el = el.parentElement)){
        if(el.tagName === 'TD'){
            return true;
        }
    }
    return false;
}

exports.getDictionaryFromSrcset = getDictionaryFromSrcset;
exports.firstDivAncestor = firstDivAncestor;
exports.firstAncestorWithMultipleChildren = firstAncestorWithMultipleChildren;
exports.findAncestor = findAncestor;
exports.httpGetSync = httpGetSync;
exports.isNestedInTable = isNestedInTable;
