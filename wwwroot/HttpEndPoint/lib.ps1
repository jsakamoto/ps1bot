# LUIS への問い合わせで問い合わせで URL エンコーディングを使うので、System.Web への参照を追加します。
Add-Type -AssemblyName System.Web

# このこの LINE ボットへのチャット投稿に対し、返信を送ります。
function Invoke-Reply ($event, $text) {
    $url = 'https://api.line.me/v2/bot/message/reply'
    $headers = @{Authorization = "Bearer $env:ChannelAccessToken"}
    $resBody = @{
        replyToken = $event.replyToken;
        messages   = @(@{
                type = "text";
                text = $text;
            });
    } | ConvertTo-Json -Compress
    $resBodyBin = [Text.Encoding]::UTF8.GetBytes($resBody)

    Invoke-RestMethod -Uri $url -Method Post -Headers $headers -ContentType "application/json" -Body $resBodyBin
}
