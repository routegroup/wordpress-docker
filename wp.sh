#!/usr/bin/env bash

colour_bold="${colour_bold:-""}"
colour_green="${colour_green:-""}"
colour_normal="${colour_normal:-""}"
colour_red="${colour_red:-""}"
colour_rev="${colour_rev:-""}"

show_commands() {
    echo "Supported commands:"
    echo "${colour_bold}cli <COMMAND>${colour_normal} runs wp-cli"
}

if [ $# = 0 ] ; then
    show_commands
    exit;
fi

case $1 in
    cli)
        shift 1;
        docker-compose run --rm --no-deps wordpress-cli "$@";
        exit;
    ;;

    help)
        show_commands
        exit;
    ;;

    *)
        echo "Unknown command ${colour_bold}$1${colour_normal}"
        show_commands
        exit;
    ;;
esac