import WebKit

#if TEST || UITEST
extension PageContentService {
    /// Adds stable accessibility labels to article web content so UI tests can target elements rendered inside the page.
    final class UITestAccessibilityScript: PageUserScript {
        private static let source: String = {
            guard let configuration = try? PageContentService.getJavascriptFor(UITestAccessibilityConfiguration.script) else {
                return ""
            }

            return """
            (function () {
                const marker = "data-wmf-uitest-accessibility-label";
                const configuration = \(configuration);
                const labels = configuration.labels;
                const strings = configuration.localizedStrings;
                const languageCode = currentLanguageCode();
                const targets = configuration.localizedTargets[languageCode] || configuration.localizedTargets.en;

                function currentLanguageCode() {
                    const htmlLanguage = document.documentElement.getAttribute("lang");
                    const pcsLocale = document.querySelector('meta[property="pcs:locale"]');
                    const language = htmlLanguage || (pcsLocale ? pcsLocale.getAttribute("content") : null) || "en";
                    return language.split("-")[0];
                }

                function setAccessibility(element, label) {
                    if (!element || element.getAttribute(marker) === label) {
                        return;
                    }

                    element.setAttribute(marker, label);
                    element.setAttribute("aria-label", label);
                }

                function setDirectAccessibility(element, label) {
                    if (!element) {
                        return;
                    }

                    element.removeAttribute("aria-labelledby");
                    setAccessibility(element, label);
                }

                function textIncludes(element, text) {
                    return element && element.textContent && element.textContent.trim().indexOf(text) !== -1;
                }

                function allElements(selector) {
                    return Array.from(document.querySelectorAll(selector));
                }

                function matchesArticleLink(element) {
                    return element && (
                        element.getAttribute("href") === targets.articleHref ||
                        element.getAttribute("title") === targets.articleTitle
                    );
                }

                function articleLinks() {
                    return allElements("a").filter(matchesArticleLink);
                }

                function hasTableAncestor(element) {
                    return element.closest(".pcs-collapse-table-container") || element.closest("table");
                }

                function isNonLeadImageLink(element) {
                    return element.querySelector("img, span.pcs-lazy-load-placeholder") &&
                        !hasTableAncestor(element) &&
                        !element.closest("header");
                }

                function articleLink(links) {
                    if (targets.articleLinkInQuickFacts) {
                        return links.find(hasTableAncestor);
                    }

                    return links.find((element) => !element.closest("table"));
                }

                function nonLeadImage() {
                    return document.querySelector('a[href="' + targets.nonLeadImageHref + '"]') || allElements("a.mw-file-description")
                        .find(isNonLeadImageLink);
                }

                function quickFactsTableItem(links) {
                    if (targets.articleLinkInQuickFacts) {
                        return null;
                    }

                    return links.find((element) => element.closest(".pcs-collapse-table-container table"));
                }

                function quickFactsTable() {
                    const collapsedContainer = document.querySelector(".pcs-collapse-table-collapsed-container");
                    if (collapsedContainer) {
                        collapsedContainer.setAttribute("role", "button");
                        return collapsedContainer;
                    }

                    return document.querySelector(".pcs-collapse-table-container [role='button']");
                }

                function editSectionLabel() {
                    return document.querySelector('meta[property="mw:pageProtection:edit"]') ? labels.protectedEditIcon : labels.unprotectedEditIcon;
                }

                function aboutThisArticleItem() {
                    const lastEditedItem = document.querySelector("#pcs-footer-container-menu-items .pcs-footer-menu-icon-last-edited a");
                    if (lastEditedItem) {
                        return lastEditedItem;
                    }

                    const footerItems = allElements("#pcs-footer-container-menu-items a, #pcs-footer-container-menu-items *");
                    const editHistoryText = footerItems.find((element) => textIncludes(element, strings.viewEditHistory));
                    const editHistoryLink = footerItems.find((element) => {
                        const href = element.getAttribute("href") || "";
                        return href.indexOf("action=history") !== -1 || href.indexOf("Special:History") !== -1;
                    });

                    return editHistoryLink || (editHistoryText ? editHistoryText.closest("a") || editHistoryText.closest(".pcs-footer-menu-item") || editHistoryText : null);
                }

                function annotate() {
                    const links = articleLinks();
                    setAccessibility(articleLink(links), labels.articleLink);
                    setAccessibility(nonLeadImage(), labels.nonLeadImage);
                    setAccessibility(quickFactsTable(), labels.quickFactsTable);
                    setAccessibility(quickFactsTableItem(links), labels.quickFactsTableItem);
                    setDirectAccessibility(document.querySelector('a.pcs-edit-section-link[data-action="edit_section"]'), editSectionLabel());
                    setAccessibility(aboutThisArticleItem(), labels.aboutThisArticleItem);
                    setAccessibility(document.querySelector("#pcs-footer-container-legal a"), labels.licenseLink);
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
        }()

        init() {
            super.init(source: UITestAccessibilityScript.source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        }
    }
}
#endif
