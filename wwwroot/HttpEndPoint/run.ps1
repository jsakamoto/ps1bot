. "$EXECUTION_CONTEXT_FUNCTIONDIRECTORY\lib.ps1"

# POST method: $req
$requestBody = Get-Content $req -Raw -Encoding UTF8 | ConvertFrom-Json
$requestBody.events | where type -eq "message" | % {
    try {
        $ErrorActionPreference = "Stop"

        $event = $_
        $messageText = $event.message.text

        # PowerShell は "120MB" とか単位付きのバイトサイズが整数定数となるとなる
        # オモシロ仕様なので、これを活かして、KB/MB/GB/TB/PB をを Bytes に換算する機能を搭載しました。
        if ($messageText -match "^\d+[KMGTP]?B$") {
            $bytes = iex $messageText
            Invoke-Reply $event ("$messageText は {0:#,0} Bytes です。" -f $bytes)
        }

        # 実行時に文字列を式として評価できるので評価できるので (JavaScript の eval と同様)、
        # これを活かして四則演算であればそのまま評価して計算結果を返す、電卓モード機能を搭載しました。
        elseif ($messageText -match "^\-?\d+(\.\d+)?([ ]*[\+\-\*\/][ ]*\-?\d+(\.\d+)?)*([ ]*=[ ]*)?$") {
            $resultOfCaliculate = iex $messageText.TrimEnd(" ", "=")
            Invoke-Reply $event ("{0}" -f $resultOfCaliculate)
        }

        # 以上、正規表現でのマッチングで判定できる機能のほかは、
        # LUIS になげて Intent が何か分析してもらい、判明した判明した Intent に応じて分岐。
        else {
            $url = $env:LUISEndPoint + [System.Web.HttpUtility]::UrlEncode($messageText)
            $result = Invoke-RestMethod -Method Get -Uri $url
            $intent = $result.topScoringIntent.intent
            echo "Top Scoring Intent is [$intent]"

            switch ($intent) {
                # 挨拶
                "Greeting" {
                    Invoke-Reply $event "こんにちは。"
                }
                
                # PowerShell バージョンを知る
                "TellMeYourVersion"{
                    $text = $PSVersionTable | ft -HideTableHeaders -AutoSize | Out-String
                    Invoke-Reply $event $text.TrimEnd("`r", "`n", " ")
                }
                
                # 稼働プラットフォームを知る
                "WhereDoYouLive" {
                    $text = "Microsoft Azure の Functions App 上で稼働している PowerShell スクリプトです。"
                    Invoke-Reply $event $text 
                }

                # CLR/H について知る
                "AboutCLRH" {
                    $texts = @(
                        "CLR/H は、北海道で IT 関連、特に開発系技術に関する学習と研究を目的としたコミュニティです。 CLR/H には `"Creation Leads to Revolution with Humanity (or Humor :-)`" という意味もあります。",                        
                        "定期的に勉強会およびイベントを開催し、参加者同士の情報交換や技術研鑽を行っております。会の成り立ちから、Microsoft .NET テクノロジー関連の話題が多いですが、それ以外の話題を取り上げることもあります。"
                    )
                    Invoke-Reply $event ($texts -join "`n") 
                }

                # 使い方
                "HowToUse" {
                    $features = @(
                        "★ `"1+2*3`" のような四則演算のメッセージを送ると、計算結果を返します。",
                        "★ `"128MB`" や `"1GB`" などのサイズ情報を送ると、バイト数に換算して返します。",
                        "★ どこのプラットフォームで動作しているか尋ねられます。",
                        "★ バージョン情報を尋ねられます。",
                        "★ IT勉強会コミュニティ「CLR/H」について尋ねられます。"
                    )
                    Invoke-Reply $event ($features -join "`n") 
                }
                # 判定できなかった場合
                "None" {
                    Invoke-Reply $event "うぃっす!" 
                }
            }
        }
    }
    catch {
        $ErrorActionPreference = "Continue"
        Invoke-Reply $event "すみません、エラーが発生しました。"
    }
    finally{
        $ErrorActionPreference = "Continue"
    }
}

