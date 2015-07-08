#!/bin/sh

combine_kv () {
    local rootName=$1
    local inDir=$2
    local outFile=$3
    if [ -d $inDir ]; then
        echo \"$rootName\"' {' > $outFile
        sed -e 's/^/\t/g' $inDir/*.txt >> $outFile
        echo '}' >> $outFile
    else
        echo "Directory not found: $inDir"
    fi
}

combine_kv DOTAAbilities abilities npc_abilities_custom.txt
combine_kv DOTAHeroes heroes npc_heroes_custom.txt
combine_kv DOTAItems items npc_items_custom.txt
combine_kv DOTAUnits units npc_units_custom.txt
combine_kv WoeAbilities abilities/woe woe_abilities.txt
combine_kv WoeItems items/woe woe_items.txt
combine_kv WoeUnits units/woe woe_units.txt
combine_kv WoeHeroes heroes/woe woe_heroes.txt