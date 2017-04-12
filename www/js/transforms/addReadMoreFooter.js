
const transformer = require('../transformer');

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
        containerAnchor.href = '/wiki/' + wmfPage.title.replace(/ /g, '_');
        pageContainer.appendChild(containerAnchor);

        var bottomActions = document.createElement('div');
        bottomActions.id = index;
        bottomActions.className = 'footer_readmore_page_actions';
        pageContainer.appendChild(bottomActions);

        if(wmfPage.title){
            var title = document.createElement('h3');
            title.id = index;
            title.className = 'footer_readmore_page_title';
            title.innerHTML = wmfPage.title;
            containerAnchor.appendChild(title);
        }

        if(wmfPage.thumbnail){
            var img = document.createElement('img');
            img.id = index;
            img.className = 'footer_readmore_page_thumbnail';
            img.src = wmfPage.thumbnail.source;
            img.width = 120;
            containerAnchor.appendChild(img);
        }

        if(wmfPage.terms){
            var description = document.createElement('h4');
            description.id = index;
            description.className = 'footer_readmore_page_description';
            description.innerHTML = wmfPage.terms.description;
            containerAnchor.appendChild(description);
        }

        if(wmfPage.extract){
            var extract = document.createElement('div');
            extract.id = index;
            extract.className = 'footer_readmore_page_extract';
            extract.innerHTML = wmfPage.extract;
            containerAnchor.appendChild(extract);
        }

        var saveAnchor = document.createElement('a');
        saveAnchor.id = index;
        saveAnchor.innerText = 'Save for later';
        saveAnchor.className = 'footer_readmore_page_action_save';
        saveAnchor.href = '/wiki/Dog';
        bottomActions.appendChild(saveAnchor);
        
        return document.createDocumentFragment().appendChild(pageContainer);
    }
}

const showReadMore = (pages) => {
  const app_footer_readmore = document.getElementById('app_footer_readmore');
  pages.forEach((page, index) => {
    const pageModel = new WMFPage(page.title, page.thumbnail, page.terms, page.extract);
    const pageFragment = new WMFPageFragment(pageModel, index);
    app_footer_readmore.appendChild(pageFragment);
  });
};

// Leave 'baseURL' null if you don't need to deal with proxying.
const fetchReadMore = (baseURL, title, showReadMoreHandler) => {
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
      pithumbsize: 320,
      prop: 'pageterms|pageimages|pageprops|revisions|extracts',
      rrvlimit: 1,
      rvprop: 'ids',
      wbptterms: 'description',
      formatversion: 2
    };

    const paramsString = Object.keys(params)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`).join('&');
    
    xhr.open('GET', `${baseURL}/w/api.php?${paramsString}`, true);
    xhr.onload = () => {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
            showReadMoreHandler(JSON.parse(xhr.responseText).query.pages);
        } else {
          // console.error(xhr.statusText);
        }
      }
    };
    xhr.onerror = (e) => {
      console.log(`${e}`);
      // console.error(xhr.statusText);
    };
    xhr.send(null);
};

transformer.register('addReadMoreFooter', function(baseURL, title) {
  fetchReadMore(baseURL, title, showReadMore);
});
