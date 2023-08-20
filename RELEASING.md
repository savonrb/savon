_You'll need write access to the repository and the [rubygems](https://rubygems.org/gems/savon) project to create a release._

1. On master, edit [CHANGELOG.md](https://github.com/savonrb/savon/blob/master/CHANGELOG.md) to finalize the new version number and list of all changes.
2. Bump [version.rb](https://github.com/savonrb/savon/blob/master/lib/savon/version.rb) to the version you picked in previous step.
3. **Final check**: make sure all tests are green, and that `gem build savon.gemspec` on master succeeds. If not, merge any fixes back to master and go to step 1.
4. [Draft a new release](https://github.com/savonrb/savon/releases/new) on Github.
   - Create a tag matching the version in previous step - e.g. `v2.12.1` - prepend the version number with a "v". 
   - Use `v[version]` for the release title, and copy the changelog into the release notes. 
   - Click "Publish release" to commit the tag on Github.
5. `git checkout` the newly commited tag, then `gem build savon.gemspec` to build the gem package locally. Use `gem push savon-[version].gem` to publish to rubygems.
