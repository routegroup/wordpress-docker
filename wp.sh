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
    echo "${colour_bold}db:import <PATH>${colour_normal} runs imports SQL from path"
    echo "${colour_bold}db:export <PATH>${colour_normal} create new SQL file"
    echo "${colour_bold}db:reset <PATH>${colour_normal} recreate db"
    echo "${colour_bold}build ${colour_normal} create production with correct file structure"
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

    db:import)
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

    db:export)
        shift 1
        SQL_FILENAME="backup-$(date +%s).sql"
        docker-compose exec db /bin/bash -c "mysqldump -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_NAME > /sql/$SQL_FILENAME"
        exit
    ;;

    db:reset)
        docker-compose exec db mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "drop database $WORDPRESS_DB_NAME"
        docker-compose exec db mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" -e "create database $WORDPRESS_DB_NAME"
        exit
    ;;

    build)
        WORDPRESS_FILENAME="wordpress-$WORDPRESS_VERSION.zip"
        WORDPRESS_URL="https://wordpress.org/$WORDPRESS_FILENAME"
        WORDPRESS_BUILD_PATH="./build/$WORDPRESS_VERSION"

        if [ ! -f "./build/$WORDPRESS_FILENAME" ]; then
            wget "$WORDPRESS_URL" -O "./build/$WORDPRESS_FILENAME"
        fi
        
        rm -rf "./build/wordpress"
        rm -rf "./build/$WORDPRESS_VERSION"
        unzip -q "./build/$WORDPRESS_FILENAME" -d "./build"
        mv "./build/wordpress" "$WORDPRESS_BUILD_PATH"
        
        rm -rf "$WORDPRESS_BUILD_PATH/wp-content/themes/twentytwenty"
        rm -rf "$WORDPRESS_BUILD_PATH/wp-content/themes/twentytwentyone"
        rm -rf "$WORDPRESS_BUILD_PATH/wp-content/themes/twentytwentytwo"
        rm -rf "$WORDPRESS_BUILD_PATH/wp-content/themes/twentytwentytwo"
        
        rm -rf "$WORDPRESS_BUILD_PATH/wp-content/plugins/akismet"
        rm -rf "$WORDPRESS_BUILD_PATH/wp-content/plugins/hello.php"

        cp -r ./plugins "$WORDPRESS_BUILD_PATH/wp-content"
        cp -r ./themes "$WORDPRESS_BUILD_PATH/wp-content"
        cp -r ./uploads "$WORDPRESS_BUILD_PATH/wp-content"

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