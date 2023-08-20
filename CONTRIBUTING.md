# Contribution Guide

This page describes how to contribute changes to Savon.

Please do not create a pull request without reading this guide first.
Make sure to read the documentation for your version and ask questions on [Stack Overflow](https://stackoverflow.com/questions/ask?tags=savon).

**Bug fixes**

If you really think you found a bug, please make sure to add as much information as possible
to the ticket. You're a developer, we are developers and you know we need tests to reproduce
problems and make sure they don't come back.

So if you can reproduce your problem in a spec, that would be awesome! If you can't, please
let us know how we can make this easier for you. Also, provide code and the WSDL of the
service you're working with, so others can try to come up with a spec for your problem.

After we have a failing spec, it needs to be fixed. Make sure your new spec is the
only failing one under the `spec` directory. CI only runs the "unit tests" at `spec/savon`,
but Savon actually has some additional specs at `spec/integration`, which you need to run locally 
to make sure the integration with real-world services still works.

These specs are not run by CI, because the services are not guaranteed to work all the time.

Please follow this workflow for Pull Requests:

* [Fork the project](https://help.github.com/articles/fork-a-repo)
* Create a feature branch and make your bug fix
* Add tests for it!
* [Send a Pull Request](https://help.github.com/articles/using-pull-requests)
* [Check that your Pull Request passes the build](https://github.com/savonrb/savon/actions?query=workflow%3ARuby)

**Improvements and feature requests**

If you have an idea for an improvement or a new feature, please feel free to
[create a new Issue](https://github.com/savonrb/savon/issues/new/choose) and describe your idea
so that other people can give their insights and opinions. This is also important to avoid
duplicate work.

Pull Requests and Issues on GitHub are meant to be used to discuss problems and ideas,
so please make sure to participate and follow up on questions. In case no one comments
on your ticket, please keep updating the ticket with additional information.
