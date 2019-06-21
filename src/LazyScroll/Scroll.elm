module LazyScroll.Scroll exposing
    ( Scroll
    , jsonDecoder
    , left
    , top
    )

import Json.Decode


type Scroll
    = Scroll Float Float


left : Scroll -> Float
left scroll =
    case scroll of
        Scroll l _ ->
            l


top : Scroll -> Float
top scroll =
    case scroll of
        Scroll _ t ->
            t


jsonDecoder : Json.Decode.Decoder Scroll
jsonDecoder =
    Json.Decode.field "target" <|
        Json.Decode.map2 Scroll
            (Json.Decode.field "scrollLeft" Json.Decode.float)
            (Json.Decode.field "scrollTop" Json.Decode.float)
