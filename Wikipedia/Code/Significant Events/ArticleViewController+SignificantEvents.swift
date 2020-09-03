

import Foundation

extension ArticleViewController {
    func injectSignificantEventsContent(_ completion: (() -> Void)? = nil) {
        let significantEventsBoxHTML = "<div id='significant-changes-container'><div id='significant-changes-inner-container'><h4 id='significant-changes-header'>RECENT CHANGES</h4><ul id='significant-changes-list'><li id='significant-changes-first-list'><p class='significant-changes-timestamp'>3 minutes ago</p><p class='significant-changes-description'>Reference added in Epedimology section</p><p class='significant-changes-userInfo'>Edited by <a href='./wiki/User:Pixiu'>Pixiu</a> (1795 edits)</p></li><li id='significant-changes-list'><p class='significant-changes-timestamp'>8 minutes ago</p><p class='significant-changes-description'>New discussion about this article</p><p class='significant-changes-userInfo'>Edited by <a href='./wiki/User:Pixiu'>MushroomCat</a> (7349 edits)</p></li></ul><hr id='significant-changes-hr'><p id='significant-changes-read-more'>Read more updates</p></div></div>"
        let javascript = """
            function pleaseWork() {
                 var sections = document.getElementById('pcs').getElementsByTagName('section');
                 if (sections.length === 0) {
                     return false;
                 }
                 var firstSection = sections[0];
                 var pTags = firstSection.getElementsByTagName('p');
                 if (pTags.length === 0) {
                     return false;
                 }
                 var button = document.createElement('BUTTON');
                 button.innerHTML = "CLICK ME";
                 var firstParagraph = pTags[0];
                 firstParagraph.insertAdjacentHTML("afterend","\(significantEventsBoxHTML)");
                 return true;
            }
            pleaseWork();
        """
        webView.evaluateJavaScript(javascript) { (result, error) in
            print(result)
            print(error)
        }
    }
}
