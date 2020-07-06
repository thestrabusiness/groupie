module Main exposing (Model, Msg(..), init, main, update, view)

import Api exposing (ApiConfig, ApiToken(..), ClientId(..), CurrentUser, GroupMeResponse)
import Browser
import Browser.Navigation as Navigation
import Html exposing (..)
import Html.Attributes exposing (href, src)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, andThen, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Page.GroupList as GroupList
import Page.MostLiked as MostLiked
import Page.RecentMessages as RecentMessages
import Route exposing (Route)
import Url exposing (Url)



---- MODEL ----


type Model
    = NotFound ApiConfig
    | Loading ApiConfig
    | SignIn ApiConfig
    | GroupList GroupList.Model
    | RecentMessages RecentMessages.Model
    | MostLiked MostLiked.Model


init : ApiConfig -> Url -> ( Model, Cmd Msg )
init config url =
    ( Loading config, getCurrentUser <| Route.fromUrl url )



---- UPDATE ----


type Msg
    = OnUrlChange Url
    | OnUrlRequest Browser.UrlRequest
    | GotCurrentUserResponse (Maybe Route) (Result Http.Error CurrentUser)
    | GroupListMsg GroupList.Msg
    | RecentMessagesMsg RecentMessages.Msg
    | MostLikedMsg MostLiked.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        config =
            getApiConfig model

        currentUser =
            config.currentUser
    in
    case ( msg, model ) of
        ( OnUrlRequest request, _ ) ->
            case request of
                Browser.Internal url ->
                    ( model, Navigation.pushUrl config.navKey (Url.toString url) )
                        |> changeRouteTo (Route.fromUrl url)

                Browser.External href ->
                    ( model, Navigation.load href )

        ( OnUrlChange url, _ ) ->
            ( model, Cmd.none )
                |> changeRouteTo (Route.fromUrl url)

        ( GotCurrentUserResponse route response, _ ) ->
            case response of
                Ok currentUser_ ->
                    let
                        newConfig =
                            { config | currentUser = Just currentUser_ }

                        updatedModel =
                            setApiConfig newConfig model
                    in
                    changeRouteTo route ( updatedModel, Cmd.none )

                Err _ ->
                    ( SignIn <| getApiConfig model, Cmd.none )

        ( GroupListMsg groupListMsg, GroupList groupListModel ) ->
            let
                ( newModel, newMsg ) =
                    GroupList.update groupListMsg groupListModel
            in
            ( GroupList newModel, Cmd.map GroupListMsg newMsg )

        ( GroupListMsg _, _ ) ->
            ( model, Cmd.none )

        ( RecentMessagesMsg recentMessagesMsg, RecentMessages recentMessagesModel ) ->
            let
                ( newModel, newMsg ) =
                    RecentMessages.update recentMessagesMsg recentMessagesModel
            in
            ( RecentMessages newModel, Cmd.map RecentMessagesMsg newMsg )

        ( RecentMessagesMsg _, _ ) ->
            ( model, Cmd.none )

        ( MostLikedMsg mostLikedMsg, MostLiked mostLikedModel ) ->
            let
                ( newModel, newMsg ) =
                    MostLiked.update mostLikedMsg mostLikedModel
            in
            ( MostLiked newModel, Cmd.map MostLikedMsg newMsg )

        ( MostLikedMsg _, _ ) ->
            ( model, Cmd.none )


setApiConfig : ApiConfig -> Model -> Model
setApiConfig config model =
    case model of
        NotFound _ ->
            NotFound config

        Loading _ ->
            Loading config

        GroupList pageModel ->
            GroupList { pageModel | config = config }

        RecentMessages pageModel ->
            RecentMessages { pageModel | config = config }

        MostLiked pageModel ->
            MostLiked { pageModel | config = config }

        SignIn _ ->
            SignIn config


getApiConfig : Model -> ApiConfig
getApiConfig model =
    case model of
        NotFound config ->
            config

        Loading config ->
            config

        GroupList { config } ->
            config

        RecentMessages { config } ->
            config

        MostLiked { config } ->
            config

        SignIn config ->
            config


changeRouteTo : Maybe Route -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
changeRouteTo route ( model, msg ) =
    let
        apiConfig =
            getApiConfig model
    in
    case route of
        Nothing ->
            ( NotFound apiConfig, msg )

        Just Route.SignIn ->
            ( SignIn apiConfig, msg )

        Just Route.GroupList ->
            let
                ( groupListModel, groupListMsg ) =
                    GroupList.init apiConfig
            in
            ( GroupList groupListModel
            , Cmd.batch [ msg, Cmd.map GroupListMsg groupListMsg ]
            )

        Just (Route.RecentMessages groupId) ->
            let
                ( recentMessagesModel, recentMessagesMsg ) =
                    RecentMessages.init apiConfig groupId
            in
            ( RecentMessages recentMessagesModel
            , Cmd.batch [ msg, Cmd.map RecentMessagesMsg recentMessagesMsg ]
            )

        Just (Route.MostLikedMessages groupId) ->
            let
                ( mostLikedModel, mostLikedMsg ) =
                    MostLiked.init apiConfig groupId
            in
            ( MostLiked mostLikedModel
            , Cmd.batch [ msg, Cmd.map MostLikedMsg mostLikedMsg ]
            )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    case model of
        NotFound _ ->
            { title = "Page Not Found"
            , body =
                [ div []
                    [ h1 [] [ text "Page Not Found" ]
                    , a [ href "/" ] [ text "Go Home" ]
                    ]
                ]
            }

        SignIn config ->
            { title = "Sign In"
            , body =
                [ div []
                    [ h1 [] [ text "GroupMe" ]
                    , signInLink config.clientId
                    ]
                ]
            }

        Loading _ ->
            { title = "Loading..."
            , body =
                [ div []
                    [ p [] [ text "Loading..." ]
                    ]
                ]
            }

        GroupList pageModel ->
            { title = "Group List"
            , body =
                [ GroupList.view pageModel
                    |> Html.map GroupListMsg
                ]
            }

        RecentMessages pageModel ->
            { title = "Latest Messages"
            , body =
                [ RecentMessages.view pageModel
                    |> Html.map RecentMessagesMsg
                ]
            }

        MostLiked pageModel ->
            { title = "Most Liked Messages"
            , body =
                [ MostLiked.view pageModel
                    |> Html.map MostLikedMsg
                ]
            }


signInLink : ClientId -> Html Msg
signInLink (ClientId clientId) =
    a [ href <| "https://oauth.groupme.com/oauth/authorize?client_id=" ++ clientId ]
        [ text "Sign in to GroupMe" ]



---- API ----


getCurrentUser : Maybe Route -> Cmd Msg
getCurrentUser route =
    Http.get
        { url = "/sessions"
        , expect = Http.expectJson (GotCurrentUserResponse route) currentUserDecoder
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



---- PROGRAM ----


type alias Flags =
    { authenticityToken : String
    , clientId : String
    }


initWithConfig : Flags -> Url -> Navigation.Key -> ( Model, Cmd Msg )
initWithConfig { authenticityToken, clientId } url navKey =
    let
        apiConfg =
            { clientId = ClientId clientId
            , currentUser = Nothing
            , navKey = navKey
            , authenticityToken = authenticityToken
            }
    in
    init apiConfg url


main : Program Flags Model Msg
main =
    Browser.application
        { view = view
        , init = initWithConfig
        , update = update
        , subscriptions = always Sub.none
        , onUrlChange = OnUrlChange
        , onUrlRequest = OnUrlRequest
        }
