module Page.GroupList exposing (Model, Msg, init, update, view)

import Api exposing (ApiConfig, ApiToken, GroupMeResponse)
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (class, href, method, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, list, nullable, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Route exposing (GroupId(..))


type alias Group =
    { id : String
    , name : String
    , imageUrl : Maybe String
    }


type alias Model =
    { groups : List Group
    , config : ApiConfig
    }


type Msg
    = GotGroups (Result Http.Error (GroupMeResponse (List Group)))
    | UserClickedSignOut
    | GotSignOutResponse (Result Http.Error ())



---- UPDATE ----


init : ApiConfig -> ( Model, Cmd Msg )
init config =
    case config.currentUser of
        Just { accessToken } ->
            ( { config = config, groups = [] }, getGroups accessToken )

        Nothing ->
            ( { config = config, groups = [] }
            , Navigation.replaceUrl config.navKey "/sign_in"
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotGroups result ->
            case result of
                Ok { response } ->
                    ( { model | groups = response }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        UserClickedSignOut ->
            ( model, signOut model.config )

        GotSignOutResponse result ->
            case result of
                Ok _ ->
                    let
                        config =
                            model.config

                        newConfig =
                            { config | currentUser = Nothing }
                    in
                    ( { model | config = newConfig }
                    , Navigation.pushUrl
                        config.navKey
                        "/"
                    )

                Err _ ->
                    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view { groups } =
    div [ class "group-list" ]
        [ div [ class "group-list__header" ]
            [ h2 [ onClick UserClickedSignOut ] [ text "Sign Out" ]
            ]
        , div [ class "group-list__content" ] <| List.map viewGroup groups
        ]


viewGroup : Group -> Html Msg
viewGroup group =
    div [ class "group-list__item" ]
        [ img [ src <| imageWithDefault group.imageUrl ] []
        , h2 [] [ text group.name ]
        , div [ class "links" ]
            [ a [ href <| "/groups/" ++ group.id ++ "/messages" ]
                [ text "Recent Messages" ]
            , a [ href <| "/groups/" ++ group.id ++ "/most_liked" ]
                [ text "Most Liked Messages" ]
            ]
        ]


imageWithDefault : Maybe String -> String
imageWithDefault =
    Maybe.withDefault "https://i.groupme.com/300x300.png.e8ec5793a332457096bc9707ffc9ac37"



---- API ----


signOut : ApiConfig -> Cmd Msg
signOut { authenticityToken } =
    Http.request
        { method = "DELETE"
        , url = "/sessions"
        , expect = Http.expectWhatever GotSignOutResponse
        , body = Http.emptyBody
        , headers = [ Http.header "X-CSRF-Token" authenticityToken ]
        , timeout = Nothing
        , tracker = Nothing
        }


getGroups : ApiToken -> Cmd Msg
getGroups token =
    Http.get
        { url = Api.urlWithQueryParams Api.groupsUrl token []
        , expect = Http.expectJson GotGroups groupListDecoder
        }


groupDecoder : Decoder Group
groupDecoder =
    succeed Group
        |> required "id" string
        |> required "name" string
        |> required "image_url" (nullable string)


groupListDecoder : Decoder (GroupMeResponse (List Group))
groupListDecoder =
    succeed GroupMeResponse
        |> required "response" (list groupDecoder)
