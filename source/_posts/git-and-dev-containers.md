---
title: (Guide) Understanding Navigating Git in a dev container
tags:
    - devops
    - containers
    - docker
    - ssh-agent
    - git
date: 2024-07-04 04:21:29
---

## Background

When using dev containers for development, it's important that we can use git commands while still inside the container. Without this ability, we would have to exit the container before using git commands, which would be quite cumbersome.

On [VS Code's website](https://code.visualstudio.com/docs/devcontainers/containers), they state:

> Working with Git?
> Here are two tips to consider:
> If you are working with the same repository both locally in Windows and inside a container, be sure to set up consistent line endings. [See tips and tricks for details.](https://code.visualstudio.com/docs/remote/troubleshooting#_resolving-git-line-ending-issues-in-wsl-resulting-in-many-modified-files)

> If you clone using a Git credential manager, your container should already have access to your credentials! If you use SSH keys, you can also opt in to sharing them. See [Sharing Git credentials with your container for details.](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials)

There is a chance that git will just work out of the box, but this has not been my case. This article will explain my experiences and how to avoid my own pitfalls.

## Setting up Git Credentials in a Dev Container

There are two ways to use git through a dev container. The first way involves git's credential helper.

### Git and Dev Containers Method 1: Credential Helper

The first thing is to actually make sure git is installed in your image. Lots of images come with git, but if they don't, you may need to add a line into your Dockerfile

<!-- Debian Based Distros -->

`apt-get install -y vim git`

<!-- RPM Based Distros -->

`dnf install git`

From the official documentation:

> If you use HTTPS to clone your repositories and have a credential helper configured in your local OS, no further setup is required. Credentials you've entered locally will be reused in the container and vice versa.

You can visually check to see the credential helper in action: from within your container, type in `git config --list`

You should see something like...

`credential.helper=!f() { stuff here }`

This was inserted by the dev containers extension through VS Code. Let's dig deeper:

```
cat ~/.gitconfig
...
...
[credential]
	helper = "!f() { ...stuff here... }

```

This credential helper is responsible for some pretty magical things.

-   When you run a git command that needs authentication, git inside the container requests credentials
-   The git credential helper set up by VS Code intercepts this request
-   The credential helper communicates with the VS Code server process running in the container
-   This server process then communicates with the VS Code client on your host machine.
-   The VS Code client on your host machine interacts with your local SSH agent to get the necessary credentials
-   These credentials are then passed back through the chain to authenticate your git operation

If you are not using a credential helper, or do not wish to use one, we can still securely work within a dev container through ssh user agent forwarding.

### Git and Dev Containers Method 2: SSH User Agent Forwarding

In the advanced section of `sharing Git credentials with your container`, the documentation states:

> There are some cases when you may be cloning your repository using SSH keys instead of a credential helper. To enable this scenario, the extension will automatically forward your local SSH agent if one is running.

This is quite convenient! For those who may not be familiar with SSH user agent forwarding, let's explore SSH Agents in more detail.

## What are SSH Agents?

An SSH Agent is nothing more than a key manager for SSH. Keys are held in memory and are used for signing messages. Throwing keys into the agent is as simple as `ssh-add $HOME/.ssh/<your ssh key>`.

When you connect to some remote server (your container in this scenario), the SSH client authenticates via the agent.

There is one particular feature that makes developing within containers secure and possible: SSH user agent forwarding.

## User Agent Forwarding

SSH user agent forwarding enables developers to use keys on remote systems without needing to copy the keys over from their local machine to their remote. In other words, a remote host is able to effectively borrow your private keys, without your private keys actually being exposed or leaving your local system.

To achieve this, you:

-   enable agent forwarding when connecting to the first remote server (docker container in this case). It might be as simple as setting it in your .ssh/config, like:

```bash
Host github.com
  AddKeysToAgent yes

Host myServer
  AddKeysToAgent yes
```

-   when logged into a remote system, you can verify that the agent is being forwarded correctly by checking that the key in memory matches both locally and remotely: `ssh-add -l`

```bash
local@dev $ ssh-add -l
256 SHA256:/pARi... (email) (encryption)

(from dev container)
remote@9726a2548ae8:/app# ssh-add -l
256 SHA256:/pARi... (email) (encryption)
```

-   when using git commands (specifically push, pull, clone, fetch), it actually runs the system's ssh, which in turn leverages the agent for message signing and authentication!

By this point, hopefully it works. If not, perhaps the below will help you debug:

## Pitfalls

One pitfall was that I had a remote with a URL that looked like this:

```
root@9726a2548ae8:/app# git remote -v
origin  git@personal.github.com:<name>/<repo>.git (fetch)
origin  git@personal.github.com:<name>/<repo>.git (push)
```

When I tried using git push / git pull / git fetch / etc, it seemed to just.. hang.

To discover the culprit, I ran
`GIT_TRACE=true git pull`

```
root@9726a2548ae8:/app# GIT_TRACE=true git pull
02:16:17.326891 git.c:460               trace: built-in: git pull
02:16:17.351613 run-command.c:655       trace: run_command: git fetch --update-head-ok
02:16:17.359033 git.c:460               trace: built-in: git fetch --update-head-ok
02:16:17.391809 run-command.c:655       trace: run_command: unset GIT_PREFIX; GIT_PROTOCOL=version=2 ssh -o SendEnv=GIT_PROTOCOL git@personal.github.com 'git-upload-pack '\''<user>/<repo>.git'\'''
```

And that's where it occured to me that git has no idea what to do with the host `personal.github.com`. The ssh-agent knows nothing about how it should handle this!

So I went into `~/.ssh/config` and added this entry:

```bash
Host personal.github.com
  HostName github.com
```

And everything fell into place.

```bash
root@9726a2548ae8:/app# GIT_TRACE=true git pull
02:21:23.413813 git.c:460               trace: built-in: git pull
02:21:23.433939 run-command.c:655       trace: run_command: git fetch --update-head-ok
02:21:23.442161 git.c:460               trace: built-in: git fetch --update-head-ok
02:21:23.473589 run-command.c:655       trace: run_command: unset GIT_PREFIX; GIT_PROTOCOL=version=2 ssh -o SendEnv=GIT_PROTOCOL git@personal.github.com 'git-upload-pack '\''<user>/<repo>.git'\'''
02:21:25.392300 run-command.c:655       trace: run_command: git rev-list --objects --stdin --not --all --quiet --alternate-refs
02:21:25.626777 run-command.c:1523      run_processes_parallel: preparing to run up to 1 tasks
02:21:25.628426 run-command.c:1551      run_processes_parallel: done
02:21:25.628455 run-command.c:655       trace: run_command: git maintenance run --auto --no-quiet
02:21:25.635209 git.c:460               trace: built-in: git maintenance run --auto --no-quiet
02:21:25.666329 run-command.c:655       trace: run_command: git merge FETCH_HEAD
02:21:25.674428 git.c:460               trace: built-in: git merge FETCH_HEAD
Already up to date.
```

## Conclusion

Copying over your private keys breaks a core principle of security--private keys should never leave your system. We also want to keep complexity to a minimum by not introducing private keys on a per-host basis, as this would not be feasible if you were tasked with working with numerous machines.
