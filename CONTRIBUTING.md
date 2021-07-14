# Contributing to spandex_tesla

First off, thanks for taking the time to contribute!

Now, take a moment to be sure your contributions make sense to everyone else.
These are just guidelines, not rules.
Use your best judgment, and feel free to propose changes to this document in a pull request.

Please note that this project is released with a [Contributor Code of Conduct][code-of-conduct]. By participating in this project you agree to abide by its terms.

## Reporting Issues
Found a problem? Want a new feature? First of all see if your issue or idea has [already been reported][issue].
If don't, just open a [new clear and descriptive issue][new-issue].

## Submitting pull requests
Pull requests are the greatest contributions, so be sure they are focused in scope, and do avoid unrelated commits.
And submit your pull request after making sure that all tests pass and they are covering 100% of the code.

- [Fork][fork] it!
- Clone your fork: `git clone https://github.com/<your-username>/spandex_tesla`
- Navigate to the newly cloned directory: `cd spandex_tesla`
- Create a new branch for the new feature: `git checkout -b my-new-feature`
- Install the tools necessary for development: `mix deps.get`
- Make your changes.
- Commit your changes: `git commit -am 'Add some feature'`
- Push to the branch: `git push origin my-new-feature`
- Submit a pull request with full remarks documenting your changes.

## Publishing new versions

1. Bump the version on README and mix.exs
2. Update the changelog
3. Make a commit for the new version `git commit -am "vx.x.x"`
4. Tag the version `git tag "vx.x.x" && git push origin master --tags`
5. Publish to hex `mix hex.publish`
6. Create a [new release][new-release]

[fork]: https://github.com/thiamsantos/spandex_tesla/fork
[code-of-conduct]: https://github.com/thiamsantos/spandex_tesla/blob/master/CODE_OF_CONDUCT.md
[issue]: https://github.com/thiamsantos/spandex_tesla/issues
[new-issue]: https://github.com/thiamsantos/spandex_tesla/issues/new
[new-release]: https://github.com/thiamsantos/spandex_tesla/releases/new?body=Checkout+the+%5Bchangelog%5D%28https%3A%2F%2Fgithub.com%2Fthiamsantos%2Fspandex_tesla%2Fblob%2Fmaster%2FCHANGELOG.md%29
