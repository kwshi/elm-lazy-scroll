module Main exposing (main)

import Browser
import Css
import Html.Styled
import Html.Styled.Attributes
import Html.Styled.Events
import LazyScroll


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { focus : Int
    , viewport : LazyScroll.Viewport
    , scroll : LazyScroll.Scroll
    }


type Msg
    = Viewport LazyScroll.Viewport
    | Scroll LazyScroll.Scroll
    | Focus Int


init : () -> ( Model, Cmd Msg )
init _ =
    ( { focus = 0
      , viewport = LazyScroll.Viewport 0 0
      , scroll = LazyScroll.Scroll 0 0
      }
    , LazyScroll.initCmd Viewport
    )


subscriptions : Model -> Sub msg
subscriptions _ =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Viewport vp ->
            ( { model | viewport = vp }, Cmd.none )

        Scroll s ->
            ( { model | scroll = s }, Cmd.none )

        Focus n ->
            ( { model | focus = n }, Cmd.none )


testData : List Int
testData =
    List.range 0 5000


viewItem : Int -> Html.Styled.Html Msg
viewItem num =
    Html.Styled.div
        [ Html.Styled.Events.onClick <| Focus num
        , Html.Styled.Attributes.css
            [ Css.backgroundColor <| Css.rgb 220 245 200
            , Css.cursor Css.pointer
            , Css.marginLeft <| Css.px 10
            , Css.marginRight <| Css.px 10
            , Css.height <| Css.pct 100
            , Css.displayFlex
            , Css.flexFlow2 Css.column Css.noWrap
            , Css.justifyContent Css.center
            ]
        ]
        [ Html.Styled.text <| String.fromInt num ]

scroller: LazyScroll.Model Int -> Html.Styled.Html Msg
scroller =
    LazyScroll.scroller
        { direction = LazyScroll.Vertical
        , itemSize = 30
        , margin = 10
        , spacing = 10
        , scrollMsg = Scroll
        , viewItem = viewItem
        }


view : Model -> Browser.Document Msg
view model =
    { title = "hi"
    , body =
        [ Html.Styled.toUnstyled <|
            Html.Styled.div
                []
                [ Html.Styled.div
                    [ Html.Styled.Attributes.css
                        [ Css.height <| Css.vh 40
                        , Css.borderStyle Css.solid
                        , Css.width <| Css.px 400
                        ]
                    ]
                    [ scroller
                        { viewport = model.viewport
                        , scroll = model.scroll
                        , items = testData
                        }
                    ]
                , Html.Styled.text <| String.fromInt model.focus
                ]
        ]
    }
