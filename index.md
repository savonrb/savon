---
title: Home
layout: default
---

Introduction to Pages
=====================

The GitHub Pages feature allows you to publish content to the web by simply pushing content to one of your GitHub hosted repositories. There are two different kinds of Pages that you can create: User Pages and Project Pages.

User Pages
----------

Let's say your GitHub username is "alice". If you create a GitHub repository named `alice.github.com`, commit a file named `index.html` into the `master` branch, and push it to GitHub, then this file will be automatically published to [http://alice.github.com/](http://alice.github.com/).

On the first push, it can take up to ten minutes before the content is available.

Real World Example: [github.com/defunkt/defunkt.github.com](http://github.com/defunkt/defunkt.github.com/) &rarr; [http://defunkt.github.com/](http://defunkt.github.com/).

Project Pages
-------------

Let's say your GitHub username is "bob" and you have an existing repository named `fancypants`. If you create a new root branch named `gh-pages` in your repository, any content pushed there will be published to [http://bob.github.com/fancypants/](http://bob.github.com/fancypants/).

In order to create a new root branch, first ensure that your working directory is clean by committing or stashing any changes. <span style="color: #a00;">The following operation will lose any uncommitted changes!</span>

After running this you'll have an empty working directory (don't worry, your main repo is still on the `master` branch). Now you can create some content in this branch and push it to GitHub. For example:

{% highlight ruby %}
client = Savon::Client.new :wsdl => "http://example.com?wsdl"
{% endhighlight %}

{% highlight ruby %}
client.call(:get_user) do
  soap.body = { :id => 123 }
end
{% endhighlight %}

On the first push, it can take up to ten minutes before the content is available.

Real World Example: [github.com/defunkt/ambition@gh-pages](http://github.com/defunkt/ambition/tree/gh-pages) &rarr; [http://defunkt.github.com/ambition](http://defunkt.github.com/ambition).

### Project Page Generator

If you don't want to go through the steps above to generate your branch, or you simply would like a generic page, you can use our page generator to create your gh-pages branch for you and fill it with a default page.

![Page generator](page_generator.jpg)

After your page is generated, you can check out the new branch:

    $ cd Repos/ampere
    $ git fetch origin
    remote: Counting objects: 92, done.
    remote: Compressing objects: 100% (63/63), done.
    remote: Total 68 (delta 41), reused 0 (delta 0)
    Unpacking objects: 100% (68/68), done.
    From git@github.com:tekkub/ampere
     * [new branch]      gh-pages     -> origin/gh-pages
    $ git checkout -b gh-pages origin/gh-pages
    Branch gh-pages set up to track remote branch refs/remotes/origin/gh-pages.
    Switched to a new branch "gh-pages"

Using Jekyll For Complex Layouts
================================

In addition to supporting regular HTML content, GitHub Pages support [Jekyll](http://github.com/mojombo/jekyll/), a simple, blog aware static site generator written by our own Tom Preston-Werner. Jekyll makes it easy to create site-wide headers and footers without having to copy them across every page. It also offers intelligent blog support and other advanced templating features.

Every GitHub Page is run through Jekyll when you push content to your repo. Because a normal HTML site is also a valid Jekyll site, you don't have to do anything special to keep your standard HTML files unchanged. Jekyll has a thorough [README](http://github.com/mojombo/jekyll/blob/master/README.textile) that covers its features and usage.

As of April 7, 2009, you can configure most Jekyll settings via your `_config.yml` file. Most notably, you can select your permalink style and choose to have your Markdown rendered with RDiscount instead of the default Maruku. The only options we override are as follows:

    safe: true
    source: <your pages repo>
    destination: <the build dir>
    lsi: false
    pygments: true

If your Jekyll site is not transforming properly after you push it to GitHub, it's useful to run the converter locally so you can see any parsing errors. In order to do this, you'll want to use the same version that we use.

We currently use <span style="font-weight: bold; color: #0a0;">Jekyll 0.6.0</span> and run it with the equivalent command:

    jekyll --pygments --safe

As of December 27, 2009, you can completely opt-out of Jekyll processing by creating a file named `.nojekyll` in the root of your pages repo and pushing that to GitHub. This should only be necessary if your site uses directories that begin with an underscore, as Jekyll sees these as special dirs and does not copy them to the final destination.

If there's a feature you wish that Jekyll had, feel free to fork it and send a pull request. We're happy to accept user contributions.

Real World Example: [github.com/pages/pages.github.com](http://github.com/pages/pages.github.com/) &rarr; [http://pages.github.com/](http://pages.github.com/).

Custom Domains
==============

If you or one of the collaborators on your repository have a paid account, GitHub Pages allows you to direct a domain name of your choice at your Page.

Let's say you own the domain name [example.com](http://example.com). Furthermore, your GitHub username is "charlie" and you have published a User Page at [http://charlie.github.com/](http://charlie.github.com/). Now you'd like to load up [http://example.com/](http://example.com) in your browser and have it show the content from [http://charlie.github.com/](http://charlie.github.com/).

Start by creating a file named `CNAME` in the root of your repository. It should contain your domain name like so:

    example.com

Push this new file up to GitHub.  The server will set your pages to be hosted at [example.com](http://example.com), and create redirects from [www.example.com](http://www.example.com) and [charlie.github.com](http://charlie.github.com/) to [example.com](http://example.com).

Next, you'll need to visit your domain registrar or DNS host and add a record for your domain name. For a sub-domain like `www.example.com` you would simply create a CNAME record pointing at `charlie.github.com`.  If you are using a top-level domain like `example.com`, you must use an A record pointing to `207.97.227.245`.  *Do not use a CNAME record with a top-level domain,* it can have adverse side effects on other services like email.  Many DNS services will let you set a CNAME on a TLD, even though you shouldn't.  Remember that it may take up to a full day for DNS changes to propagate, so be patient.

Real World Example: [github.com/mojombo/mojombo.github.com](http://github.com/mojombo/mojombo.github.com/) &rarr; [http://tom.preston-werner.com/](http://tom.preston-werner.com/).

Custom 404 Pages
================

If you provide a `404.html` file in the root of your repo, it will be served instead of the default 404 page.  Note that Jekyll-generated pages will not work, it <i>must</i> be an html file.

Real World Example: [http://github.com/tekkub/tekkub.github.com/blob/master/404.html](http://github.com/tekkub/tekkub.github.com/blob/master/404.html) &rarr; [http://tekkub.net/404.html](http://tekkub.net/404.html).
