module LazyScroll exposing
    ( Direction(..)
    , Model
    , Options
    , Scroll
    , Viewport
    , initCmd
    , onScroll
    , scroller
    , subscriptions
    )

import Browser.Dom
import Browser.Events
import Css
import Html.Styled
import Html.Styled.Attributes
import Html.Styled.Events
import Json.Decode
import Task


type alias Scroll =
    { left : Float, top : Float }


type alias Viewport =
    { width : Float, height : Float }


type Direction
    = Horizontal
    | Vertical


type alias Options item msg =
    { direction : Direction
    , itemSize : Float
    , margin : Float
    , spacing : Float
    , scrollMsg : Scroll -> msg
    , viewItem : item -> Html.Styled.Html msg
    }


type alias Model item =
    { viewport : Viewport, scroll : Scroll, items : List item }


initCmd : (Viewport -> msg) -> Cmd msg
initCmd transform =
    Task.perform
        (\{ viewport } ->
            transform (Viewport viewport.width viewport.height)
        )
        Browser.Dom.getViewport


subscriptions : (Viewport -> msg) -> Sub msg
subscriptions transform =
    Browser.Events.onResize
        (\w h -> transform <| Viewport (toFloat w) (toFloat h))


decodeScroll : Json.Decode.Decoder Scroll
decodeScroll =
    Json.Decode.field "target" <|
        Json.Decode.map2 Scroll
            (Json.Decode.field "scrollLeft" Json.Decode.float)
            (Json.Decode.field "scrollTop" Json.Decode.float)


onScroll : (Scroll -> msg) -> Html.Styled.Attribute msg
onScroll scrollToMsg =
    Html.Styled.Events.on "scroll"
        (Json.Decode.map scrollToMsg decodeScroll)


scroller : Options item msg -> Model item -> Html.Styled.Html msg
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
                    , vpSize = .width
                    , scOffset = .left
                    }

                Vertical ->
                    { overflow = Css.overflowY
                    , size = Css.height
                    , altSize = Css.width
                    , offset = Css.top
                    , vpSize = .height
                    , scOffset = .top
                    }

        containerStyle =
            Html.Styled.Attributes.css
                [ overflow Css.scroll
                , Css.height (Css.pct 100)
                , Css.width (Css.pct 100)
                ]

        containerAttributes =
            [ containerStyle, onScroll options.scrollMsg ]

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

        placeholderAttributes itemCount =
            [ placeholderStyle, placeholderSizeStyle itemCount ]

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

        itemAttributes i =
            [ itemStyle, itemOffsetStyle i ]

        itemContainer ( i, item ) =
            Html.Styled.div (itemAttributes i) [ options.viewItem item ]

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
        Html.Styled.div containerAttributes
            [ Html.Styled.div (placeholderAttributes <| List.length items) <|
                List.map itemContainer <|
                    takeDrop (vpSize viewport) (scOffset scroll) <|
                        enumerate items
            ]
