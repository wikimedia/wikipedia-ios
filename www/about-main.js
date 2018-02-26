const wmf = {}

wmf.applyDarkThemeLogo = () => {
  hideElementById('dark-logo')
  showElementById('light-logo')
}

wmf.applyLightThemeLogo = () => {
  hideElementById('light-logo')
  showElementById('dark-logo')
}

const showElementById = id => {
  show(document.getElementById(id))
}

const hideElementById = id => {
  hide(document.getElementById(id))
}

const show = element => {
  element.style.display = ''
}

const hide = element => {
  element.style.display = 'none'
}

window.wmf = wmf