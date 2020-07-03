module Api exposing
    ( ApiConfig
    , ApiToken(..)
    , ClientId(..)
    , CurrentUser
    , GroupMeResponse
    , apiTokenParam
    , encodeQueryParams
    , groupsUrl
    , queryParams
    , urlWithQueryParams
    )

import Browser.Navigation as Navigation


type ApiToken
    = ApiToken String


type ClientId
    = ClientId String


type alias ApiConfig =
    { navKey : Navigation.Key, clientId : ClientId, currentUser : Maybe CurrentUser }


type alias GroupMeResponse a =
    { response : a
    }


type alias CurrentUser =
    { name : String
    , accessToken : ApiToken
    }


baseApiUrl : String
baseApiUrl =
    "https://api.groupme.com/v3"


groupsUrl : String
groupsUrl =
    baseApiUrl ++ "/groups"


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
