#!/bin/sh

combine_kv () {
    local rootName=$1
    local inDir=$2
    local outFile=$3
    if [ -d $inDir ]; then
        echo \"$rootName\"' {' > $outFile
        find $inDir -type f | sed -i -e 's/^/\t/g' >> $outFile
        echo '}' >> $outFile
    else
        echo "Directory not found: $inDir"
    fi
}

combine_kv WoeAbilities abilities/woe woe_abilities.txt
combine_kv WoeItems items/woe woe_items.txt
combine_kv WoeUnits units/woe woe_units.txt
combine_kv WoeHeroes heroes/woe woe_heroes.txt