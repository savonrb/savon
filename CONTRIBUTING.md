# Contribution Guide

This page describes how to contribute changes to Savon.

Please do not create a pull request without reading this guide first.
Make sure to read the documentation for your version at [savonrb.com](http://savonrb.com/)
and post questions to the [mailing list](https://groups.google.com/forum/#!forum/savonrb).

**Bug fixes**

If you really think you found a bug, please make sure to add as many information as possible
to the ticket. You're a developer, we are developers and you know we need tests to reproduce
problems and make sure they don't come back.

So if you can reproduce your problem in a spec, that would be awesome! If you can't, please
let us know how we could make this easier for you. Also, provide code and the WSDL of the
service your working with so others can try to come up with a spec for your problem.

After we have a failing spec, it obviously needs to be fixed. Make sure your new spec is the
only failing one under the `spec` directory. Travis only runs the "unit tests" at `spec/savon`,
but Savon actually has with some additional "integration/example specs" at `spec/integration`,
which you need to run locally to make sure the integration with real world services still works.

Notice that these specs are not run by Travis, because the service's are not guaranteed to work
all the time and the specs will timeout after a few seconds when the service is currently down.

Please follow this basic workflow for pull requests:

* [Fork the project](https://help.github.com/articles/fork-a-repo)
* Create a feature branch and make your bug fix
* Add tests for it!
* Update the [Changelog](https://github.com/savonrb/savon/blob/master/CHANGELOG.md)
* [Send a pull request](https://help.github.com/articles/using-pull-requests)
* [Check that your pull request passes the build](https://travis-ci.org/savonrb/savon/pull_requests)


**Improvements and feature requests**

If you have an idea for an improvement or a new feature, please feel free to
[create a new issue](https://github.com/savonrb/savon/issues/new) and describe your idea
so that other people can give their insights and opinions. This is also important to avoid
duplicate work.

Pull requests and issues on GitHub are meant to be used to discuss problems and ideas,
so please make sure to participate and follow up on questions. In case noone comments
on your ticket, please keep updating the ticket with additional information.
