# Process

## Creating pull requests
When composing a pull request, link to the phabricator ticket that the work relates to. Also apply GitHub labels where appropriate.

### Labels
#### Dependent PR
Pull request contains changes from another pull request. This dependent PR must be merged first. After dependent PR is merged, be sure to update from the base branch before merging.
#### Question/Design Question
Pull request has a question that needs answering.
#### Design Review
Pull request is in design review, meaning further commits might trickle in to address design feedback. PR can still be reviewed in this state.

For Work in Progress or pull requests on Hold, [mark your PR as draft](https://docs.github.com/en/github/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests#draft-pull-requests) via the GitHub UI.

## Assigning pull requests
Assigning the `wikimedia/ios` bot as a reviewer will randomly choose an iOS engineer from the team to review. If you have one or more a specific engineers in mind to review, you can assign them directly. 

## Merging pull requests
Pull requests require code review approval from one other developer before merging. After the pull request is merged, delete the branch, unless it's the TWN branch. **Never delete the twn branch** as it's [required by translatewiki to import translations](localization.md).
