---
title: "The Case Against Conventional Commit"
---

====================================
The Case Against Conventional Commit
====================================

`Conventional Commits`_ is a standard for structured git commit messages, which is quickly 
becoming pervasive. On any given project, there are probably several contributors using
it in messages on commits and PRs, even if not required.

However, I will attempt to make the case that if not strictly followed, Conventional Commit
quickly loses it's meaning.

Conventional Commits Primer
===========================

  Conventional Commits is a specification for adding human machine and machine readable 
  structure to commit messages

  -- Conventional Commit Documentation

Conventional Commit is a lightweight structure on top of git commit messages. The
structure looks like this::

    <type>[optional scope]: <description>

    [optional body]

    [optional footer(s)]

Typically, type can be one of: fix, feat, BREAKING CHANGE, build, chore, ci, doc, or test.
Optional scope can provide extra contextual information, most commonly a component such as
api, ui, or cli. For example::

    fix(api): prevent racing of requests

    Introduce a request id and a reference to latest request. Dismiss
    incoming responses other than from latest request.

    Remove timeouts which were used to mitigate the racing issue but are
    obsolete now.

The benefits of Conventional Commit are a strong selling point:

* Tooling can automatically generate changelogs and releases
* Communicating the nature of changes
* Commit logs are easy to scan

Disadvantages of Conventional Commits
=====================================

I'll concede that when strictly followed, Conventional Commits can dramatically improve
readability of commit logs. Having the type and scope can make it easier to scan the 
history.

Unfortunately, in my experience, this is rarely the case. When 
not strictly followed, the case against Conventional Commit is strong:

* Commit messages are inconsistent
* Type and scope uses up space that could be used in the short description
* Plain English often reads better
* Structure doesn't replace descriptive commit messages

When not strictly followed, you can no longer easily scan the git commit log or use
automation. In my opinion, this negates all the benefits.

The subject line should be short, 50 characters is widely considered the standard. If
you're using Conventional Commit, you have already lost about 5-10 characters.

**Writing good descriptive messages for your changes is much more important than the
structure.**

When to Use Conventional Commits
================================

I actually do think that Conventional Commits can be used effectively, provided that
you:

* Strictly enforce the message structure
* Use tooling to generate release notes
* Write good descriptive messages

Good Descriptive Commit Messages
================================

Whether or not you use Conventional Commits, you should write well formed, thoughtful
commit messages.

Well Formed Messages
--------------------

The format of commit messages is largely standardized. Follow
`The Seven Rules`_:

1. Separate subject from body with a blank line
2. Limit the subject line to 50 characters
3. Capitalize the subject line
4. Do not end the subject line with a period
5. Use the imperative mood in the subject line
6. Wrap the body at 72 characters
7. Use the body to explain what and why vs. how

For example,

::

    Summarize changes in around 50 characters or less

    More detailed explanatory text, if necessary. Wrap it to about 72
    characters or so. In some contexts, the first line is treated as the
    subject of the commit and the rest of the text as the body. The
    blank line separating the summary from the body is critical (unless
    you omit the body entirely); various tools like `log`, `shortlog`
    and `rebase` can get confused if you run the two together.

    Explain the problem that this commit is solving. Focus on why you
    are making this change as opposed to how (the code explains that).
    Are there side effects or other unintuitive consequences of this
    change? Here's the place to explain them.

    Further paragraphs come after blank lines.

    - Bullet points are okay, too

    - Typically a hyphen or asterisk is used for the bullet, preceded
      by a single space, with blank lines in between, but conventions
      vary here

    If you use an issue tracker, put references to them at the bottom,
    like this:

    Resolves: #123
    See also: #456, #789

Thoughtful Messages
-------------------

The message content is the most important thing. As a general litmus test, consider:

  Does the commit message all the information required to review the changes?

To come up with thoughtful messages, ask yourself:

1. What have I changed?
2. Why have I made these changes?
3. What effect have my changes made?
4. Why was the change needed?

As you write your message, keep the following guidelines in mind:

**The subject line is the most important:** The subject line is the only thing that will
show in commands such as `git log --oneline`, so it should be a good, concise summary of
the change.

**Use the body to explain the what and why:** The body is the place to context. Focus on
the problem the commit is solving and why you are making the change. Do not focus on how
the change was made, but if it contains important context, it can go here too.

**Do not assume the reviewer has access to the issue tracker:** Having to leave the PR to
look up a ticket is painful. Put everything needed in the message to fully review the
change. However, ticket numbers are important for tooling integration, so put references
to them in the bottom of the body. Avoid putting them in the subject line.

**Review the message to see if it should this be split into multiple commits:** 
Sometimes, commit messages can reveal the change would be easier to review as multiple
independent changes. Do not be afraid to rebase and split it up into multiple commits.

Conclusion
==========

If not used correctly and consistently, conventional commits can actually hurt
readability. If you're not strictly enforcing message structure, seriously consider
whether conventional commits are adding any value.

Whether or not you use conventional commit, you should write thoughtful, well formed
commit messages. Remember to keep the subject clear and concise while adding detailed
explanation in the body. Remember, less is not more.

Resources
=========

This post was compiled from several excellent sources:

* `Conventional Commits`_
* `The Seven Rules`_
* `How to Write Better Commit Messages`_
* `Git Commit Good Practice`_

.. _Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
.. _The Seven Rules: https://cbea.ms/git-commit/
.. _How to Write Better Commit Messages: https://www.freecodecamp.org/news/how-to-write-better-git-commit-messages/
.. _Git Commit Good Practice: https://wiki.openstack.org/wiki/GitCommitMessages
