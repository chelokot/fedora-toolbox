if status is-interactive
    starship init fish | source

    function __chelokot_container_context
        test -r /run/.containerenv; or return

        set -l name (sed -n 's/^name="\([^"]*\)"$/\1/p' /run/.containerenv)
        test -n "$name"; or return

        set_color --dim yellow
        printf '  %s' "$name"
        set_color normal
    end

    function fish_right_prompt
    end

    function fish_prompt
        switch "$fish_key_bindings"
            case fish_hybrid_key_bindings fish_vi_key_bindings fish_helix_key_bindings
                set STARSHIP_KEYMAP "$fish_bind_mode"
            case '*'
                set STARSHIP_KEYMAP insert
        end

        set STARSHIP_CMD_PIPESTATUS $pipestatus
        set STARSHIP_CMD_STATUS $status
        set STARSHIP_DURATION "$CMD_DURATION$cmd_duration"

        if contains -- --final-rendering $argv
            if test "$STARSHIP_CMD_STATUS" -eq 0
                printf "\e[1;32m❯\e[0m "
            else
                printf "\e[1;31m❯\e[0m "
            end
            return
        end

        __starship_set_job_count

        set -l prompt_lines (/usr/bin/starship prompt --terminal-width="$COLUMNS" --status=$STARSHIP_CMD_STATUS --pipestatus="$STARSHIP_CMD_PIPESTATUS" --keymap=$STARSHIP_KEYMAP --cmd-duration=$STARSHIP_DURATION --jobs=$STARSHIP_JOBS | string split \n)
        set -l right_context (__chelokot_container_context)

        if test (count $prompt_lines) -eq 0
            return
        end

        set -l first_line $prompt_lines[1]
        set -l right_width (string length --visible -- "$right_context")
        set -l right_column (math "$COLUMNS - $right_width - 1")

        if test -n "$right_context"; and test "$right_column" -gt 1
            printf '%s' "$first_line"
            printf '\e[s\e[%dG  %s\e[u\n' "$right_column" "$right_context"
        else
            printf '%s\n' "$first_line"
        end

        if test (count $prompt_lines) -gt 1
            printf '%s' "$prompt_lines[2]"
        end
    end

    set -g fish_transient_prompt 1
end
