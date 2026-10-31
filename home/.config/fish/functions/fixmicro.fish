function fixmicro --description 'Unmute the default microphone and set it to 100%'
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0
    wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1.0
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@
end
