// var sectionHeaders = require("./sectionHeaders");

/*
function scrollDownByTopMostSectionHeaderHeightIfNecessary(fragmentId){
    var header = sectionHeaders.getSectionHeaderForId(fragmentId);
    if  (header.id != fragmentId){
        window.scrollBy(0, -header.getBoundingClientRect().height);
    }
}
*/

function scrollToFragment(fragmentId){
    location.hash = '';
    location.hash = fragmentId;
    /*
    Setting location.hash scrolls the element to very top of screen. If this
    element is not a section header it will be positioned *under* the top
    static section header, so shift it down by the static section header 
    height in these cases.
    */
    //scrollDownByTopMostSectionHeaderHeightIfNecessary(fragmentId);
}

global.scrollToFragment = scrollToFragment;