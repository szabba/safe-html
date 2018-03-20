module Html.Main exposing (..)

import Html as H
import Html.Safe as HS


main =
    H.beginnerProgram
        { model = False
        , update = \msg _ -> msg
        , view =
            \model ->
                H.div []
                    [ H.span [] [ H.text ("Was a message sent? " ++ toString model) ]
                    , HS.toHtml <| HS.nodeOrSend (always True) "script" [] []
                    ]
        }
