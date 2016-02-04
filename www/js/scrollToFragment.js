function scrollToFragment(fragmentId){
    location.hash = '';
    location.hash = fragmentId;
}

global.scrollToFragment = scrollToFragment;

function accessibilityCursorToFragment(fragmentId){
    /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
    var focus_element = document.getElementById(fragmentId);
    var other_element = document.body;
    other_element.setAttribute('tabindex', 0);
    other_element.focus();
    focus_element.setAttribute('tabindex', 0);
    focus_element.focus();
}

global.accessibilityCursorToFragment = accessibilityCursorToFragment;
