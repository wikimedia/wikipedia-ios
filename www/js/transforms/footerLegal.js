
function add(licenseString, licenseSubstitutionString, containerID, licenceLinkClickHandler) {
  var container = document.getElementById(containerID)
  var licenseStringHalves = licenseString.split('$1')


  container.innerHTML = 
  `<div class='footer_legal_contents'>
    <hr class='footer_legal_divider'>
    <span class='footer_legal_licence'>
      ${licenseStringHalves[0]}
      <a class='footer_legal_licence_link'>
        ${licenseSubstitutionString}
      </a>
      ${licenseStringHalves[1]}
    </span>
  </div>`

  container.querySelector('.footer_legal_licence_link')
           .addEventListener('click', function(){
             licenceLinkClickHandler()
           }, false)
}

exports.add = add