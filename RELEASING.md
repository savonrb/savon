_You'll need write access to the repository and the [rubygems](https://rubygems.org/gems/savon) project to create a release._

## Cutting a release

1. On main, edit [CHANGELOG.md](https://github.com/savonrb/savon/blob/main/CHANGELOG.md) to finalize the new version number and list of all changes.
2. Bump [version.rb](https://github.com/savonrb/savon/blob/main/lib/savon/version.rb) to the version you picked in previous step.
3. **Final check**: make sure all tests are green, and that `gem build savon.gemspec` on main succeeds. If not, merge any fixes back to main and go to step 1.
4. [Draft a new release](https://github.com/savonrb/savon/releases/new) on Github.
   - Create a tag matching the version in previous step - e.g. `v2.12.1` - prepend the version number with a "v". 
   - Use `v[version]` for the release title, and copy the changelog into the release notes. 
   - Click "Publish release" to commit the tag on Github.
5. `git checkout` the newly commited tag, then `gem build savon.gemspec` to build the gem package locally. Use `gem push savon-[version].gem` to publish to rubygems.

## Updating minimum ruby version

- Update `required_ruby_version` in [savon.gemspec](https://github.com/savonrb/savon/blob/main/savon.gemspec)
- Update the test matrix in [ci.yml](https://github.com/savonrb/savon/blob/main/.github/workflows/ci.yml)
- Update [README](https://github.com/savonrb/savon/blob/main/README.md) with the correct support matrix
- Note the updated requirement in [CHANGELOG.md](https://github.com/savonrb/savon/blob/main/CHANGELOG.md)
