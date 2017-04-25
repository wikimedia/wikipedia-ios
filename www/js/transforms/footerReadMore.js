
var _saveButtonClickHandler = null;
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
        var pageContainer = document.createElement('div');
        pageContainer.id = index;
        pageContainer.className = 'footer_readmore_page';

        var containerAnchor = document.createElement('a');
        containerAnchor.href = '/wiki/' + encodeURI(wmfPage.title);
        pageContainer.appendChild(containerAnchor);

        var bottomActions = document.createElement('div');
        bottomActions.id = index;
        bottomActions.className = 'footer_readmore_page_actions';
        pageContainer.appendChild(bottomActions);

        if(wmfPage.title){
            var title = document.createElement('h3');
            title.id = index;
            title.className = 'footer_readmore_page_title';
            title.innerHTML = wmfPage.title.replace(/_/g, ' ');
            containerAnchor.appendChild(title);
        }

        if(wmfPage.thumbnail){
            var img = document.createElement('img');
            img.id = index;
            img.className = 'footer_readmore_page_thumbnail';
            
//TODO: inject this class name
img.classList.add('wideImageOverride');
  
            img.src = wmfPage.thumbnail.source;
            img.width = 120;
            containerAnchor.appendChild(img);
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
            containerAnchor.appendChild(descriptionEl);
        }

        var saveAnchor = document.createElement('a');
        saveAnchor.id = `${_saveButtonIDPrefix}${encodeURI(wmfPage.title)}`;
        saveAnchor.innerText = 'Save for later';
        saveAnchor.className = 'footer_readmore_page_action_save';

        saveAnchor.addEventListener('click', function(){
          _saveButtonClickHandler(wmfPage.title);
        }, false);

        bottomActions.appendChild(saveAnchor);
        
        return document.createDocumentFragment().appendChild(pageContainer);
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
      pithumbsize: 640,
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

function add(baseURL, title, saveForLaterString, savedForLaterString, containerID, saveButtonClickHandler, titlesShownHandler) {
  _readMoreContainer = document.getElementById(containerID);
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
