# Versioner

This is a language agnostic git versioning tool using tags.

## Why this repo

There are plenty of tools available that can generate a version based on Git tags.
However, they are typically:

- driven by commit messages, not configuration
- dependent on programming languages

I didn't want to have to introduce a programming language into my pipeline, especially when it was a language that had
absolutely nothing to do with my pipeline, e.g. using an action implemented in JS in a Python project.
I also didn't feel like commit messages were the way to go, typos happen, and then someone needs to go and update it
manually.

The aim has been to have a very simple approach at versioning without introducing new dependencies, and for it to be
configuration driven.

## How to use it

Inside your GHA pipeline, simply add the following step:

```yaml
    - uses: DragosDumitrache/versioner/versioner@v2.6.1
```

Incrementing the `major` or `minor` versions is done simply through a bump in your project's
corresponding `version.json` file. When this happens, the `patch` number is reset to 0. In all other cases, the `patch`
version is incrementally calculated from the number of commits added since the previous patch. For consecutive patches,
this approach works best with the `Squash and Merge` strategy.

