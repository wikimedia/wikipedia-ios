const leadImage = pcs.c1.Page.getLeadImage();
window.webkit.messageHandlers.{{messageHandlerName}}.postMessage({action: 'leadImage', data: {leadImage}});
const tableOfContents = pcs.c1.Page.getTableOfContents();
if (tableOfContents) {
    window.webkit.messageHandlers.{{messageHandlerName}}.postMessage({action: 'tableOfContents', data: {tableOfContents}});
}
