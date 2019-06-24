module LazyScroll.Scroll exposing
    ( fromLeftTop
    , left, top
    , jsonDecoder, jsonMsgDecoder
    , Scroll
    )

{-| Methods on the `Scroll` type.


# Constructor

@docs fromLeftTop


# Property accessors

@docs left, top


# JSON event decoders

@docs jsonDecoder, jsonMsgDecoder

-}

import Json.Decode


{-| The `Scroll` type is a model/state type used to track information
about the current scroll position (JS `.scrollLeft`, `scrollTop`) of
some scrollable container.

The `Scroll` type currently only tracks the JS `scrollLeft` and
`scrollTop` properties, since these are the only two properties that
seem relevant to the scroll state (see `LazyScroll.Viewport` for size
properties), but the author of this library is open to suggestions if
the need for other scroll properties comes up in your use cases! Feel
free to open a GitHub issue.

-}
type Scroll
    = Scroll Float Float


{-| A simple constructor for `Scroll` types from left- and top- scroll
offset values. Generally, this is used to initialize app models with
default values, so sensible starting values to pass this constructor
are `0 0`.
-}
fromLeftTop : Float -> Float -> Scroll
fromLeftTop =
    Scroll


{-| The horizontal scroll offset (JS `.scrollLeft`).
-}
left : Scroll -> Float
left (Scroll l _) =
    l


{-| The vertical scroll offset (JS `.scrollTop`).
-}
top : Scroll -> Float
top (Scroll _ t) =
    t


{-| A JSON decoder for the `scroll` event object to retrieve the
current scroll state of a DOM element. The scroll properties are
accessed on the event by JS properties `.target.scrollLeft` and
`.target.scrollTop`.

This decoder is a "low-level" decoder that directly decodes to a
`Scroll` type; to use this decoder to detect and parse scroll events,
see `jsonMsgDecoder` instead, which decodes scroll events into custom
message types.

-}
jsonDecoder : Json.Decode.Decoder Scroll
jsonDecoder =
    Json.Decode.field "target" <|
        Json.Decode.map2 fromLeftTop
            (Json.Decode.field "scrollLeft" Json.Decode.float)
            (Json.Decode.field "scrollTop" Json.Decode.float)


{-| A JSON decoder for scroll events that returns custom user-defined
message types. This is merely a convenience function that saves you
from having to write `Json.Decode.map` all the time.

For example, if there is a scroll event message type defined as
follows:

    type Msg
        = ScrollMsg LazyScroll.Scroll

to create a `div` element that generates `ScrollMsg`s, one _could_
write

    Html.div
        [ Html.Events.on "scroll" <|
            Json.Decode.map
                ScrollMsg
                LazyScroll.Scroll.jsonDecoder
        ]
        [-- stuff...
        ]

but one may more conveniently write (the author: though it doesn't
look like _that_ much of a time save, I guess, so it doesn't really
matter _that_ much which you use, but it's here if you want it)

    Html.div
        [ Html.Events.on "scroll" <|
            LazyScroll.Scroll.jsonMsgDecoder ScrollMsg
        ]
        [-- stuff...
        ]

-}
jsonMsgDecoder : (Scroll -> msg) -> Json.Decode.Decoder msg
jsonMsgDecoder scrollMsg =
    Json.Decode.map scrollMsg jsonDecoder
