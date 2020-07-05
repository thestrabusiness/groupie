module Attachment exposing (Attachment(..), attachmentDecoder)

import Json.Decode exposing (Decoder, list, oneOf, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, required)


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
