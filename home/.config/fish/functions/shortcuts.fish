function shortcuts --description 'List the global shortcuts KDE has right now. Add words to filter: shortcuts tile, shortcuts meta+ctrl'
    set -l filter (string lower -- "$argv")
    set -l bold
    set -l normal
    if isatty stdout
        set bold (set_color --bold)
        set normal (set_color normal)
    end

    # 1) read KDE's own file   2) sort by group, then by keys   3) print aligned under one heading per group
    awk -v filter="$filter" '
        BEGIN { backslash_t = sprintf("%ct", 92) }      # KDE separates alternative keys with a literal \t
        /^[[]/ {                                        # [kwin], [services][org.kde.konsole.desktop], ...
            group = $0; gsub(/^[[]|[]]$/, "", group)
            app = ""
            if (sub(/^services[]][[]/, "", group)) {    # shortcuts that launch an app or one of its actions
                app = group; sub(/[.]desktop$/, "", app); sub(/^org[.]kde[.]/, "", app); group = "Apps"
            }
            skip = index(group, "$InverseAction")       # internal pairs, not shortcuts
            next
        }
        skip || !index($0, "=") { next }
        {
            action = substr($0, 1, index($0, "=") - 1)
            count = split(substr($0, index($0, "=") + 1), field, ",")    # keys,default keys,description (apps: keys only)
            if (action == "_k_friendly_name") { title[group] = field[1]; next }
            keys = field[1]
            if (keys == "" || keys == "none") next
            while ((i = index(keys, backslash_t)) > 0) keys = substr(keys, 1, i - 1) ", " substr(keys, i + 2)
            what = field[3]; for (j = 4; j <= count; j++) what = what "," field[j]
            if (app != "") what = (action == "_launch") ? app : app ": " action
            row[++rows] = group "\t" keys "\t" what; rowgroup[rows] = group
        }
        END {
            for (r = 1; r <= rows; r++) {
                line = row[r]
                if (rowgroup[r] in title) line = title[rowgroup[r]] substr(line, length(rowgroup[r]) + 1)
                if (filter == "" || index(tolower(line), filter)) print line
            }
        }
    ' ~/.config/kglobalshortcutsrc | LC_ALL=C sort -u | awk -F'\t' -v bold="$bold" -v normal="$normal" '
        { group[NR] = $1; keys[NR] = $2; what[NR] = $3; if (length($2) > width) width = length($2) }
        END {
            for (r = 1; r <= NR; r++) {
                if (group[r] != group[r - 1]) printf "%s%s%s%s\n", (r > 1 ? "\n" : ""), bold, group[r], normal
                printf "  %-" width "s  %s\n", keys[r], what[r]
            }
            if (NR == 0) print "No shortcut matches."
        }
    '
end
