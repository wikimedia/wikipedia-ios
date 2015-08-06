
function getSectionHeadersArray(){
    var nodeList = document.querySelectorAll('h1.section_heading');
    var nodeArray = Array.prototype.slice.call(nodeList);
    nodeArray = nodeArray.map(function(n){
        return {
            sectionId:n.getAttribute('sectionId'),
            text:n.textContent
        };
    });
    return nodeArray;
}

function getSectionHeaderLocationsArray(){
    var nodeList = document.querySelectorAll('h1.section_heading');
    var nodeArray = Array.prototype.slice.call(nodeList);
    nodeArray = nodeArray.map(function(n){
        return n.getBoundingClientRect().top;
    });
    return nodeArray;
}

global.getSectionHeadersArray = getSectionHeadersArray;
global.getSectionHeaderLocationsArray = getSectionHeaderLocationsArray;
