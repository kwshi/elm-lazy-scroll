module LazyScroll.Viewport exposing
    ( fromWidthHeight, fromBrowser
    , width, height
    , Viewport
    )

{-| Methods on the `Viewport` type.


# Constructor

@docs fromWidthHeight, fromBrowser


# Property accessors

@docs width, height

-}

import Browser.Dom


{-| The `Viewport` type is a model/state type used to store
information about the current viewport size of some container element
(typically, a scrollable element).

The `Viewport` type currently tracks only two viewport properties:
width and height. For scroll offset/position properties, see the
`LazyScroll.Scroll` module.

-}
type Viewport
    = Viewport Float Float


{-| A basic constructor for `Scroll` types from width and height
parameters.
-}
fromWidthHeight : Float -> Float -> Viewport
fromWidthHeight =
    Viewport


{-| Converts a `Browser.Dom.Viewport` type into a `Scroll` type.
(Note that only the `.viewport.width` and `.viewport.height`
properties of `Browser.Dom.Viewport` are used, so there is no
conversion the other way).
-}
fromBrowser : Browser.Dom.Viewport -> Viewport
fromBrowser { viewport } =
    fromWidthHeight viewport.width viewport.height


{-| Gets the width of a `Viewport`.
-}
width : Viewport -> Float
width (Viewport w _) =
    w


{-| Gets the height of a `Viewport`.
-}
height : Viewport -> Float
height (Viewport _ h) =
    h
