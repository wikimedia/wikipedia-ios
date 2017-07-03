
function sendMediaWithTarget(target) {
  window.webkit.messageHandlers.mediaClicked.postMessage({'media':target.alt})
}

function handleMediaClickEvent(event){
  const target = event.target;
  if(!target) {
    return
  }
  const file = target.getAttribute('alt');
  if(!file) {
    return
  }
  sendMediaWithTarget(target)
}

function install() {
  Array.prototype.slice.call(document.querySelectorAll('img[alt^="File:"],[alt$=".ogv"]')).forEach(function(element){
    element.addEventListener('click',function(event){
      event.preventDefault();
      handleMediaClickEvent(event)
    },false)
  })
}

exports.install = install;
