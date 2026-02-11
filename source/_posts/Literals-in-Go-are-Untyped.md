---
title: Literals in Go are Untyped
date: 2026-02-11 13:56:30
tags:
categories:
---

I wasn't sure if this topic warranted its own post or not, but upon first encountering this statement, I did a double take.

What do you mean they're untyped? Are you telling me that `"hello"` is not a string?

And the answer is... That's correct!

When you write a literal like `"hello"`, `42`, or `3.14`, it does have a **default type** (string, int, float64 respectively), but it's not _committed_ to that type yet. Go calls these "untyped constants."

The moment these literals get assigned to a variable or used in a context that demands a concrete type, it resolves. You can think of it as the literal being flexible right up until Go _needs_ to commit.

## Why does this matter?

This flexibility means untyped literals can flow into compatible types without an explicit conversion. Consider this:

```go
type Celsius float64

var temp Celsius = 36.6 // works!
```

If `36.6` were already typed as `float64`, this would fail — Go doesn't allow implicit conversions between named types. You'd have to write `Celsius(36.6)` instead. But because `36.6` is an untyped constant, it happily adapts to `Celsius`.

The same applies to strings:

```go
type Greeting string

var g Greeting = "hello" // works!
```

No cast needed because `"hello"` hasn't committed to `string` yet.

## So when _does_ it become typed?

When Go has no type context to guide it, it falls back to the default type:

```go
s := "hello" // s is of type string
x := 42      // x is of type int
f := 3.14    // f is of type float64
```

Here, `:=` asks Go to infer a type, and with nothing else to go on, it reaches for the default. At this point, `s` is a `string` — concrete and committed.

## The takeaway

"Untyped" doesn't mean "no type information." It means the literal is flexible — a kind of superposition of compatible types that collapses into a concrete one only when it needs to. It's a small detail, but it's one of those things that makes Go's type system feel surprisingly ergonomic for a statically typed language.