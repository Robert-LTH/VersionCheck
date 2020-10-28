function Global:Get-SFLatestReleaseUri {

    param(

        $Project

    )

    <#

        https://sourceforge.net/p/forge/documentation/Using%20the%20Release%20API/

        "You can also get the URL by right-clicking on the file in the Files web interface and selecting Copy Link."

    #>

    $Pattern = "url=(http[s]*://downloads.sourceforge.net/project/$Project/[%\w\/\.\-\?=&;]+)`">"

    $req = Invoke-WebRequest -Uri "https://sourceforge.net/projects/$Project/files/latest/download" -UseBasicParsing
    $req | Select-String -Pattern $Pattern | Select-Object -ExpandProperty Matches | Select-Object -ExpandProperty Groups | Select-Object -ExpandProperty Value -Last 1

}