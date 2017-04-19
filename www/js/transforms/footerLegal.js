
function add(licenseString, licenseSubstitutionString, licenceLinkClickHandler) {
  var container = document.getElementById('footer_legal_container');

  var contents = document.createElement('div');
  contents.className = 'footer_legal_contents';

  var licenseStringHalves = licenseString.split('$1');

  var licenseEl = document.createElement('span');
  licenseEl.className = 'footer_legal_licence';

  var firstHalf = document.createTextNode(licenseStringHalves[0]);
  licenseEl.appendChild(firstHalf);

  var licenseLinkEl = document.createElement('span');
  licenseLinkEl.className = 'footer_legal_licence_link';
  licenseLinkEl.innerText = licenseSubstitutionString;
  licenseLinkEl.addEventListener('click', function(){
    licenceLinkClickHandler();
  }, false);
  licenseEl.appendChild(licenseLinkEl);

  var secondHalf = document.createTextNode(licenseStringHalves[1]);
  licenseEl.appendChild(secondHalf);

  contents.appendChild(licenseEl);
  container.appendChild(contents);
}

exports.add = add;
