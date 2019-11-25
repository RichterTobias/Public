Function Start-SimplePomodoro {

<#
      .SYNOPSIS
      Start-SimplePomodoro is a function command to start a new Pomodoro session with additional actions. This is a simplified version of the Start-Pomodoro 
      .DESCRIPTION

        By MVP Ståle Hansen (http://msunified.net) with modifications by Jan Egil Ring (https://github.com/janegilring)
        Pomodoro function by Nathan.Run() http://nathanhoneycutt.net/blog/a-pomodoro-timer-in-powershell/
        Note: for desktops you need to enable presentation settings in order to suppress email alerts, by MVP Robert Sparnaaij: https://msunified.net/2013/11/25/lock-down-your-lync-status-and-pc-notifications-using-powershell/
        Start-Pomodoro also controls your Skype client presence, this is removed in Start-SimplePomodoro
        Get the old version here: https://github.com/janegilring/PSProductivityTools
        This function closes Teams and starts it again after the session has ended for full focus on deep work
        Latest version blogged about here: https://msunified.net/2019/10/22/my-current-powershell-pomodoro-timer/
        Latest version to be found here: https://github.com/StaleHansen/Public/tree/master/Start-SimplePomodoro

        Required version: Windows PowerShell 3.0 or later 

        If you end the script prematurely, you can run the script with a 10 second lenght to reset your IFTTT and 

        It is recommended to add your Start-SimplePomodoro runline at the end of this script for easy startup

     .EXAMPLE
      Start-SimplePomodoro
     .EXAMPLE
      Start-SimplePomodoro -Minutes 10 -AudioFilePath $MusicToCodeByCollectionPath -StartMusic
     .EXAMPLE
      Start-SimplePomodoro -Minutes 15 -SpotifyPlayList spotify:playlist:XXXXXXXXXXXXXXXXXX
     .EXAMPLE
      Start-SimplePomodoro -Minutes 20 -IFTTMuteTrigger pomodoro_start -IFTTUnMuteTrigger pomodoro_stop -IFTTWebhookKey XXXXXXXXX
      .EXAMPLE
      Start-SimplePomodoro -Minutes 0.1 -SpotifyPlayList spotify:playlist:XXXXXXXXXXXXXXXXXX -IFTTMuteTrigger pomodoro_start -IFTTUnMuteTrigger pomodoro_stop -IFTTWebhookKey XXXXXXXXX


#>

    [CmdletBinding()]
    Param (
        
        [int]$Minutes = 25, #Duration of your Pomodoro Session
        [switch]$StartMusic,
        [string]$SpotifyPlayList, #uri of your favourite spotify playlist
        [string]$EndPersonalNote = ' ', #LegacySkypeforBusiness note
        [string]$IFTTMuteTrigger, #your_IFTTT_maker_mute_trigger
        [string]$IFTTUnMuteTrigger, #your_IFTTT_maker_unmute_trigger
        [string]$IFTTWebhookKey, #your_IFTTT_webhook_key
        [string]$StartNotificationSound = "C:\Windows\Media\Windows Proximity Connection.wav",
        [string]$EndNotificationSound = "C:\Windows\Media\Windows Proximity Notification.wav",
        [string]$Path = $env:LOCALAPPDATA+"\Microsoft\Teams\Update.exe",
        [string]$Arguments = '--processStart "Teams.exe"'
    )


    #Setting computer to presentation mode, will suppress most types of popups
    Write-Host "Starting presentation mode" -ForegroundColor Green
    presentationsettings /start
    
    #Stop Microsoft Teams
    Write-Host "Closing Microsoft Teams" -ForegroundColor Green
    Get-Process -Name Teams -ErrorAction SilentlyContinue | Stop-Process -ErrorAction SilentlyContinue
    
    #Start Spotify
    if ($SpotifyPlayList -ne ''){Write-Host "Opening your specified Spotify playlist" -ForegroundColor Green; Start-Process -FilePath $SpotifyPlayList}
    
    #Turn off Vibration and mute Phone using IFTTT
    if ($IFTTMuteTrigger -ne '' -and $IFTTWebhookKey -ne ''){
        
             try {
                      
                    $null = Invoke-RestMethod -Uri https://maker.IFTTT.com/trigger/$IFTTMuteTrigger/with/key/$IFTTWebhookKey -Method POST -ErrorAction Stop
                    Write-Host -Object "Android IFTTT mute trigger invoked successfully" -ForegroundColor Green

            }
            catch  {

                    Write-Host -Object "An error occured while invoking IFTT mute trigger: $($_.Exception.Message)" -ForegroundColor Yellow

            }   
        
        }

    Write-Host
    Write-Host "You are GO for flow and deep work <ThumbsUp>"
    Write-Host
  
    if (Test-Path -Path $StartNotificationSound) {
     
        $player = New-Object System.Media.SoundPlayer $StartNotificationSound -ErrorAction SilentlyContinue
         1..2 | ForEach-Object { 
             $player.Play()
            Start-Sleep -m 3400 
        }
    }

    #Counting down to end of Pomodoro
    $seconds = $Minutes * 60
    $delay = 1 #seconds between ticks
    for ($i = $seconds; $i -gt 0; $i = $i - $delay) {
        $percentComplete = 100 - (($i / $seconds) * 100)
        Write-Progress -SecondsRemaining $i `
            -Activity "Pomodoro Focus sessions" `
            -Status "Time remaining:" `
            -PercentComplete $percentComplete
        if ($i -eq 16){Write-Host "Wrapping up, you will be available in $i seconds" -ForegroundColor Green}
        Start-Sleep -Seconds $delay
    }#Timer ended

    #Stopping presentation mode to re-enable outlook popups and other notifications
    Write-Host "Stopping presentation mode" -ForegroundColor Green
    presentationsettings /stop
    
    #Start Microsoft Teams again
    Write-Host "Starting Microsoft Teams" -ForegroundColor Green
    Start-Process -FilePath $Path -ArgumentList $Arguments -WindowStyle Hidden
   
    #Turn vibration on android phone back on using IFTTT
    if ($IFTTUnMuteTrigger -ne '' -and $IFTTWebhookKey -ne ''){

            try {
                      
                        $null = Invoke-RestMethod -Uri https://maker.IFTTT.com/trigger/$IFTTUnMuteTrigger/with/key/$IFTTWebhookKey -Method POST -ErrorAction Stop
           
                        Write-Host -Object "Android IFTTT unmute trigger invoked successfully" -ForegroundColor Green

            }
            catch  {

                Write-Host -Object "An error occured while invoking IFTT unmute trigger: $($_.Exception.Message)" -ForegroundColor Yellow

            }   
        }

    
    #playing end notification sound
    if (Test-Path -Path $EndNotificationSound) {

    #Playing end of focus session notification
    $player = New-Object System.Media.SoundPlayer $EndNotificationSound -ErrorAction SilentlyContinue
     1..2 | ForEach-Object {
         $player.Play()
        Start-Sleep -m 1400 
    }

    }

}

Start-SimplePomodoro -SpotifyPlayList spotify:playlist:XXXXXXXXXXXXXXXXXX -IFTTMuteTrigger pomodoro_start -IFTTUnMuteTrigger pomodoro_stop -IFTTWebhookKey XXXXXXXXX
#reset
#Start-SimplePomodoro -Minutes 0.1 -SpotifyPlayList spotify:playlist:XXXXXXXXXXXXXXXXXX -IFTTMuteTrigger pomodoro_start -IFTTUnMuteTrigger pomodoro_stop -IFTTWebhookKey XXXXXXXXX


