var bridge = require("./bridge");

function collectDisambig( sourceNode ) {
    var res = [];
    var links = sourceNode.querySelectorAll( 'div.hatnote a' );
    var i = 0,
        len = links.length;
    for (; i < len; i++) {
        // Pass the href; we'll decode it into a proper page title in Obj-C
        res.push( links[i].getAttribute( 'href' ) );
    }
    return res;
}

function collectIssues( sourceNode ) {
    var res = [];
    var issues = sourceNode.querySelectorAll( 'table.ambox' );
    var i = 0,
        len = issues.length;
    for (; i < len; i++) {
        // .ambox- is used e.g. on eswiki
        res.push( issues[i].querySelector( '.mbox-text, .ambox-text' ).innerHTML );
    }
    return res;
}

function anchorForUrl(url) {
    var titleForDisplay = decodeURIComponent(url);
    titleForDisplay = (titleForDisplay.indexOf('/wiki/') === 0) ? titleForDisplay.substring(6) : titleForDisplay;
    titleForDisplay = titleForDisplay.split('_').join(' ');
    return '<a class="ios-disambiguation-anchor" href="' + url + '" >' + titleForDisplay + '</a>';
}

function insertAfter(newNode, referenceNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

function setIsSelected(el, isSelected) {
    if(isSelected){
        el.style.borderBottom = "1px dotted #ccc";
    }else{
        el.style.borderBottom = "none";
    }
}

function toggleSubContainerButtons( activeSubContainerId, focusButtonId, blurButtonId ){
    var buttonToBlur = document.getElementById( blurButtonId );
    if(buttonToBlur) {
        setIsSelected(buttonToBlur, false);
    }
    var buttonToActivate = document.getElementById( focusButtonId );
    var isActiveSubContainerPresent = document.getElementById( activeSubContainerId ) ? true : false;
    setIsSelected(buttonToActivate, isActiveSubContainerPresent);
}

function toggleSubContainers( activeSubContainerId, inactiveSubContainerId, activeSubContainerContents ){
    var containerToRemove = document.getElementById( inactiveSubContainerId );
    if(containerToRemove){
        containerToRemove.parentNode.removeChild(containerToRemove);
    }
    var containerToAddOrToggle = document.getElementById( activeSubContainerId );
    if(containerToAddOrToggle){
        containerToAddOrToggle.parentNode.removeChild(containerToAddOrToggle);
    }else{
        containerToAddOrToggle = document.createElement( 'div' );
        containerToAddOrToggle.id = activeSubContainerId;
        containerToAddOrToggle.innerHTML = activeSubContainerContents;
        insertAfter(containerToAddOrToggle, document.getElementById('issues_container'));
    }
}

function issuesClicked( sourceNode ) {
    var issues = collectIssues( sourceNode.parentNode );
    var disambig = collectDisambig( sourceNode.parentNode.parentNode ); // not clicked node
    bridge.sendMessage( 'issuesClicked', { "hatnotes": disambig, "issues": issues } );

    toggleSubContainers('issues_sub_container', 'disambig_sub_container', issues);
    toggleSubContainerButtons('issues_sub_container', 'issues_button', 'disambig_button');
}

function disambigClicked( sourceNode ) {
    var disambig = collectDisambig( sourceNode.parentNode );
    var issues = collectIssues( sourceNode.parentNode.parentNode ); // not clicked node
    bridge.sendMessage( 'disambigClicked', { "hatnotes": disambig, "issues": issues } );

    toggleSubContainers('disambig_sub_container', 'issues_sub_container', disambig.sort().map(anchorForUrl).join( "" ));
    toggleSubContainerButtons('disambig_sub_container', 'disambig_button', 'issues_button');
}

exports.issuesClicked = issuesClicked;
exports.disambigClicked = disambigClicked;
