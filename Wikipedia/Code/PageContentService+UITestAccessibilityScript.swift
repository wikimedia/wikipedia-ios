import WebKit

#if TEST || UITEST
extension PageContentService {
    /// Adds stable accessibility labels to article web content so UI tests can target elements rendered inside the page.
    final class UITestAccessibilityScript: PageUserScript {
        private static let source = """
            (function () {
                const labels = {
                    articleLink: "Article Link Canis",
                    nonLeadImage: "Article Non-Lead Image",
                    quickFactsTable: "Article Quick Facts Table",
                    quickFactsTableItem: "Article Quick Facts Table Link",
                    aboutThisArticleItem: "Article About This Article Item",
                    licenseLink: "Article License Link"
                };
                const marker = "data-wmf-uitest-accessibility-label";

                function setAccessibility(element, label) {
                    if (!element || element.getAttribute(marker) === label) {
                        return;
                    }

                    element.setAttribute(marker, label);
                    element.setAttribute("aria-label", label);
                }

                function textIncludes(element, text) {
                    return element && element.textContent && element.textContent.trim().indexOf(text) !== -1;
                }

                function annotate() {
                    const canisArticleLink = Array.from(document.querySelectorAll('a[href="./Canis"][title="Canis"]'))
                        .find((element) => !element.closest("table"));
                    setAccessibility(canisArticleLink, labels.articleLink);

                    const nonLeadImage = Array.from(document.querySelectorAll('a[href^="./File:"] img, a[href^="./File:"] span.pcs-lazy-load-placeholder'))
                        .find((element) => !element.closest("table") && !element.closest(".pcs-collapse-table-container") && !element.closest("header"));
                    setAccessibility(nonLeadImage, labels.nonLeadImage);

                    const quickFactsTable = document.querySelector(".pcs-collapse-table-container .pcs-collapse-table-collapsed-container");
                    setAccessibility(quickFactsTable, labels.quickFactsTable);

                    const quickFactsTableItem = document.querySelector('.pcs-collapse-table-container table a[href="./Canis"]');
                    setAccessibility(quickFactsTableItem, labels.quickFactsTableItem);

                    const footerItems = Array.from(document.querySelectorAll("#pcs-footer-container-menu-items *"));
                    const editHistoryText = footerItems.find((element) => textIncludes(element, "View edit history"));
                    const editHistoryItem = editHistoryText ? editHistoryText.closest("a") || editHistoryText.closest(".pcs-footer-menu-item") || editHistoryText : null;
                    setAccessibility(editHistoryItem, labels.aboutThisArticleItem);

                    const licenseLink = document.querySelector("#pcs-footer-container-legal a");
                    setAccessibility(licenseLink, labels.licenseLink);
                }

                function scheduleAnnotate() {
                    window.requestAnimationFrame(function () {
                        annotate();
                        window.setTimeout(annotate, 250);
                    });
                }

                if (document.readyState === "loading") {
                    document.addEventListener("DOMContentLoaded", scheduleAnnotate);
                } else {
                    scheduleAnnotate();
                }

                if (!window.wmfUITestAccessibilityObserver) {
                    window.wmfUITestAccessibilityObserver = new MutationObserver(scheduleAnnotate);
                    window.wmfUITestAccessibilityObserver.observe(document.documentElement, {
                        childList: true,
                        subtree: true
                    });
                }
            }());
            """

        init() {
            super.init(source: UITestAccessibilityScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
}
#endif
