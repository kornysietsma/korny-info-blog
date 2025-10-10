---
title: "Better Claude Code permissions"
categories: ['AI', 'Development']
date: 2025-10-10
tags: [claude-code, permissions, rust]
toc: false
---

This is a short post (two in one day!) to talk about a new tool I've written to help with Claude Code permissions.

_Note_ see also my standard [AI Disclaimer](/ai-disclaimer/)

## The problem with permissions

In [my previous post](/2025/10/10/agent-mermaid-reporting-for-duty/) I mentioned a frustrating issue with Claude Code - it kept asking me to approve the same commands over and over again. The [documentation says you can use wildcards in permissions](https://docs.claude.com/en/docs/claude-code/iam#tool-specific-permission-rules) but in practice, even simple patterns don't work reliably. I'd give it permissions like `Bash(rm /tmp/mermaid:*)` and it would _still_ ask me every single time it wanted to delete a temporary mermaid file.

## The solution: hooks

Fortunately, Claude Code has an alternative approach: [hooks](https://docs.claude.com/en/docs/claude-code/iam#additional-permission-control-with-hooks). You can write a script that runs before every tool use, and that script can approve or deny the operation. This is exactly what I needed - a way to say "yes, Claude can run mermaid-cli commands without asking me every time" without dangerously-skip-permissions or any such foolishness.

So I threw together [claude-code-permissions-hook](https://github.com/kornysietsma/claude-code-permissions-hook), a configurable permission handler that uses regular expressions to allow or deny tool usage.

## Why Rust?

I could have written this in Python or JavaScript or any scripting language. But I chose Rust for three reasons:

First, performance. Yes, premature optimisation is the root of a lot of evil. For almost all my AI stuff I'm using Python, it is simple, expressive, and [you can build it into a single executable script using uv](https://docs.astral.sh/uv/guides/scripts/), which is great for quick things. But - this hook runs _on every single tool use_. Rust compiles to fast binaries with no startup cost.

Second, Rust is fun - I really enjoy using it, it's fast, modern, has great tooling. It can get complex when you do complex things - async coding or dealing with mutable state - but for a simple cli tool it is great. [Take a look at some code - it's not _that_ complex, even vibe-coded code!](https://github.com/kornysietsma/claude-code-permissions-hook/blob/main/src/main.rs)

And thirdly, Rust is a good language for an agentic LLM tool. I've seen suggestions in the past that LLMs struggled with Rust, due to its newness and complexity, but so far I haven't had that problem; admittedly I haven't done anything complicated. But the advantage of a strict type system, explicit error handling, and built in linting and hints and tests, make it easy for a tool like Claude Code to iterate until it gets something semi-decent.

Claude Code vibe-coded 95% of this tool, with a fairly short prompt and only a few hints - I think it took me longer to write this blog post!  (Note that when I say "vibe coded" - I still checked every line before committing anything - I don't trust the AIs _that_ much)

## How it works

The hook is quite simple:

1. Every time Claude Code plans to call a tool, it looks through its configuration for a `PreToolUse` entry that matches the tool, and sees that it should call `claude-code-permissions-hook`
2. Claude Code sends a JSON payload describing the tool it wants to use
3. The hook loads a TOML configuration file with allow/deny rules and logging settings
4. It checks deny rules first (these take precedence)
5. Then it checks allow rules
6. If something matches, it outputs an allow or deny decision
7. If nothing matches, it outputs nothing (which means Claude's normal permissions apply)
8. Logging rules are checked - even with no matches, verbose logging kicks in so you can diagnose stuff

Here's the configuration I use for running the Mermaid agent:

```toml
# Allow npx mermaid-cli mmdc commands (but exclude pipes, background jobs, etc.)
[[allow]]
tool = "Bash"
command_regex = "^npx -p @mermaid-js/mermaid-cli mmdc "
command_exclude_regex = "&|;|\\||`"

# Allow reading files in /tmp/mermaid-test-automation (but exclude parent navigation)
[[allow]]
tool = "Read"
file_path_regex = "^/tmp/mermaid-test-automation"
file_path_exclude_regex = "\\.\\."

# Allow rm commands for mermaid test files (with or without -f)
[[allow]]
tool = "Bash"
command_regex = "^rm (-f )?/tmp/mermaid-test-automation"
command_exclude_regex = "&|;|\\||`|\\$\\(|\\.\\."
```

The `exclude_regex` is handy - you can write "allow this pattern, but not if it also matches this other pattern" which makes it easier to write rules like "allow cargo commands, but not if they contain shell injection characters".

I won't go into too much detail here - the [README on GitHub](https://github.com/kornysietsma/claude-code-permissions-hook) covers installation and configuration.

## Caveats

This is very much a "just solve an immediate problem" tool. I haven't packaged it up nicely, there's no installer, you need to build it yourself with `cargo build --release`. No warranty is provided! I suspect the tool may be short-lived, Anthropic will probably fix their permissions and then I'll need this much less - though it's handy to be able to add my own specific bypasses here!

## Does it work?

Absolutely. I can now draw mermaid diagrams without drowning in permission prompts. I can log what tools I use, and change tweaks as I want. And, I can configure exactly what Claude can and can't do - I could see extending this to be more specific if I need to; it's just code.

And I got to write some Rust, which is always fun.

If you're having similar frustrations with Claude Code permissions, [give it a try](https://github.com/kornysietsma/claude-code-permissions-hook). If you're not comfortable building Rust code, you could easily take the ideas here and implement them in your language of choice - the concepts are pretty simple.
