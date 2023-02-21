#!/bin/zsh

autoload colors; colors

echo $fg[cyan]"Configuring CleanChoice Energy CEO functions...\n"$reset_color

function ceo_email() {
    echo "\n\nchris.bartling+$(date +%s)@cleanchoice.com\n\n"
}

function arc_email() {
    echo "\n\nARC_TEST_R_SINGLE_ELEC$(date +%s)@any-domain.com\n\n"
}


echo $fg[cyan]Available functions$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo $fg[yellow]ceo_email$reset_color
echo $fg[yellow]arc_email$reset_color
echo $fg[cyan]---------------------------------------------$reset_color
echo "\n"