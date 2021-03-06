module Page.MostLiked exposing (Model, Msg, init, update, view)

import Api exposing (ApiConfig)
import Attachment exposing (Attachment(..), attachmentDecoder)
import Html exposing (..)
import Html.Attributes exposing (class, href, src)
import Html.Events exposing (onClick)
import Http
import Http.Detailed
import Json.Decode as Decode
    exposing
        ( Decoder
        , int
        , list
        , nullable
        , string
        , succeed
        )
import Json.Decode.Pipeline exposing (required)
import Route exposing (GroupId(..))
import Time


type alias DetailedError =
    Http.Detailed.Error String


pageSize : Int
pageSize =
    50


type alias Model =
    { config : ApiConfig
    , messageCache : Loadable (Maybe MessageCache)
    , messages : Loadable (List Message)
    , groupId : GroupId
    , offset : Int
    }


type alias Message =
    { id : Int
    , createdAt : Time.Posix
    , text : Maybe String
    , avatarUrl : Maybe String
    , favoritesCount : Int
    , senderName : Maybe String
    , attachments : List Attachment
    }


type alias MessageCache =
    { createdAt : Time.Posix
    , endedAt : Maybe Time.Posix
    }


type Loadable a
    = Loading
    | Success a
    | Failed String



---- UPDATE ----


init : ApiConfig -> GroupId -> ( Model, Cmd Msg )
init apiConfig groupId =
    ( { config = apiConfig
      , messages = Loading
      , messageCache = Loading
      , groupId = groupId
      , offset = 0
      }
    , Cmd.batch [ getMessages groupId 0 pageSize, getMessageCache groupId ]
    )


type Msg
    = GotMessageResponse (Result DetailedError ( Http.Metadata, List Message ))
    | UserClickedStartMessageCache
    | GotMessageCacheResponse (Result DetailedError ( Http.Metadata, Maybe MessageCache ))
    | GotCreateMessageCacheResponse (Result DetailedError ( Http.Metadata, Maybe MessageCache ))
    | UserReachedBottom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotMessageResponse response ->
            case response of
                Ok ( _, messages ) ->
                    ( appendNewMessages messages model, Cmd.none )

                Err error ->
                    handleError error model

        GotMessageCacheResponse response ->
            case response of
                Ok ( _, maybeMessageCache ) ->
                    ( { model | messageCache = Success maybeMessageCache }, Cmd.none )

                Err error ->
                    handleError error model

        UserClickedStartMessageCache ->
            ( { model | messageCache = Loading }, startMessageCache model.config model.groupId )

        GotCreateMessageCacheResponse response ->
            case response of
                Ok ( _, maybeMessageCache ) ->
                    ( { model | messageCache = Success maybeMessageCache }, Cmd.none )

                Err error ->
                    handleError error model

        UserReachedBottom ->
            let
                newOffset =
                    model.offset + pageSize
            in
            ( { model | offset = newOffset }, getMessages model.groupId newOffset pageSize )


appendNewMessages : List Message -> Model -> Model
appendNewMessages responseMessages model =
    let
        newMessages =
            case model.messages of
                Success existingMessages ->
                    existingMessages ++ responseMessages

                _ ->
                    responseMessages
    in
    { model | messages = Success newMessages }



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "message-list message-list__most-liked" ]
        [ div [ class "message-list__header" ]
            [ h2 [] [ a [ href "/groups" ] [ text "Back to groups" ] ]
            , div [] []
            ]
        , div
            [ class "message-list__content" ]
            [ h1 [] [ text "Top 10 Messages Of All Time" ]
            , viewMessageCache model.messageCache
            , viewMessages model.messages
            , button [ onClick UserReachedBottom ] [ text "Show More" ]
            ]
        ]


viewLoadable : Loadable a -> (a -> Html Msg) -> Html Msg -> Html Msg
viewLoadable loadable onSuccessContent onErrorContent =
    case loadable of
        Loading ->
            p [] [ text "Loading..." ]

        Success loaded ->
            onSuccessContent loaded

        Failed error ->
            div []
                [ div [] [ text error ]
                , onErrorContent
                ]


viewMessageCache : Loadable (Maybe MessageCache) -> Html Msg
viewMessageCache messageCache =
    viewLoadable messageCache
        (\maybeCache ->
            case maybeCache of
                Nothing ->
                    startCacheButton "Fetch the latest messages"

                Just { endedAt } ->
                    cacheStatusMessage endedAt
        )
        (startCacheButton "Retry Cache")


cacheStatusMessage : Maybe Time.Posix -> Html Msg
cacheStatusMessage maybeEndedAt =
    case maybeEndedAt of
        Just endedAt ->
            div []
                [ div [] [ text <| "Last fetched at: " ++ postToDateTime endedAt ++ " UTC" ]
                , startCacheButton "Fetch again"
                ]

        Nothing ->
            div [] [ text "Please wait: We're fetching the latest messages for you..." ]


startCacheButton : String -> Html Msg
startCacheButton label =
    div [] [ button [ onClick UserClickedStartMessageCache ] [ text label ] ]


viewMessages : Loadable (List Message) -> Html Msg
viewMessages messages =
    viewLoadable messages
        (\messages_ ->
            if List.isEmpty messages_ then
                noMessagesMessage

            else
                div [] <| List.map viewMessage messages_
        )
        (div [] [])


