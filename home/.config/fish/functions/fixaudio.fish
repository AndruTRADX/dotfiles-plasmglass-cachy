function fixaudio --wraps='systemctl --user restart pipewire pipewire-pulse wireplumber' --description 'alias fixaudio systemctl --user restart pipewire pipewire-pulse wireplumber'
    systemctl --user restart pipewire pipewire-pulse wireplumber $argv
end
