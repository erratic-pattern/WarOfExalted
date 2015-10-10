#!/bin/sh

combine_kv () {
    local rootName=$1
    local inDir=$2
    local outFile=$3
    if [ -d $inDir ]; then
        echo \"$rootName\" > $outFile
        echo '{' >> $outFile
        sed -e 's/^/\t/g' $inDir/*.txt >> $outFile
        echo '}' >> $outFile
    else
        echo "Directory not found: $inDir"
    fi
}
cd npc
combine_kv DOTAAbilities abilities npc_abilities_custom.txt
combine_kv DOTAHeroes heroes npc_heroes_custom.txt
combine_kv DOTAItems items npc_items_custom.txt
combine_kv DOTAUnits units npc_units_custom.txt
