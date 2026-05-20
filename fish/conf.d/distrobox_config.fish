if status --is-interactive
    test -z "$USER"; and set -gx USER (id -un 2>/dev/null)
    test -z "$UID"; and set -gx UID (id -ur 2>/dev/null)
    test -z "$EUID"; and set -gx EUID (id -u 2>/dev/null)

    test -z "$XDG_RUNTIME_DIR"; and set -gx XDG_RUNTIME_DIR /run/user/(id -ru)
    test -z "$DBUS_SESSION_BUS_ADDRESS"; and set -gx DBUS_SESSION_BUS_ADDRESS unix:path=$XDG_RUNTIME_DIR/bus

    if test -e /var/tmp/.$USER.passwd.initialize
        echo "First time user password setup"
        trap "echo; exit" INT
        passwd; and rm -f /var/tmp/.$USER.passwd.initialize
        trap - INT
    end
end
