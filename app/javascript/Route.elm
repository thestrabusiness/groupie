module Route exposing (GroupId(..), Route(..), fromUrl)

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string)


type Route
    = GroupList
    | SignIn
    | RecentMessages GroupId
    | MostLikedMessages GroupId


type GroupId
    = GroupId String


fromUrl : Url -> Maybe Route
fromUrl =
    Parser.parse urlParser


urlParser : Parser (Route -> a) a
urlParser =
    oneOf
        [ Parser.map GroupList Parser.top
        , Parser.map SignIn (s "sign_in")
        , Parser.map GroupList (s "groups")
        , Parser.map (RecentMessages << GroupId) (s "groups" </> string </> s "messages")
        ]
