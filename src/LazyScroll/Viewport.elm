module LazyScroll.Viewport exposing
    ( Viewport
    , fromBrowser
    , fromWidthHeight
    , height
    , width
    )

import Browser.Dom

type Viewport
    = Viewport Float Float

fromWidthHeight : Float -> Float -> Viewport
fromWidthHeight = Viewport

width : Viewport -> Float
width viewport =
    case viewport of
        Viewport w _ ->
            w


height : Viewport -> Float
height viewport =
    case viewport of
        Viewport _ h ->
            h


fromBrowser : Browser.Dom.Viewport -> Viewport
fromBrowser { viewport } =
    Viewport viewport.width viewport.height
