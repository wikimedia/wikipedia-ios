# Working With Ruby
The project only depends on the default Ruby installation of OS X. This is codified in the `.ruby-version` file, which is enforced by [Bundler](http://bundler.io/) and picked up by Ruby version managers such as [rbenv](https://github.com/sstephenson/rbenv). Tools like rbenv and rvm are recommended if you are working on projects which depend on different versions of Ruby.

## Gems
### Installation
Any gems that the project uses are added to the `Gemfile`, which is used by Bundler to install gems _locally_, inside the project directory. This is done for two reasons. First, to prevent any side effects caused by depending or installing gems globally. Second, to remove any possible need for `sudo` when installing gems. As such, installing gems globally is **not** recommended, nor is using `sudo` to install gems into the OSX-provided Ruby enviroment.

### Usage
Invoking any of the gems installed by Bundler can be done a couple of different ways. The most reliable way is by using `bundle exec` to prefix your commands (e.g. `bundle exec pod install`). If this is too cumbersome, you can use the `Makefile` goals (e.g. `make pod` which runs `bundle exec pod install`), or configure your `PATH` to discover the local binaries installed by Bundler.
