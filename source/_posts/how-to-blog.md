---
title: How to start a tech blog FAST (with Hexo)
date: 2024-06-29 14:15:29
tags: blogging
---

If you are an aspiring tech blogger looking to launch your site quickly, look no more. This post is about how I spun up a blog in under 15 minutes using [Hexo](https://hexo.io/) (I was not paid to write this).

I'll share my personal experience and provide a step-by-step process to help you succeed where I've failed before.

## Why Hexo?

Hexo is like many of the existing static site generators out there, but with one awesome caveat: there's a lot of batteries included. These are some of the reasons I chose to use Hexo:

-   It has crazy awesome documentation with plenty of examples
-   It is more lightweight and faster than using Wordpress
-   It supports markdown out of the box
-   Setup can be done in under 5 minutes
-   It is secure by default (static sites tend to be)
-   It is highly customizable with themes
-   It is free and open source
-   There is a built in server for local testing
-   There is no database required
-   Support for multiple languages is possible through i18n
-   Configuration is located in one place (a \_config.yml file that is easy to read and parse)

```py
def give_reader_words_of_encouragement() -> None:
    print("It has code highlighting out of the box")
```

If you're convinced or willing to give it a try, let's go through setup together.

## Setup

Setup takes about 10-15 minutes.

Prerequisites

-   install [Node.js](https://nodejs.org/en) (Should be at least Node.js 10.13, recommends 12.0 or higher)
-   install [Git](https://git-scm.com/)

Installing Hexo

-   install [Hexo](https://hexo.io/):
    `npm install hexo-cli -g`
-   setup the initial blog:
    `hexo init blog`
-   install dependencies
    `cd blog && npm install`
-   start the server:
    `hexo server`

Congratulations. You have a working blog already.

![hexo hello world page](/images/hexo-hello-world.png)

Spend the next 5 minutes becoming familiar with how to create blog pages and blog posts:

Documentation concerning blog creation is here (5 minute read): https://hexo.io/docs/writing.html

## Create a new page

```bash
$ hexo new page about
```

## Create a new post

```bash
$ hexo new "My New Post"
```

More info: [Writing](https://hexo.io/docs/writing.html)

## Create a new draft

```bash
$ hexo new draft "My New Post"
```

## Publish draft

```bash
$ hexo publish draft "My New Post"
```

Under the hood, this just moves the markdown file from `source/_drafts` to `source/_posts`

## Run server

```bash
$ hexo server
```

More info: [Server](https://hexo.io/docs/server.html)

## Generate static files

```bash
$ hexo generate
```

More info: [Generating](https://hexo.io/docs/generating.html)

## Deploy to remote sites

```bash
$ hexo deploy
```

More info: [Deployment](https://hexo.io/docs/one-command-deployment.html)

## Documentation

Documentation can be found [here](https://hexo.io/docs/)
