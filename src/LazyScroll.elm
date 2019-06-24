module LazyScroll exposing
    ( Scroll, Viewport
    , getViewport, getViewportOf
    , Direction(..), scroller
    , onScroll
    , subscribeResize
    )

{-| Core lazy scroller functions.


# Model types

@docs Scroll, Viewport


# Viewport event hooks

@docs getViewport, getViewportOf, subscribeResize


# Main renderer

@docs Direction, scroller


# Miscellaneous helpers

@docs onScroll

-}

import Browser.Dom
import Browser.Events
import Css
import Html.Styled
import Html.Styled.Attributes
import Html.Styled.Events
import Json.Decode
import LazyScroll.Scroll as Scroll
import LazyScroll.Viewport as Viewport
import Task


{-| Convenient alias for `LazyScroll.Scroll.Scroll`.
-}
type alias Scroll =
    Scroll.Scroll


{-| Convenient alias for `LazyScroll.Viewport.Viewport`.
-}
type alias Viewport =
    Viewport.Viewport


{-| An enumeration type used to configure the scroll direction of the
scroller.
-}
type Direction
    = Horizontal
    | Vertical


{-| Generates a `Cmd` that retrieves the browser viewport dimensions
(JS `window.innerWidth`, `window.innerHeight`). The `Cmd` should be
passed to `Browser.application` or `Browser.document` via the `init`
or `update` methods to generate messages containing information about
the viewport size. `getViewport` takes one argument telling it how to
transform a `LazyScroll.Viewport` type into a message type.

The following example demonstrates how to retrieve the browser
viewport size on startup by passing a `getViewport` command in the
`init` argument to `Browser.document`:

    type alias Model =
        { browserVp : LazyScroll.Viewport }

    type Msg
        = BrowserViewport LazyScroll.Viewport

    init : flags -> ( Model, Cmd Msg )
    init model =
        ( { vp = LazyScroll.Viewport.fromWidthHeight 0 0 }
        , LazyScroll.getViewport BrowserViewport
        )

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            BrowserViewport vp ->
                ( { model | browserVp = vp }, Cmd.none )

The following illustrates the flow of commands and messages used to
store the browser viewport information in the example above:

    init
        => LazyScroll.getViewport
        => BrowserViewport
        => update
        => model

`getViewport` commands can also be used in the `update` method to
trigger `getViewport` commands in response to other messages. The
following example illustrates how `getViewport` may be triggered by
`ViewportQuery` message, which may come from a button click, etc.

    type Msg
        = BrowserViewport LazyScroll.Viewport
        | ViewportQuery

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            BrowserViewport vp ->
                ( { model | browserVp = vp }, Cmd.none )

            ViewportQuery ->
                ( model, LazyScroll.getViewport BrowserViewport )

The following illustrates the flow of messages in the example
above:

    ViewportQuery
        => update
        => LazyScroll.getViewport
        => BrowserViewport
        => update
        => model

Note in the that the `LazyScroll.getViewport` command is triggered by
a _different_ message than the `BrowserViewport` message. Be careful not
to generate a `getViewport` command in response to the viewport
message _itself_, or you'll land in an infinite loop!

Note `LazyScroll.getViewport` shares a name with
`Browser.Dom.getViewport`, but they have different signatures
(`Browser.Dom.getViewport` produces a `Task`, whereas
`LazyScroll.getViewport` produces a `Cmd`!). The reason they share a
name is that `LazyScroll.getViewport` is just a thin wrapper around
`Browser.Dom.getViewport`.

-}
getViewport : (Viewport -> msg) -> Cmd msg
getViewport viewportToMsg =
    Cmd.map viewportToMsg <|
        Task.perform
            Viewport.fromBrowser
            Browser.Dom.getViewport


{-| Generates a `Cmd` that retrieves the viewport dimensions (JS
`element.innerWidth`, `element.innerHeight`) of a single scroll
container element, identified by the element's `id`. Similar to
`getViewport`, except this command retrieves the viewport size of a
DOM element instead of the entire browser window.

The following call produces a `Cmd` that retrieves the viewport size
of an element with `id="chatLog"` and returns a
message of type `ViewportSize LazyScroll.Viewport`:

    viewportCmd : Cmd Msg
    viewportCmd =
        getViewportOf "scrollContainer" ViewportSize

Multiple `getViewportOf` and/or `getViewport` commands may be used in
conjunction to keep track of multiple viewport sizes. The following
example uses both methods to keep track of viewport sizes of both
the browser and an element with `id="chatLog"`:

    type alias Model =
        { browserVp : LazyScroll.Viewport
        , chatVp : LazyScroll.Viewport
        }

    type Msg
        = BrowserViewport LazyScroll.Viewport
        | ChatViewport LazyScroll.Viewport

    init : flags -> ( Model, Cmd Msg )
    init =
        ( { browserVp = LazyScroll.Viewport.fromWidthHeight 0 0
          , chatVp = LazyScroll.Viewport.fromWidthHeight 0 0
          }
        , Cmd.batch
            [ LazyScroll.getViewport BrowserViewport
            , LazyScroll.getViewportOf "chatLog" ChatViewport
            ]
        )

    update : Msg -> Model -> Model
    update msg model =
        case msg of
            BrowserViewport vp ->
                ( { model | browserVp = vp }, Cmd.none )

            ChatViewport vp ->
                ( { model | chatVp = vp }, Cmd.none )

The following illustrates the flow of messages in the example above:

    init => { LazyScroll.getViewport   => BrowserViewport }
            { LazyScroll.getViewportOf => ChatViewport    }
         => update
         => model

Note again that `LazyScroll.getViewportOf` shares a name with
`Browser.Dom.getViewportOf` and has a related purpose (it's a thin
wrapper), but they have different signatures.

-}
getViewportOf :
    String
    -> (Result Browser.Dom.Error Viewport -> msg)
    -> Cmd msg
