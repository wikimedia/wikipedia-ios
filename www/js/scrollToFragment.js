function scrollToFragment(fragmentId){
    location.hash = '';
    location.hash = fragmentId;
}

global.scrollToFragment = scrollToFragment;