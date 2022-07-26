#!/usr/bin/env bash

set -o allexport
source ./.env
set +o allexport

colour_bold="${colour_bold:-""}"
colour_green="${colour_green:-""}"
colour_normal="${colour_normal:-""}"
colour_red="${colour_red:-""}"
colour_rev="${colour_rev:-""}"

show_commands() {
    echo "Supported commands:"
    echo "${colour_bold}cli <COMMAND>${colour_normal} runs wp-cli"
    echo "${colour_bold}url:set <OLD-URL> <NEW-URL>${colour_normal} changes url"
    echo "${colour_bold}sql:import <PATH>${colour_normal} runs imports SQL from path"
    echo "${colour_bold}sql:export <PATH>${colour_normal} create new SQL file"
}

if [ $# = 0 ] ; then
    show_commands
    exit
fi

case $1 in
    cli)
        shift 1
        docker-compose run --rm --no-deps wordpress-cli "$@"
        exit
    ;;

    url:set)
        shift 1
        docker-compose run --rm --no-deps wordpress-cli search-replace "$@" --all-tables
        docker-compose run --rm --no-deps wordpress-cli elementor replace_urls "$@"
        exit
    ;;

    sql:import)
        shift 1
        SQL_FILENAME="$@"
        if [ -f "$SQL_FILENAME" ]; then
            docker-compose exec db mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "drop database $WORDPRESS_DB_NAME"
            docker-compose exec db mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "create database $WORDPRESS_DB_NAME"
            docker-compose exec db mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" "$WORDPRESS_DB_NAME" -e "source /$SQL_FILENAME"
        else
            echo "SQL doesn't exists"
        fi
        exit
    ;;

    sql:export)
        shift 1
        SQL_FILENAME="backup-$(date +%s).sql"
        docker-compose exec db /bin/bash -c "mysqldump -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_NAME > /sql/$SQL_FILENAME"
        exit
    ;;

    help)
        show_commands
        exit
    ;;

    *)
        echo "Unknown command ${colour_bold}$1${colour_normal}"
        show_commands
        exit
    ;;
esac