getViewportOf id viewportToMsg =
    Cmd.map viewportToMsg <|
        Task.attempt
            (Result.map Viewport.fromBrowser)
            (Browser.Dom.getViewportOf id)


{-| Produces a `Sub` that generates messages on browser resize events.
The resulting `Sub` should be passed via the to `Browser.application`
or `Browser.document` via the `subscriptions` argument to actually
specify that messages should be produced on resize events.

This method can be used together with the `getViewport` and
`getViewportOf` commands to keep track of the viewport size in real
time. The following example extends the previous examples with a
`subscribeResize` subscription (passed to a `Browser.application` or
`Browser.document` call) to respond to browser resize events and
thereby keep track of the browser viewport size in real time:

    subscriptions : Model -> Sub Msg
    subscriptions model =
        LazyScroll.subscribeResize BrowserViewport

The following illustrates the flow of messages in the above:

    browser resize event
        => LazyScroll.subscribeResize
        => BrowserViewport
        => update
        => model

To keep a real time model of the viewport size of a single DOM element
_that resizes together with the browser viewport_ (say, using some
responsive CSS) instead of the entire browser window, one common
pattern is to trigger the element-specific `getViewportOf` command in
response to a browser resize event. The following example modifies the
previous examples to keep track of the viewport sizes of both the
browser and an element with `id="chatLog"` in real time:

    init : flags -> ( Model, Cmd Msg )
    init flags =
        ( { browserVp = LazyScroll.Viewport.fromWidthHeight 0 0
          , chatVp = LazyScroll.Viewport.fromWidthHeight 0 0
          }
        , LazyScroll.getViewport BrowserViewport
        )

    subscriptions : Model -> Sub.Msg
        LazyScroll.subscribeResize BrowserViewport

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            BrowserViewport vp ->
                ( { model | browserVp = vp }
                , LazyScroll.getViewportOf
                    "chatLog" ChatViewport
                )

            ChatViewport vp ->
                ( { model | chatVp = vp }, Cmd.none )

The following illustrates the flow of messages in the example above:

    { init                   => LazyScroll.getViewport     }
    { (browser resize event) => LazyScroll.subscribeResize }
        => BrowserViewport
        => update
        => { model                                    }
           { LazyScroll.getViewportOf => ChatViewport
                                      => update
                                      => model        }

Again, note that the `ChatViewport` message does not itself trigger
any `getViewport` or `getViewportOf` commands in order to avoid
entering an infinite loop.

Also note that, unlike in an earlier example, the `getViewportOf`
command is _not_ batched with the `getViewport` command, since the
`getViewportOf` call is now produced _after_ (rather than
simultaneously with) the `getViewport` call. If the commands were
batched, then the `getViewportOf` command would be triggered _twice_:
once in the batch command, then again in response to the
`BrowserViewport` event. It would not be the end of the world if you
accidentally do batch the two commands, but it would perform redundant
work, so it is good practice to avoid doing so.

-}
subscribeResize : (Viewport -> msg) -> Sub msg
subscribeResize viewportToMsg =
    Sub.map viewportToMsg <|
        Browser.Events.onResize
            (\w h ->
                Viewport.fromWidthHeight
                    (toFloat w)
                    (toFloat h)
            )


{-| A scroll event attribute that provides data about the scroll
offsets (JS `.scrollTop`, `.scrollLeft`).
-}
onScroll : (Scroll -> msg) -> Html.Styled.Attribute msg
onScroll scrollToMsg =
    Html.Styled.Events.on "scroll"
        (Json.Decode.map scrollToMsg Scroll.jsonDecoder)


