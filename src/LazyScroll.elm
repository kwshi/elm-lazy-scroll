module LazyScroll exposing
    ( Direction(..)
    , Scroll
    , Viewport
    , getViewport
    , getViewportOf
    , onScroll
    , scroller
    , subscriptions
    )

import Json.Decode
import LazyScroll.Viewport as Viewport
import LazyScroll.Scroll as Scroll
import Browser.Dom
import Browser.Events
import Css
import Html.Styled
import Html.Styled.Attributes
import Html.Styled.Events
import Task


type alias Scroll = Scroll.Scroll
type alias Viewport = Viewport.Viewport

type Direction
    = Horizontal
    | Vertical


getViewport : (Viewport -> msg) -> Cmd msg
getViewport viewportToMsg =
    Cmd.map viewportToMsg <|
        Task.perform Viewport.fromBrowser Browser.Dom.getViewport


getViewportOf : String -> (Result Browser.Dom.Error Viewport -> msg) -> Cmd msg
getViewportOf id viewportToMsg =
    Cmd.map viewportToMsg <|
        Task.attempt
            (Result.map Viewport.fromBrowser)
            (Browser.Dom.getViewportOf id)


subscriptions : (Viewport -> msg) -> Sub msg
subscriptions viewportToMsg =
    Sub.map viewportToMsg <|
        Browser.Events.onResize
            (\w h -> Viewport.fromWidthHeight (toFloat w) (toFloat h))


onScroll : (Scroll -> msg) -> Html.Styled.Attribute msg
onScroll scrollToMsg =
    Html.Styled.Events.on "scroll"
        (Json.Decode.map scrollToMsg Scroll.jsonDecoder)


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