viewMessage : Message -> Html Msg
viewMessage message =
    div [ class "message" ]
        [ div [ class "message__meta" ]
            [ div [ class "message__avatar" ]
                [ img [ src <| imageWithDefault message.avatarUrl ] [] ]
            , div [ class "message__title" ]
                [ text <| Maybe.withDefault "GroupMe" message.senderName ]
            ]
        , div [ class "message__body" ] <|
            [ div [ class "message__title" ] [ text <| postToDateTime message.createdAt ]
            , div [] [ text <| Maybe.withDefault "" message.text ]
            , div [] [ text <| String.fromInt message.favoritesCount ++ " likes" ]
            ]
                ++ viewAttachments message.attachments
        ]


imageWithDefault : Maybe String -> String
imageWithDefault =
    Maybe.withDefault "https://i.groupme.com/300x300.png.6485c42fdeaa45b5a4b986b9cb1c91a2"


viewAttachments : List Attachment -> List (Html Msg)
viewAttachments attachments =
    List.map viewAttachment attachments


viewAttachment : Attachment -> Html Msg
viewAttachment attachment =
    case attachment of
        Image data ->
            img [ src data.url ] []

        Location _ ->
            div [] [ text "Location" ]

        Split _ ->
            div [] [ text "Split" ]

        Emoji _ ->
            div [] [ text "Emoji" ]

        Mention _ ->
            div [] [ text "Mention" ]

        File _ ->
            div [] [ text "File" ]


noMessagesMessage : Html Msg
noMessagesMessage =
    div []
        [ p [] [ text "It looks like we don't have any messages for this group" ]
        , p [] [ text "Click the button above and we'll fetch the latest ones for you" ]
        ]



---- API ----


startMessageCache : ApiConfig -> Route.GroupId -> Cmd Msg
startMessageCache { authenticityToken } groupId =
    Http.request
        { method = "POST"
        , url = groupCacheUrl groupId
        , expect = Http.Detailed.expectJson GotCreateMessageCacheResponse messageCacheDecoder
        , body = Http.emptyBody
        , headers = [ Http.header "X-CSRF-Token" authenticityToken ]
        , timeout = Nothing
        , tracker = Nothing
        }


getMessageCache : Route.GroupId -> Cmd Msg
getMessageCache groupId =
    Http.get
        { url = groupCacheUrl groupId
        , expect = Http.Detailed.expectJson GotMessageCacheResponse messageCacheDecoder
        }


groupCacheUrl : Route.GroupId -> String
groupCacheUrl (GroupId groupId) =
    "/groups/" ++ groupId ++ "/message_cache"


messageCacheDecoder : Decoder (Maybe MessageCache)
messageCacheDecoder =
    succeed MessageCache
        |> required "started_at" posixDecoder
        |> required "ended_at" (nullable posixDecoder)
        |> nullable


getMessages : Route.GroupId -> Int -> Int -> Cmd Msg
getMessages groupId offset limit =
    Http.get
        { url = mostLikedUrl groupId offset limit
        , expect = Http.Detailed.expectJson GotMessageResponse messageListDecoder
        }


mostLikedUrl : GroupId -> Int -> Int -> String
mostLikedUrl (GroupId groupId) offset limit =
    "/groups/"
        ++ groupId
        ++ "/most_liked_messages?"
        ++ "offset="
        ++ String.fromInt offset
        ++ "&limit="
        ++ String.fromInt limit


messageListDecoder : Decoder (List Message)
messageListDecoder =
    Decode.list messageDecoder


messageDecoder : Decoder Message
messageDecoder =
    succeed Message
        |> required "id" int
        |> required "created_at" posixDecoder
        |> required "text" (nullable string)
        |> required "avatar_url" (nullable string)
        |> required "favorites_count" int
        |> required "sender_name" (nullable string)
        |> required "attachments" (list attachmentDecoder)


postToDateTime : Time.Posix -> String
postToDateTime posix =
    let
        zone =
            Time.utc
    in
    (englishMonthName <| Time.toMonth zone posix)
        ++ " "
        ++ (String.fromInt <| Time.toDay zone posix)
        ++ " "
        ++ (String.fromInt <| Time.toYear zone posix)
        ++ " "
        ++ (String.fromInt <| Time.toHour zone posix)
        ++ ":"
        ++ (String.padLeft 2 '0' <| String.fromInt <| Time.toMinute zone posix)


englishMonthName : Time.Month -> String
englishMonthName month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


posixDecoder : Decoder Time.Posix
posixDecoder =
    Decode.andThen timeHelper int


timeHelper : Int -> Decoder Time.Posix
timeHelper value =
    succeed <| secondsToPosix value


secondsToPosix : Int -> Time.Posix
secondsToPosix seconds =
    Time.millisToPosix (seconds * 1000)


handleError : DetailedError -> Model -> ( Model, Cmd Msg )
handleError error model =
    case error of
        Http.Detailed.BadStatus _ body ->
            ( { model | messageCache = Failed <| parseErrorBody body }, Cmd.none )

        _ ->
            ( { model | messageCache = Failed "Something went wrong" }, Cmd.none )


parseErrorBody : String -> String
parseErrorBody body =
    let
        result =
            Decode.decodeString (Decode.list string) body
    in
    case result of
        Ok errors ->
            String.join "\n" errors

        Err _ ->
            "Something went wrong"
