function fixglass --description 'Rebuild the KWin glass effect after a KWin upgrade'
    paru -S --rebuild --noconfirm kwin-effects-glass-git $argv
    and echo "Glass effect rebuilt. Log out and back in to load it."
end
