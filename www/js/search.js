// Based on the excellent blog post: http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

// We're using a global variable to store the number of occurrences
var MyApp_SearchResultCount = 0;
var MyApp_SearchResultMatches = [];

// helper function, recursively searches in elements and their child nodes
function MyApp_HighlightAllOccurencesOfStringForElement(element,keyword) {
    if (element) {
        if (element.nodeType == 3) {        // Text node
            while (true) {
                var value = element.nodeValue;  // Search for keyword in text node
                var idx = value.toLowerCase().indexOf(keyword);
                
                if (idx < 0) break;             // not found, abort
                
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx,keyword.length));
                span.appendChild(text);
                span.setAttribute("class","MyAppHighlight");

var highlightSpanId = "find_match|" + MyApp_SearchResultCount;
span.setAttribute("id", highlightSpanId);
MyApp_SearchResultMatches.push({
                               'highlightSpanId': highlightSpanId
                               });
                
                span.style.backgroundColor="yellow";
                span.style.color="black";
                text = document.createTextNode(value.substr(idx+keyword.length));
                element.deleteData(idx, value.length - idx);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
                MyApp_SearchResultCount++;	// update the counter
            }
        } else if (element.nodeType == 1) { // Element node
            if (element.style.display != "none" && element.nodeName.toLowerCase() != 'select') {
                for (var i=element.childNodes.length-1; i>=0; i--) {
                    MyApp_HighlightAllOccurencesOfStringForElement(element.childNodes[i],keyword);
                }
            }
        }
    }
}

// helper function, recursively removes the highlights in elements and their childs
function MyApp_RemoveAllHighlightsForElement(element) {
    if (element) {
        if (element.nodeType == 1) {
            if (element.getAttribute("class") == "MyAppHighlight") {
                var text = element.removeChild(element.firstChild);
                element.parentNode.insertBefore(text,element);
                element.parentNode.removeChild(element);
                return true;
            } else {
                var normalize = false;
                for (var i=element.childNodes.length-1; i>=0; i--) {
                    if (MyApp_RemoveAllHighlightsForElement(element.childNodes[i])) {
                        normalize = true;
                    }
                }
                if (normalize) {
                    element.normalize();
                }
            }
        }
    }
    return false;
}

// the main entry point to remove the highlights
function MyApp_RemoveAllHighlights() {
    MyApp_SearchResultCount = 0;
    MyApp_SearchResultMatches = [];
    MyApp_RemoveAllHighlightsForElement(document.body);
}

// the main entry point to start the search
function MyApp_HighlightAllOccurencesOfString(keyword) {
    MyApp_RemoveAllHighlights();
    MyApp_HighlightAllOccurencesOfStringForElement(document.body, keyword.toLowerCase());
    
window.webkit.messageHandlers.searchMatchesFound.postMessage(MyApp_SearchResultMatches);
    
}

exports.MyApp_HighlightAllOccurencesOfString = MyApp_HighlightAllOccurencesOfString;
exports.MyApp_RemoveAllHighlights = MyApp_RemoveAllHighlights;
