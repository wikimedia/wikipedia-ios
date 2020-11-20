# Process

## Creating pull requests
When composing a pull request, link to the phabricator ticket that the work relates to. Also apply GitHub labels where appropriate.

### Labels
#### Release number (6.2, 6.2.1, etc)
Which release is this work for?
#### WIP
Work in progress. Don't merge, also hold off on full review
#### Hold
Don't merge yet. Needs more discussion with product & design or is blocked by something else.
#### Changes welcome
Just make the suggested change rather than adding a code review comment.
#### Update branch before merging
Pull request contains changes from another pull request. Updating from main after the dependent PR is merged will clean up the diff.
#### Question/Design Question
Pull request has a question that needs answering.
#### Low impact
The code change in the pull request doesn't affect more than a few files or is just a refactor.

## Merging pull requests
Pull requests require code review approval from one other developer before merging. After the pull request is merged, delete the branch, unless it's the TWN branch. **Never delete the twn branch** as it's [required by translatewiki to import translations](localization.md).
