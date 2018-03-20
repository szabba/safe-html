module Html.Safe
    exposing
        ( SafeHtml
        , UnsafeHtmlUsage(..)
        , nodeOrError
        , nodeOrLog
        , nodeOrNothing
        , nodeOrSend
        , toHtml
        )

{-| A library for building safe(-er) view functions.

@docs SafeHtml, toHtml

@docs nodeOrError, UnsafeHtmlUsage, nodeOrNothing, nodeOrLog, nodeOrSend

-}

import Html exposing (Attribute, Html)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Result.Extra as Result


{-| A piece of HTML with some extra safety guarantees.
-}
type SafeHtml msg
    = SafeHtml (Html msg)


{-| A type describing the possible reasons for which a safe HTML node could not be constructed.
-}
type UnsafeHtmlUsage
    = UnsafeTag String


{-| Converts safe HTML to ordinary (ie, potentially unsafe) HTML.
-}
toHtml : SafeHtml msg -> Html msg
toHtml (SafeHtml html) =
    html


{-| Tries to build a safe HTML node.

This is analogous to [`Html.node`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#node).
The difference is that `nodeOrError` can fail to create safe HTML and will tell you why.

    nodeOrError "script" [] [] == Err (UnsafeTag "script")

-}
nodeOrError : String -> List (Attribute msg) -> List (SafeHtml msg) -> Result UnsafeHtmlUsage (SafeHtml msg)
nodeOrError name attrs children =
    if name == "script" then
        Err <| UnsafeTag name
    else
        Ok <| SafeHtml <| Html.node name attrs <| List.map toHtml children


{-| Tries to build a safe HTML node.

This is analogous to [`Html.node`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#node).
The difference is that `nodeOrNothing` can fail to create safe HTML and will tell you why.

    nodeOrNothing "script" [] [] == Nothing

Unlike `nodeOrError` this function will not tell you what the issue with building the view is.

-}
nodeOrNothing : String -> List (Attribute msg) -> List (SafeHtml msg) -> Maybe (SafeHtml msg)
nodeOrNothing name attrs children =
    nodeOrError name attrs children
        |> Result.toMaybe


{-| Builds a safe HTML node.

This is analogous to [`Html.node`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#node).
The difference is that `nodeOrLog` will skip unsafe nodes and report that in the browser console.

Unlike `nodeOrError` and `nodeOrNothing` this does not force the caller to handle a failure state at view creation time.

-}
nodeOrLog : String -> List (Attribute msg) -> List (SafeHtml msg) -> SafeHtml msg
nodeOrLog name attrs children =
    case nodeOrNothing name attrs children of
        Just safeHtml ->
            safeHtml

        Nothing ->
            ( name, attrs, children )
                |> Debug.log "Failed to build safe HTML node"
                |> always (SafeHtml (Html.text ""))


{-| Builds a safe HTML node.

This is analogous to [`Html.node`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#node).
The difference is that `nodeOrSend` will skip unsafe nodes and report them by sending a message to `update`.

-}
nodeOrSend : (UnsafeHtmlUsage -> msg) -> String -> List (Attribute msg) -> List (SafeHtml msg) -> SafeHtml msg
nodeOrSend tagError node attrs children =
    let
        replaceWith err =
            SafeHtml <|
                Html.img
                    [ HA.src <| "data:" ++ toString ( err, node, attrs, children )
                    , HA.style [ ( "width", "0" ), ( "height", "0" ) ]
                    , HE.on "loadstart" <| JD.succeed <| tagError err
                    ]
                    []
    in
    nodeOrError node attrs children
        |> Result.mapError replaceWith
        |> Result.merge


{-| Builds a safe HTML node.

This is analogous to [`Html.node`](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#node).
The difference is that `nodeOrElse` takes an extra piece of safe HTML to use as a substitute if the node would not be safe.

-}
nodeOrElse : SafeHtml msg -> String -> List (Attribute msg) -> List (SafeHtml msg) -> SafeHtml msg
nodeOrElse safeReplacement node attrs children =
    nodeOrNothing node attrs children
        |> Maybe.withDefault safeReplacement
