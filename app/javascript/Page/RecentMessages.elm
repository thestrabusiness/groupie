module Page.RecentMessages exposing (Model, Msg, init, update, view)

import Api exposing (ApiConfig, ApiToken, GroupMeResponse)
import Html exposing (..)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, int, list, nullable, oneOf, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, required, requiredAt)
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


type Attachment
    = Image ImageData
    | Location LocationData
    | Split SplitData
    | Emoji EmojiData
    | Mention MentionData
    | File FileData


type alias FileData =
    { id : String }


type alias ImageData =
    { url : String }


type alias LocationData =
    { lat : String, lng : String, name : String }


type alias SplitData =
    { token : String }


type alias EmojiData =
    { placeholder : String, charMap : List (List Int) }


type alias MentionData =
    { user_ids : List String }



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
        GotMessages groupId result ->
            case result of
                Ok { response } ->
                    let
                        flippedMessages =
                            List.reverse response
                    in
                    ( { model | messages = flippedMessages }, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "error" error
                    in
                    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view { messages } =
    div [] <|
        [ h1 [] [ a [ href "/groups" ] [ text "Back to groups" ] ] ]
            ++ List.map viewMessage messages


viewMessage : Message -> Html Msg
viewMessage message =
    div [] [ text <| Maybe.withDefault "" message.text ]



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


attachmentDecoder : Decoder Attachment
attachmentDecoder =
    oneOf
        [ imageDecoder
        , locationDecoder
        , splitDecoder
        , emojiDecoder
        , mentionDecoder
        , fileDecoder
        ]


imageDecoder : Decoder Attachment
imageDecoder =
    succeed imageFromResponse
        |> required "url" string


locationDecoder : Decoder Attachment
locationDecoder =
    succeed locationFromResponse
        |> required "lat" string
        |> required "lng" string
        |> required "name" string


splitDecoder : Decoder Attachment
splitDecoder =
    succeed splitFromResponse
        |> required "token" string


emojiDecoder : Decoder Attachment
emojiDecoder =
    succeed emojiFromResponse
        |> required "placeholder" string
        |> hardcoded []


mentionDecoder : Decoder Attachment
mentionDecoder =
    succeed mentionFromResponse
        |> required "user_ids" (list string)


fileDecoder : Decoder Attachment
fileDecoder =
    succeed fileFromResponse
        |> required "file_id" string


mentionFromResponse : List String -> Attachment
mentionFromResponse =
    Mention << MentionData


imageFromResponse : String -> Attachment
imageFromResponse =
    Image << ImageData


locationFromResponse : String -> String -> String -> Attachment
locationFromResponse lat lng name =
    Location <| LocationData lat lng name


splitFromResponse : String -> Attachment
splitFromResponse =
    Split << SplitData


emojiFromResponse : String -> List (List Int) -> Attachment
emojiFromResponse placeholder charMap =
    Emoji <| EmojiData placeholder charMap


fileFromResponse : String -> Attachment
fileFromResponse =
    File << FileData
