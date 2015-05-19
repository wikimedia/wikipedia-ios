var transformer = require("../transformer");
var utilities = require("../utilities");

transformer.register( 'collapsePageIssuesAndDisambig', function( content ) {
    transformer.transform( "displayDisambigLink", content);
    transformer.transform( "displayIssuesLink", content);

    var issuesContainer = document.getElementById('issues_container');
    if(!issuesContainer){
        return;
    }
    issuesContainer.setAttribute( "dir", window.directionality );

    // If we have both issues and disambiguation, then insert the separator.
    var disambigBtn = document.getElementById( "disambig_button" );
    var issuesBtn = document.getElementById( "issues_button" );
    if (issuesBtn !== null && disambigBtn !== null) {
        var separator = document.createElement( 'span' );
        separator.innerText = '|';
        separator.className = 'issues_separator';
        issuesContainer.insertBefore(separator, issuesBtn.parentNode);
    }

    // Hide the container if there were no page issues or disambiguation.
    issuesContainer.style.display = (disambigBtn || issuesBtn) ? 'inherit' : 'none';
} );

transformer.register( 'displayDisambigLink', function( content ) {
    var hatnotes = content.querySelectorAll( "div.hatnote" );
    if ( hatnotes.length > 0 ) {
        var container = document.getElementById( "issues_container" );
        var wrapper = document.createElement( 'div' );
        var link = document.createElement( 'a' );
        link.setAttribute( 'href', '#disambig' );
        link.className = 'disambig_button';
        link.innerHTML = utilities.httpGetSync('wmf://localize/page-similar-titles');
        link.id = 'disambig_button';
        wrapper.appendChild( link );
        var i = 0,
            len = hatnotes.length;
        for (; i < len; i++) {
            wrapper.appendChild( hatnotes[i] );
        }
        container.appendChild( wrapper );
    }
} );

transformer.register( 'displayIssuesLink', function( content ) {
    var issues = content.querySelectorAll( "table.ambox:not([class*='ambox-multiple_issues']):not([class*='ambox-notice'])" );
    if ( issues.length > 0 ) {
        var el = issues[0];
        var container = document.getElementById( "issues_container" );
        var wrapper = document.createElement( 'div' );
        var link = document.createElement( 'a' );
        link.setAttribute( 'href', '#issues' );
        link.className = 'issues_button';
        link.innerHTML = utilities.httpGetSync('wmf://localize/page-issues');
        link.id = 'issues_button';
        wrapper.appendChild( link );
        el.parentNode.replaceChild( wrapper, el );
        var i = 0,
            len = issues.length;
        for (; i < len; i++) {
            wrapper.appendChild( issues[i] );
        }
        container.appendChild( wrapper );
    }
} );

function collectDisambig( sourceNode ) {
    var res = [];
    var links = sourceNode.querySelectorAll( 'div.hatnote a' );
    var i = 0,
        len = links.length;
    for (; i < len; i++) {
        // Pass the href; we'll decode it into a proper page title in Obj-C
        if(links[i].getAttribute( 'href' ).indexOf("redlink=1") === -1){
            res.push( links[i] );
        }
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

function anchorForAnchor(anchor) {
    var url = anchor.getAttribute( 'href' );
    var titleForDisplay = anchor.text.substring(0,1).toUpperCase() + anchor.text.substring(1);
    return '<a class="ios-disambiguation-item-anchor" href="' + url + '" >' + titleForDisplay + '</a>';
}

function divForIssue(issue) {
    return '<div class="ios-issue-item">' + issue + '</div>';
}

function insertAfter(newNode, referenceNode) {
    referenceNode.parentNode.insertBefore(newNode, referenceNode.nextSibling);
}

function setIsSelected(el, isSelected) {
    if(isSelected){
        el.style.borderBottom = "1px dotted #bbb;";
        el.style.color = '#000';
    }else{
        el.style.borderBottom = "none";
        el.style.color = '#777';
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
    var closeButton = document.getElementById('issues_container_close_button');
    if(containerToRemove){
        containerToRemove.parentNode.removeChild(containerToRemove);
    }
    var containerToAddOrToggle = document.getElementById( activeSubContainerId );
    if(containerToAddOrToggle){
        containerToAddOrToggle.parentNode.removeChild(containerToAddOrToggle);
        closeButton.style.display = 'none';
    }else{
        containerToAddOrToggle = document.createElement( 'div' );
        containerToAddOrToggle.id = activeSubContainerId;
        containerToAddOrToggle.innerHTML = activeSubContainerContents;
        insertAfter(containerToAddOrToggle, document.getElementById('issues_container'));
        closeButton.style.display = 'inherit';
    }
}

function closeClicked() {
    if(document.getElementById( 'disambig_sub_container' )){
        toggleSubContainers('disambig_sub_container', 'issues_sub_container', null);
        toggleSubContainerButtons('disambig_sub_container', 'disambig_button', 'issues_button');
    }else if(document.getElementById( 'issues_sub_container' )){
        toggleSubContainers('issues_sub_container', 'disambig_sub_container', null);
        toggleSubContainerButtons('issues_sub_container', 'issues_button', 'disambig_button');
    }
}

function issuesClicked( sourceNode ) {
    var issues = collectIssues( sourceNode.parentNode );
    var disambig = collectDisambig( sourceNode.parentNode.parentNode ); // not clicked node

    toggleSubContainers('issues_sub_container', 'disambig_sub_container',  issues.map(divForIssue).join( "" ));
    toggleSubContainerButtons('issues_sub_container', 'issues_button', 'disambig_button');

    return { "hatnotes": disambig, "issues": issues };
}

function disambigClicked( sourceNode ) {
    var disambig = collectDisambig( sourceNode.parentNode );
    var issues = collectIssues( sourceNode.parentNode.parentNode ); // not clicked node

    toggleSubContainers('disambig_sub_container', 'issues_sub_container', disambig.map(anchorForAnchor).sort().join( "" ));
    toggleSubContainerButtons('disambig_sub_container', 'disambig_button', 'issues_button');

    return { "hatnotes": disambig, "issues": issues };
}

exports.issuesClicked = issuesClicked;
exports.disambigClicked = disambigClicked;
exports.closeClicked = closeClicked;
