module Page.RecentMessages exposing (Model, Msg, init, update, view)

import Api exposing (ApiConfig, ApiToken, GroupMeResponse)
import Attachment exposing (Attachment, attachmentDecoder)
import Html exposing (..)
import Html.Attributes exposing (class, href, src)
import Http
import Json.Decode exposing (Decoder, int, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (required, requiredAt)
import Route exposing (GroupId(..))


type alias Model =
    { messages : List Message
    , config : ApiConfig
    }


type alias Message =
    { id : String
    , createdAt : Int
    , text : Maybe String
    , authorName : String
    , avatarUrl : Maybe String
    , attachments : List Attachment
    , favoritedBy : List String
    }



---- UPDATE ----


type Msg
    = GotMessages Route.GroupId (Result Http.Error (GroupMeResponse (List Message)))


init : ApiConfig -> Route.GroupId -> ( Model, Cmd Msg )
init config groupId =
    let
        initialModel =
            { config = config, messages = [] }
    in
    case config.currentUser of
        Nothing ->
            ( initialModel, Cmd.none )

        Just { accessToken } ->
            ( initialModel, getMessages accessToken groupId )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotMessages _ result ->
            case result of
                Ok { response } ->
                    let
                        flippedMessages =
                            List.reverse response
                    in
                    ( { model | messages = flippedMessages }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view { messages } =
    div [ class "message-list message-list__recent" ] <|
        [ div [ class "message-list__header" ]
            [ h3 [] [ a [ href "/groups" ] [ text "Back to groups" ] ]
            , div [] []
            ]
        , div [ class "message-list__content" ] <|
            [ h1 [] [ text "Recent Messages" ]
            ]
                ++ List.map viewMessage messages
        ]


viewMessage : Message -> Html Msg
viewMessage message =
    div [ class "message" ]
        [ div [ class "message__meta" ]
            [ div [ class "message__avatar" ]
                [ img [ src <| imageWithDefault message.avatarUrl ] [] ]
            , div [ class "message__title" ] [ text message.authorName ]
            ]
        , div [ class "message__body" ]
            [ text <| Maybe.withDefault "" message.text
            ]
        ]


imageWithDefault : Maybe String -> String
imageWithDefault =
    Maybe.withDefault "https://i.groupme.com/300x300.png.6485c42fdeaa45b5a4b986b9cb1c91a2"



---- API ----


messagesUrl : Route.GroupId -> String
messagesUrl (Route.GroupId groupId) =
    Api.groupsUrl ++ "/" ++ groupId ++ "/messages"


getMessages : ApiToken -> Route.GroupId -> Cmd Msg
getMessages token groupId =
    Http.get
        { url = Api.urlWithQueryParams (messagesUrl groupId) token [ ( "limit", "100" ) ]
        , expect = Http.expectJson (GotMessages groupId) messageListDecoder
        }


messageListDecoder : Decoder (GroupMeResponse (List Message))
messageListDecoder =
    succeed GroupMeResponse
        |> requiredAt [ "response", "messages" ] (list messageDecoder)


messageDecoder : Decoder Message
messageDecoder =
    succeed Message
        |> required "id" string
        |> required "created_at" int
        |> required "text" (nullable string)
        |> required "name" string
        |> required "avatar_url" (nullable string)
        |> required "attachments" (list attachmentDecoder)
        |> required "favorited_by" (list string)
