module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (href, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode
    exposing
        ( Decoder
        , andThen
        , field
        , int
        , list
        , nullable
        , oneOf
        , string
        , succeed
        )
import Json.Decode.Pipeline
    exposing
        ( custom
        , hardcoded
        , optional
        , required
        , requiredAt
        )



---- MODEL ----


type alias Flags =
    { clientId : String }


type Model
    = Loading ApiConfig
    | SignIn ApiConfig
    | ViewingGroups (List Group) ApiConfig
    | ViewingMessages String (List Message) ApiConfig


type ApiToken
    = ApiToken String


type ClientId
    = ClientId String


type alias ApiConfig =
    { clientId : ClientId, currentUser : Maybe CurrentUser }


init : ApiConfig -> ( Model, Cmd Msg )
init config =
    ( Loading config, getCurrentUser )


type alias GroupMeResponse a =
    { response : a
    }


type alias Group =
    { id : String, name : String }


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


type alias CurrentUser =
    { name : String
    , accessToken : ApiToken
    }


getConfig : Model -> ApiConfig
getConfig model =
    case model of
        SignIn config ->
            config

        Loading config ->
            config

        ViewingGroups _ config ->
            config

        ViewingMessages _ _ config ->
            config



---- UPDATE ----


type Msg
    = NoOp
    | GotGroups (Result Http.Error (GroupMeResponse (List Group)))
    | GotMessages String (Result Http.Error (GroupMeResponse (List Message)))
    | GotCurrentUserResponse (Result Http.Error CurrentUser)
    | UserSelectedGroup String
    | UserClickedBackToGroups


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        config =
            getConfig model

        currentUser =
            config.currentUser
    in
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotGroups result ->
            case result of
                Ok { response } ->
                    ( ViewingGroups response config, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "error" error
                    in
                    ( model, Cmd.none )

        GotMessages groupId result ->
            case result of
                Ok { response } ->
                    let
                        flippedMessages =
                            List.reverse response
                    in
                    ( ViewingMessages groupId flippedMessages config, Cmd.none )

                Err error ->
                    let
                        _ =
                            Debug.log "error" error
                    in
                    ( model, Cmd.none )

        GotCurrentUserResponse response ->
            case response of
                Ok currentUser_ ->
                    let
                        newConfig =
                            { config | currentUser = Just currentUser_ }
                    in
                    case model of
                        SignIn _ ->
                            ( Loading newConfig, getGroups currentUser_.accessToken )

                        Loading _ ->
                            ( Loading newConfig, getGroups currentUser_.accessToken )

                        ViewingGroups groups _ ->
                            ( ViewingGroups groups newConfig, Cmd.none )

                        ViewingMessages groupId messages _ ->
                            ( ViewingMessages groupId messages newConfig, Cmd.none )

                Err _ ->
                    ( SignIn config, Cmd.none )

        UserSelectedGroup groupId ->
            case currentUser of
                Nothing ->
                    ( SignIn config, Cmd.none )

                Just { accessToken } ->
                    ( Loading config, getMessages accessToken groupId )

        UserClickedBackToGroups ->
            case currentUser of
                Nothing ->
                    ( SignIn config, Cmd.none )

                Just { accessToken } ->
                    ( Loading config, getGroups accessToken )



---- VIEW ----


view : Model -> Html Msg
view model =
    case model of
        SignIn config ->
            div [] [ signInLink config.clientId ]

        Loading _ ->
            div [] [ p [] [ text "Loading..." ] ]

        ViewingGroups groups _ ->
            div [] <| List.map viewGroup groups

        ViewingMessages _ messages _ ->
            div [] <|
                [ h1 [ onClick UserClickedBackToGroups ] [ text "Back to groups" ] ]
                    ++ List.map viewMessage messages


viewGroup : Group -> Html Msg
viewGroup group =
    div [] [ h2 [ onClick <| UserSelectedGroup group.id ] [ text group.name ] ]


viewMessage : Message -> Html Msg
viewMessage message =
    div [] [ text <| Maybe.withDefault "" message.text ]


signInLink : ClientId -> Html Msg
signInLink (ClientId clientId) =
    a [ href <| "https://oauth.groupme.com/oauth/authorize?client_id=" ++ clientId ]
        [ text "Sign in to GroupMe" ]



---- API ----


getCurrentUser : Cmd Msg
getCurrentUser =
    Http.get
        { url = "/sessions"
        , expect = Http.expectJson GotCurrentUserResponse currentUserDecoder
        }


currentUserDecoder : Decoder CurrentUser
currentUserDecoder =
    succeed CurrentUser
        |> required "name" string
        |> required "access_token" apiTokenDecoder


apiTokenDecoder : Decoder ApiToken
apiTokenDecoder =
    Decode.andThen decodeApiToken string


decodeApiToken : String -> Decoder ApiToken
decodeApiToken value =
    succeed <| ApiToken value


baseApiUrl : String
baseApiUrl =
    "https://api.groupme.com/v3"


groupsUrl : String
groupsUrl =
    baseApiUrl ++ "/groups"


messagesUrl : String -> String
messagesUrl groupId =
    groupsUrl ++ "/" ++ groupId ++ "/messages"


apiTokenParam : ApiToken -> String
apiTokenParam (ApiToken token) =
    "token=" ++ token


queryParams : ApiToken -> List ( String, String ) -> String
queryParams token params =
    let
        tokenParam =
            apiTokenParam token

        otherParams =
            encodeQueryParams params
    in
    "?" ++ tokenParam ++ otherParams


encodeQueryParams : List ( String, String ) -> String
encodeQueryParams params =
    List.map (\( key, value ) -> "&" ++ key ++ "=" ++ value) params
        |> String.join ""


urlWithQueryParams : String -> ApiToken -> List ( String, String ) -> String
urlWithQueryParams url token params =
    url ++ queryParams token params


getGroups : ApiToken -> Cmd Msg
getGroups token =
    Http.get
        { url = urlWithQueryParams groupsUrl token []
        , expect = Http.expectJson GotGroups groupListDecoder
        }


groupDecoder : Decoder Group
groupDecoder =
    succeed Group
        |> required "id" string
        |> required "name" string


groupListDecoder : Decoder (GroupMeResponse (List Group))
groupListDecoder =
    succeed GroupMeResponse
        |> required "response" (list groupDecoder)


getMessages : ApiToken -> String -> Cmd Msg
getMessages token groupId =
    Http.get
        { url = urlWithQueryParams (messagesUrl groupId) token [ ( "limit", "100" ) ]
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



---- PROGRAM ----


initWithConfig : Flags -> ( Model, Cmd Msg )
initWithConfig { clientId } =
    let
        apiConfg =
            { clientId = ClientId clientId
            , currentUser = Nothing
            }
    in
    init apiConfg


main : Program Flags Model Msg
main =
    Browser.element
        { view = view
        , init = initWithConfig
        , update = update
        , subscriptions = always Sub.none
        }
