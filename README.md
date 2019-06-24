## `elm-lazy-scroll`: Seamless lazy-rendered scrolling in Elm.

Do you need to render *large* scrollable lists of data in your Elm
app?  Have you noticed Elm slowing down significantly when it tries to
render lists containing thousands of elements?  Are you looking for
something *like* [infinite scrolling][elm-infinite-scroll], but
bottleneck isn't content loading times, it's the cost of rendering a
*million* DOM elements?

Try `elm-lazy-scroll`!  It allows you to efficiently render large
scrollable lists by rendering DOM lazily.  You provide a render
function `viewItem`, and the scroller calls `viewItem` *only* on the
twenty-or-so that actually are visible in the scroll pane.  Fast, and
saves effort!  Now you can handle millions of list items without
actually making millions of DOM elements!

(This library is inspired, in some sense, by the React component
[`react-virtualized`][react-virtualized].)

# Features

- Fast: capable of rendering *large* lists of data smoothly
  (tested successfully with up to ~50k elements).
- Seamless: virtually indistinguishable from plain, `overflow: scroll`
  elements.  No janky scrollbars, no "load more" buttons, no "loading"
  spinners, etc.
- Mobile-friendly: behaves the same as any scrollable element.

# Demos

- They are coming soon!  Keep your eyes peeled.

# Installation

Using the official Elm package manager:
```sh
elm install kwshi/elm-lazy-scroll
```

# Usage

## Documentation

The documentation for `elm-lazy-scroll` can be found on the official
Elm package documentation pages, once this package is published...

## Examples

See [demos](#demos).


# FAQ

## Comparison with [`elm-infinite-scroll`][elm-infinite-scroll]



# How does it work?

[react-virtualized]: https://github.com/bvaughn/react-virtualized
[elm-infinite-scroll]: https://github.com/FabienHenon/elm-infinite-scroll
