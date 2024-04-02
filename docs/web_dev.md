# Wikipedia iOS Web Development

The app uses several web components. This document explains how they are set up and how to update them. 

#### Article View
The article view uses a server-side response from our [Page Content Service](https://www.mediawiki.org/wiki/Page_Content_Service#/page/mobile-html) with additional local `js` and `css` files for further customizations. These local files live within the `Wikipedia/assets` folder in the project. You can update these directly and commit the changes.

#### Other Views
There are other smaller web components in the app, such as the About view. These live in the `Wikipedia/assets` folder and can be updated directly. 
