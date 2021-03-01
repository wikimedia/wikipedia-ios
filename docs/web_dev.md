# Wikipedia iOS Web Development
This document covers setting up your machine for work on the web components of the Wikipedia iOS project.

## Setup

Similar to the [project's Ruby setup for ci](ci.md), we recommend using a [node version manager](https://github.com/nodenv/nodenv) to install node and manage multiple versions of [node](https://nodejs.org/) on the same machine.

These are the recommended steps for setting up your machine for web development:

#### Update Submodules
The web components are included in this repo as a Git submodule called `wikipedia-ios-codemirror`. To fully initialize the submodule, run the script located at `scripts/update_submodules`.

#### Install [homebrew](https://brew.sh)
[homebrew](https://brew.sh) should have been installed by `scripts/setup`, but if you didn't run that script or would like to manually install it:
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

#### Install [nodenv](https://github.com/nodenv/nodenv)
[nodenv](https://github.com/nodenv/nodenv) manages  multiple node versions on the same machine. This is helpful in our environment where other Wikimedia Foundation repositories depend on different node versions. After [homebrew](https://brew.sh) is installed, install [nodenv](https://github.com/nodenv/nodenv) by running:
```
brew install nodenv
```

#### Update your ~/.bash_profile
Once the install command completes, add `eval "$(nodenv init -)"` to your `~/.bash_profile` (create this file if it doesn't exist)

#### Restart Terminal
After terminal restarts, verify that [nodenv](https://github.com/nodenv/nodenv)  is working properly by typing `which node` and verifying it shows a path inside your home folder.

#### Install the required node version
First `cd` to the directory where you have this repository:
```
cd /path/to/your/wikipedia-ios
```

Then, install the [node](https://nodejs.org/) version specified by our project by running:
```
nodenv install -s
```

Verify it was installed by running `node -v` and matching it to the version number specified in the `.node-version` file in this repository.

#### Install [grunt](http://gruntjs.com)
We use [grunt](http://gruntjs.com) to automate tasks related to web development such as dependency management and packaging the sources for [integration into the app](#integrating-web-into-the-native-app). Install [grunt](http://gruntjs.com) for your newly installed version of node by running:
```
npm install -g grunt
```

Verify that grunt was properly installed by running `which grunt` and verifying it shows a path inside your home folder. If it doesn't, try restarting terminal again or switching to a new terminal tab.

#### Install node modules
First `cd` to the directory where you have this repository if you aren't there already:
```
cd /path/to/your/wikipedia-ios
```

Next, `cd` to the www folder inside of this repository:
```
cd www
```

Next, install the node dependencies (modules) specified by `package.json` by running:
```
npm install
```

Finally, run grunt to build the web components of the app:
```
grunt
```

## Process
When making any changes to web dependencies, you should be working with the files in the `www` folder. Once you are done making changes, run `grunt` inside of that folder to compile your changes into the `Wikipedia/assets` folder. When committing these changes, there will be similar updates to files in both `www` and `Wikipedia/assets`.