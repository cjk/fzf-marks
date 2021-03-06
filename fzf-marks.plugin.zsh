if [[ -z "$BOOKMARKS_FILE" ]] ; then
    export BOOKMARKS_FILE="$HOME/.bookmarks"
fi

touch "$BOOKMARKS_FILE"

wfxr::bookmarks-fzf() {
    local list
    (( $+commands[exa] )) && list='exa -lbhg --git' || list='ls -l'
    fzf --border \
        --ansi \
        --cycle \
        --reverse \
        --height '40%' \
        --preview="echo {}|sed 's#.*->  ##'| xargs $list --color=always" \
        --preview-window="right:50%" \
        "$@"
}

function mark() {
    local mark_to_add
    mark_to_add=$(echo "$*: $(pwd)")
    echo "${mark_to_add}" >> "${BOOKMARKS_FILE}"

    echo "** The following mark has been added **"
    echo "${mark_to_add}"
}

function dmark()  {
    local line
    line=$(sed 's#: # -> #' "$BOOKMARKS_FILE"|
        nl| column -t|
        wfxr::bookmarks-fzf --query="$*" -m)

    if [[ -n $line ]]; then
        echo "$line" |awk '{print $1}'| xargs -I{} sed -i "{}d" "$BOOKMARKS_FILE"
        echo "** The following marks have been deleted **"
        echo "$line"
    fi
    zle && zle reset-prompt
}

function jump() {
    target=$(sed 's#: # -> #' "$BOOKMARKS_FILE"|
        nl| column -t|
        wfxr::bookmarks-fzf --query="$*" -1|
        sed 's#.*->  ##')
    if [[ -n "$target" ]]; then
        cd "$target"
        unset target
        zle && zle redraw-prompt
    else
        zle redisplay # Just redisplay if no jump to do
    fi
}

# Ensure precmds are run after cd
function redraw-prompt() {
    local precmd
    for precmd in $precmd_functions; do
        $precmd
    done
    zle reset-prompt
}
zle -N redraw-prompt

zle -N jump
bindkey ${FZF_MARKS_JUMP:-'^g'} jump
if [ "${FZF_MARKS_DMARK}" ]; then
    zle -N dmark
    bindkey ${FZF_MARKS_DMARK} dmark
fi
