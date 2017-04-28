
var _saveButtonClickHandler = null;
var _clickHandler = null;
var _titlesShownHandler = null;
var _saveForLaterString = null;
var _savedForLaterString = null;
var _saveButtonIDPrefix = 'readmore:save:';
var _readMoreContainer = null;

var shownTitles = [];

function safelyRemoveEnclosures(string, opener, closer) {
  const enclosureRegex = new RegExp(`\\s?[${opener}][^${opener}${closer}]+[${closer}]`, 'g');
  var previousString = null;
  var counter = 0;
  const safeMaxTries = 30;
  do {
    previousString = string;
    string = string.replace(enclosureRegex, '');
    counter++;
  } while (previousString !== string && counter < safeMaxTries);
  return string;
}

function cleanExtract(string){
  string = safelyRemoveEnclosures(string, '(', ')');
  string = safelyRemoveEnclosures(string, '/', '/');
  return string;
}

class WMFPage {
    constructor(title, thumbnail, terms, extract) {
        this.title = title;
        this.thumbnail = thumbnail;
        this.terms = terms;
        this.extract = extract;
    }
}

class WMFPageFragment {
    constructor(wmfPage, index) {
      
        var page = document.createElement('div');
        page.id = index;
        page.className = 'footer_readmore_page';        
      
        var hasImage = wmfPage.thumbnail && wmfPage.thumbnail.source;  
        if(hasImage){
          var image = document.createElement('div');
          image.style.backgroundImage = `url(${wmfPage.thumbnail.source})`;
          image.classList.add('footer_readmore_page_image');
          page.appendChild(image);
        }
        
        var container = document.createElement('div');
        container.classList.add('footer_readmore_page_container');
        page.appendChild(container);

        page.addEventListener('click', function(){
          _clickHandler(`/wiki/${encodeURI(wmfPage.title)}`);
        }, false);

        if(wmfPage.title){
            var title = document.createElement('div');
            title.id = index;
            title.className = 'footer_readmore_page_title';
            title.innerHTML = wmfPage.title.replace(/_/g, ' ');
            container.appendChild(title);
        }

        var description = null;
        if(wmfPage.terms){
          description = wmfPage.terms.description;
        }        
        if((description === null || description.length < 10) && wmfPage.extract){
          description = cleanExtract(wmfPage.extract);
        }
        if(description){
            var descriptionEl = document.createElement('div');
            descriptionEl.id = index;
            descriptionEl.className = 'footer_readmore_page_description';
            descriptionEl.innerHTML = description;
            container.appendChild(descriptionEl);
        }

        var saveButton = document.createElement('div');
        saveButton.id = `${_saveButtonIDPrefix}${encodeURI(wmfPage.title)}`;
        saveButton.innerText = 'Save for later';
        saveButton.className = 'footer_readmore_page_save';
        saveButton.addEventListener('click', function(event){
          _saveButtonClickHandler(wmfPage.title);
          event.stopPropagation();
          event.preventDefault();
        }, false);
        container.appendChild(saveButton);

        return document.createDocumentFragment().appendChild(page);
    }
}

function showReadMore(pages){  
  shownTitles.length = 0;
  
  pages.forEach(function(page, index){

    const title = page.title.replace(/ /g, '_');
    shownTitles.push(title);

    const pageModel = new WMFPage(title, page.thumbnail, page.terms, page.extract);
    const pageFragment = new WMFPageFragment(pageModel, index);
    _readMoreContainer.appendChild(pageFragment);
  });
  
  _titlesShownHandler(shownTitles);
}

// Leave 'baseURL' null if you don't need to deal with proxying.
function fetchReadMore(baseURL, title, showReadMoreHandler) {
    var xhr = new XMLHttpRequest();
    if (baseURL === null) {
      baseURL = '';
    }
    
    const pageCountToFetch = 3;
    const params = {
      action: 'query',
      continue: '',
      exchars: 256,
      exintro: 1,
      exlimit: pageCountToFetch,
      explaintext: '',
      format: 'json',
      generator: 'search',
      gsrinfo: '',
      gsrlimit: pageCountToFetch,
      gsrnamespace: 0,
      gsroffset: 0,
      gsrprop: 'redirecttitle',
      gsrsearch: `morelike:${title}`,
      gsrwhat: 'text',
      ns: 'ppprop',
      pilimit: pageCountToFetch,
      piprop: 'thumbnail',
      pithumbsize: 120,
      prop: 'pageterms|pageimages|pageprops|revisions|extracts',
      rrvlimit: 1,
      rvprop: 'ids',
      wbptterms: 'description',
      formatversion: 2
    };

    const paramsString = Object.keys(params)
      .map(function(key){
        return `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`;
      })
      .join('&');
    
    xhr.open('GET', `${baseURL}/w/api.php?${paramsString}`, true);
    xhr.onload = function() {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
            showReadMoreHandler(JSON.parse(xhr.responseText).query.pages);
        } else {
          // console.error(xhr.statusText);
        }
      }
    };
    /*
    xhr.onerror = function(e) {
      console.log(`${e}`);
      // console.error(xhr.statusText);
    }
    */
    xhr.send(null);
}

function updateSaveButtonText(button, title, isSaved){
  button.innerText = isSaved ? _savedForLaterString : _saveForLaterString;
}

function updateSaveButtonBookmarkIcon(button, title, isSaved){
  button.classList.remove('footer_readmore_bookmark_unfilled');
  button.classList.remove('footer_readmore_bookmark_filled');  
  button.classList.add(isSaved ? 'footer_readmore_bookmark_filled' : 'footer_readmore_bookmark_unfilled');
}

function setTitleIsSaved(title, isSaved){
  const saveButton = document.getElementById(`${_saveButtonIDPrefix}${title}`);
  updateSaveButtonText(saveButton, title, isSaved);
  updateSaveButtonBookmarkIcon(saveButton, title, isSaved);
}

function add(baseURL, title, saveForLaterString, savedForLaterString, containerID, clickHandler, saveButtonClickHandler, titlesShownHandler) {
  _readMoreContainer = document.getElementById(containerID);
  _clickHandler = clickHandler;
  _saveButtonClickHandler = saveButtonClickHandler;
  _titlesShownHandler = titlesShownHandler;  
  _saveForLaterString = saveForLaterString;
  _savedForLaterString = savedForLaterString;
  
  fetchReadMore(baseURL, title, showReadMore);
}

function setHeading(headingString, headingID) {
  document.getElementById(headingID).innerText = headingString;
}

exports.setHeading = setHeading;
exports.setTitleIsSaved = setTitleIsSaved;
exports.add = add;