{-| The main lazy-scroll renderer. `scroller` receives as its first
argument a record containing options to configure its rendering:

  - `direction`: The scroller's scroll direction.

  - `itemSize`: The size (height for vertical scrollers, or width for
    horizontal scrollers) of each item in the scrollable list.

    Having to provide a fixed size for each element is the main
    downside of this lazy scroller, but it seems unavoidable because
    knowing the fixed size of each element is, as far as the author of
    this library is aware, the only efficient way to compute which
    items to lazily render. If you have better ideas on how to do
    such a computation, feel free to open an issue on GitHub!

  - `margin`: The padding between the item list and the edge of the
    scroll container. Note that `margin` only sets the margin _along_
    the scroll direction; to set item margins in the other direction,
    apply a relevant CSS style (example for vertical scrollers:
    `marginLeft: 1em; marginRight: 1em`) to the individual list
    elements returned by `viewItem`. The `margin` option is analogous
    to the concept of _padding_ in
    [`elm-ui`][elm-ui].

  - `spacing`: The separation between successive list items. The
    `spacing` option is the same concept of _spacing_ as in
    [`elm-ui`][elm-ui].

  - `scrollMsg`: A function that converts a `Scroll` type into some
    user-defined message type, to be generated by scroll events.

  - `viewItem`: A function that, given an individual list item,
    renders the corresponding element as an `Html.Styled.Html`. This
    function will be called by the scroller to render list elements.

The second argument provides the actual model/state parameters:

  - `viewport`: The current size of the scroll container viewport.
    The scroller uses the viewport size to compute how many elements
    to render at a time.

    You may pass a `viewport` a `Viewport` object _larger_ dimensions
    than the actual scroll container's dimensions without issue (a few
    additional hidden elements will be rendered, which may
    _marginally_ slow down the scroller, but almost certainly to a
    noticeable extent). Thus, if you prefer to avoid relying on HTML
    attributes (i.e. `id`s) to retrieve scroll information, you can
    instead provide the _browser_ viewport size (retrieved via
    `getViewport`) to this parameter.  Another benefit of this
    approach is that, by only using the browser viewport, it saves you
    from having to keep track of multiple viewport sizes in your
    model.

  - `scroll`: The current scroll position within the scroller. The
    scroller uses the scroll position to compute _which_ elements to
    render, and which elements to omit.

  - `items`: The list of items (e.g. chat messages, contacts, menu
    items, etc.) to be rendered in the scroller.

The rendered scroller element has CSS properties `width: 100%` and
`height: 100%`. To control the position and size of the scroller, put
it in a wrapper element (e.g. a simple `div`) and position the wrapper
element, and the scroller will scale to fit.

[elm-ui]: https://package.elm-lang.org/packages/mdgriffith/elm-ui/latest/Element#padding-and-spacing

-}
scroller :
    { direction : Direction
    , itemSize : Float
    , margin : Float
    , spacing : Float
    , scrollMsg : Scroll -> msg
    , viewItem : item -> Html.Styled.Html msg
    }
    ->
        { viewport : Viewport
        , scroll : Scroll
        , items : List item
        }
    -> Html.Styled.Html msg
scroller options =
    let
        groupSize =
            options.itemSize + options.spacing

        { overflow, size, altSize, offset, vpSize, scOffset } =
            case options.direction of
                Horizontal ->
                    { overflow = Css.overflowX
                    , size = Css.width
                    , altSize = Css.height
                    , offset = Css.left
                    , vpSize = Viewport.width
                    , scOffset = Scroll.left
                    }

                Vertical ->
                    { overflow = Css.overflowY
                    , size = Css.height
                    , altSize = Css.width
                    , offset = Css.top
                    , vpSize = Viewport.height
                    , scOffset = Scroll.top
                    }

        containerStyle =
            Html.Styled.Attributes.css
                [ overflow Css.scroll
                , Css.height (Css.pct 100)
                , Css.width (Css.pct 100)
                ]

        placeholderStyle =
            Html.Styled.Attributes.css
                [ Css.position Css.relative ]

        placeholderSize itemCount =
            (toFloat itemCount * groupSize)
                - options.spacing
                + (2 * options.margin)

        placeholderSizeStyle itemCount =
            Html.Styled.Attributes.css
                [ size <| Css.px <| placeholderSize itemCount ]

        itemStyle =
            Html.Styled.Attributes.css
                [ Css.position Css.absolute
                , altSize <| Css.pct 100
                , size <| Css.px options.itemSize
                ]

        itemOffset i =
            toFloat i * groupSize + options.margin

        itemOffsetStyle i =
            Html.Styled.Attributes.css
                [ offset <| Css.px <| itemOffset i ]

        itemContainer ( i, item ) =
            Html.Styled.div
                [ itemStyle, itemOffsetStyle i ]
                [ options.viewItem item ]

        takeCount vp =
            ceiling <| 3 * vp / groupSize

        dropCount vp sc =
            floor <| (sc - vp) / groupSize

        enumerate l =
            List.indexedMap (\i v -> ( i, v )) l

        takeDrop vp sc items =
            List.take (takeCount vp) <|
                List.drop (dropCount vp sc) items
    in
    \{ viewport, scroll, items } ->
        Html.Styled.div
            [ containerStyle, onScroll options.scrollMsg ]
            [ Html.Styled.div
                [ placeholderStyle
                , placeholderSizeStyle <| List.length items
                ]
              <|
                List.map itemContainer <|
                    takeDrop (vpSize viewport) (scOffset scroll) <|
                        enumerate items
            ]
