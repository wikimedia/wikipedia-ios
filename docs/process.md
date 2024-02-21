# Process

## Creating pull requests
When composing a pull request, link to the phabricator ticket that the work relates to. Also apply GitHub labels where appropriate.

### Labels
#### Dependent PR
Pull request contains changes from another pull request. Updating from main after the dependent PR is merged will clean up the diff.
#### Question/Design Question
Pull request has a question that needs answering.

For Work in Progress or pull requests on Hold, [mark your PR as draft](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests#draft-pull-requests) via the GitHub UI.

## Assigning pull requests
Assigning the `wikimedia/ios` bot as a reviewer will randomly choose an iOS engineer from the team to review. If you have one or more a specific engineers in mind to review, you can assign them directly. 

## Merging pull requests
Pull requests require code review approval from one other developer before merging. After the pull request is merged, delete the branch, unless it's the TWN branch. **Never delete the twn branch** as it's [required by translatewiki to import translations](localization.md).
