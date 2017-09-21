function applyDarkThemeLogo() {
    hideElementById('dark-logo')
    showElementById('light-logo')
}

function applyLightThemeLogo() {
    hideElementById('light-logo')
    showElementById('dark-logo')
}

function showElementById(id) {
    show(document.getElementById(id))
}

function hideElementById(id) {
    hide(document.getElementById(id))
}

function show(element) {
    element.style.display = ''
}

function hide(element) {
    element.style.display = 'none'
}
