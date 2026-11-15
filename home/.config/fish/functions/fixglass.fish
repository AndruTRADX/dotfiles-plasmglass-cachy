function fixglass --description 'Rebuild the KWin glass and rounded corners effects after a KWin upgrade'
    paru -S --rebuild --noconfirm kwin-effects-glass-git kwin-effect-rounded-corners-git $argv
    and echo "Glass and rounded corners rebuilt. Log out and back in to load them."
end
