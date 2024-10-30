# Incremental completion for zsh
# by y.fujii <y-fujii at mimosa-pudica.net>, public domain

autoload -U compinit

# define widgets
zle -N self-insert self-insert-incr # replace default self-insert
zle -N vi-cmd-mode-incr # define a new widget
zle -N vi-backward-delete-char-incr
zle -N backward-delete-char-incr
zle -N expand-or-complete-prefix-incr

compinit

# shortkey for vi insert mode
bindkey -M viins '^[' vi-cmd-mode-incr               # ESC
bindkey -M viins '^h' vi-backward-delete-char-incr   # Ctrl + H
bindkey -M viins '^?' vi-backward-delete-char-incr   # Del
bindkey -M viins '^i' expand-or-complete-prefix-incr # Tab

# shortkey for emacs
bindkey -M emacs '^h' backward-delete-char-incr      # Ctrl + H
bindkey -M emacs '^?' backward-delete-char-incr      # Del
bindkey -M emacs '^i' expand-or-complete-prefix-incr # Tab

unsetopt automenu
compdef -d scp
compdef -d tar
compdef -d make
compdef -d java
compdef -d svn
compdef -d cvs

# TODO:
#     cp dir/

now_predict=0

function limit-completion
{
	if ((compstate[nmatches] <= 1)); then
		zle -M ""
	elif ((compstate[list_lines] > 6)); then
		compstate[list]=""
		zle -M "too many matches."
	fi
}

function correct-prediction
{
	if ((now_predict == 1)); then
		if [[ "$BUFFER" != "$buffer_prd" ]] || ((CURSOR != cursor_org)); then
			now_predict=0
		fi
	fi
}

function remove-prediction
{
	if ((now_predict == 1)); then
		BUFFER="$buffer_org"
		now_predict=0
	fi
}

function show-prediction
{
	# assert(now_predict == 0)
	if
		((PENDING == 0)) &&
		((CURSOR > 1)) &&
		[[ "$PREBUFFER" == "" ]] &&
		[[ "$BUFFER[CURSOR]" != " " ]]
	then
		cursor_org="$CURSOR"
		buffer_org="$BUFFER"
		comppostfuncs=(limit-completion)
		zle complete-word
		cursor_prd="$CURSOR"
		buffer_prd="$BUFFER"
		BUFFER="$buffer_org"
		CURSOR="$cursor_org"
		echo -n "\e[32m"
	else
		zle -M ""
	fi
}

function preexec
{
	echo -n "\e[39m"
}

function vi-cmd-mode-incr
{
	correct-prediction
	remove-prediction
	zle vi-cmd-mode
}

function self-insert-incr
{
	correct-prediction
	remove-prediction
	if zle .self-insert; then
		show-prediction
	fi
}

function vi-backward-delete-char-incr
{
	correct-prediction
	remove-prediction
	if zle vi-backward-delete-char; then
		show-prediction
	fi
}

function backward-delete-char-incr
{
	correct-prediction
	remove-prediction
	if zle backward-delete-char; then
		show-prediction
	fi
}

function expand-or-complete-prefix-incr
{
	correct-prediction
	if ((now_predict == 1)); then
		CURSOR="$cursor_prd"
		now_predict=0
		comppostfuncs=(limit-completion)
		zle list-choices
	else
		remove-prediction
		zle expand-or-complete-prefix
	fi
}
