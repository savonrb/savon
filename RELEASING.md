_You'll need write access to the repository to create a release. Publishing is handled automatically via [trusted publishing](https://guides.rubygems.org/trusted-publishing/)._

## Cutting a release

1. On your release branch (e.g. `main`, `v2.x`), edit [CHANGELOG.md](https://github.com/savonrb/savon/blob/main/CHANGELOG.md) to finalize the new version number and list of all changes.
2. Bump [version.rb](https://github.com/savonrb/savon/blob/main/lib/savon/version.rb) to the version you picked in previous step.
3. **Final check**: make sure all tests are green, and that `rake build` succeeds. If not, merge any fixes back to the release branch and go to step 1.
4. [Draft a new release](https://github.com/savonrb/savon/releases/new) on Github.
   - In the "Choose a tag" field, type the version tag - e.g. `v2.12.1` - and select "Create new tag on publish".
   - Use `v[version]` for the release title, and copy the changelog into the release notes.
   - Click "Publish release". Github creates and pushes the tag, which triggers the release workflow.
5. Publishing to RubyGems.org is fully automated. The [Push gem workflow](https://github.com/savonrb/savon/actions/workflows/gem_push.yml) triggers on the published release and requires approval from a release manager via the `release` environment before credentials are issued. **Before approving**: confirm that CI is green on the release commit. Approve the deployment in the Actions UI and the gem will be built and pushed automatically.

## Updating minimum ruby version

- Update `required_ruby_version` in [savon.gemspec](https://github.com/savonrb/savon/blob/main/savon.gemspec)
- Update the test matrix in [ci.yml](https://github.com/savonrb/savon/blob/main/.github/workflows/ci.yml)
- Update [README](https://github.com/savonrb/savon/blob/main/README.md) with the correct support matrix
- Note the updated requirement in [CHANGELOG.md](https://github.com/savonrb/savon/blob/main/CHANGELOG.md)
