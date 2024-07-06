---
title: Writing good commit messages
date: 2024-07-06 11:51:49
tags:
    - git
    - version control
---

Recently, our team expanded with the addition of several platform engineers. During onboarding, a colleague proposed adopting a standardized commit message format. This suggestion prompted me to investigate Git best practices, particularly focusing on commit message conventions. My goal today is to share some of my findings.

In this post I will not touch on _git commit guidelines_, as that's another rabbit hole.

I'll start with a quote that stuck with me through the years:

> Re-establishing the context of a piece of code is wasteful. We can't avoid it completely, so our efforts should go to [reducing it](http://www.osnews.com/story/19266/WTFs_m) to as small as possible. Commit messages can do exactly that and as a result, *a commit message shows whether a developer is a good collaborator*.
>
> -   Peter Hutterer

## Advantages to Adhering to Guidelines

### Higher Team Velocity Through Faster Information Retrieval

Team velocity is significantly influenced by collaborative efficiency. Git is a distributed version control system designed to enable asynchronous collaboration. Through having a consistent set of guidelines, developers and maintainers acquire a reliable map -- the project's log, for streamlining their workflows. Without said guidelines, a project's log might resemble something that looks like:

```
A:

fix bug where neighbor vacuums at 5am
revert senior engineer's lunch
updated readme to add emojis
WIP: new feature
forgot to add file
finalized feature
rebase egg salad onto mcchicken
```

This lack of structure can impede productivity and hinder effective code review processes. Let's compare it to a change log that has some semblance of structure:

```
B:

feat: add user authentication system
fix: resolve memory leak in data processing module
docs: update API documentation for new endpoints
refactor: optimize database query performance
test: add unit tests for payment gateway integration
chore: update dependencies to latest versions
```

While the former might be okay if you're the only engineer working on the codebase (though I'd argue that you'll still forget what you did in half a year and the log won't be helpful), the latter allows others to comb through the history more elegantly. Now developers can quickly search through change logs and get the information they need significantly quicker.

### Leveraging Automation Tools

A side effect of the latter implementation is that many tools know how to read this format to automate change logs or even populate pull requests (thank you Bitbucket).

By having a commit that looks like

```
doc: introduce documentation for /query endpoint

- add swagger documentation
```

Opening a PR automatically populates both the title and body appropriately, and change logs can also get auto generated from the above format.

## The Conventional Commits Specification

The Conventional Commits Specification is based heavily on the [Angular Commit Guidelines](https://github.com/angular/angular/blob/22b96b9/CONTRIBUTING.md#-commit-message-guidelines) , and is commonly used amongst teams to help keep commits as atomic and consistent as possible. This is achieved by having commits follow this standard:

```
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

Some Examples:

```
## Simple
fix: additional handling in parse_claude_response

## Simple
chore: fix one typo in directory name

## Commit message with scope
feat(lang): add Polish language

## Commit message that includes a breaking change
feat(api)!: send an email to the customer when a product is shipped
```

Visit the official [Conventional Commits Specification Site](https://www.conventionalcommits.org/en/v1.0.0/#specification) to read more about the different types, scopes, subject, body, and footer explanations.

## Should You Follow It?

Not necessarily!

If your team already has a set of standards and guidelines, there's nothing wrong with staying with what your team has already decided.

It your team does not have a set of guidelines, it takes 15 minutes out of everyone's day to learn and forever changes the way the project's change logs look, hopefully for the better.

The Conventional Commits Specification is not necessarily accepted by everyone--for example, even in 2024, many engineers have [voiced their thoughts](https://www.reddit.com/r/git/comments/1bdfwsy/comment/kun8y67/):

> I don’t buy this conventional commit thing. I admit do look nice when you have a library and generate change log for it. But as an application developer, I write my commits for people, not for tools. In addition, my commits are not a feature or doc. A feature will most likely be many commits, and the docs will be written simultaneously.

Another user says

> The only reason I see for conventional commits is if you would want to generate nicer change logs by parsing the commit messages only. I don’t even think that is a good idea because every commit does not necessarily have to have its own change log line. I don’t really see the point of building a small CMS inside the commit messages.

## Google Engineering Practices Documentation

Google released [a set of guidelines](https://google.github.io/eng-practices/review/developer/cl-descriptions.html) detailing how to write good commit messages that may also fit into your team's workflow. The Google Engineering Practices Documentation actually has two documents:

-   [The Code Reviewer’s Guide](https://google.github.io/eng-practices/review/reviewer/)
    -   A guide for people doing a code review
-   [The Change Author’s Guide](https://google.github.io/eng-practices/review/developer/)
    -   This guide is for developers whose PRs are going through review

If you're looking for more perspectives and other industry accepted best practices, I also highly recommend the above documents.

Also worth calling out is that Google also publishes [style guides for various languages](https://github.com/google/styleguide) that have helped me become a better developer with Python and TypeScript.

## Conclusion

Having some sort of standard got git messages is important for maintaining some level of consistency in a project.

If your team doesn't know where to start, the Conventional Commits Specification takes under 30 minutes to learn and has specific examples, making for an easy entry point for acquiring a standard. It is also easier to enforce a specific standard like Conventional Commits through git hooks. An example of how to do it can be found [here](https://blog.jobins.jp/generate-changelog-from-git-commit-messages)

The Google guide also contains great examples, but is a longer read and goes over the philosophy behind their recommendations. My personal recommendation is the Google guide, but I also like the philosophy of Conventional Commits, and above all I believe that having a standard is better than having no standard.
