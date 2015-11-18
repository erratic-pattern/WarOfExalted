#!/usr/bin/env perl
#
# This script auto-generates a Lua table from this wiki table: https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API#modifierfunction
#
use strict; use warnings;

# constants
my $tabWidth = 4;

my $tab = ' ' x $tabWidth;

my $luaHeader = <<END
-- NOTE: the following code is auto-generated from wiki documentation https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API#modifierfunction
declareFunctionsMap = {
END
;

my $luaFooter = <<END
}
-- end auto-generated code
END
;

# read entire file into string
local $/;
local $_ = <>;

# convert lines
s/\r\n?/\n/g;

# strip out stuff before wiki table contents
s/^.*?=+ modifierfunction =+\n.*?Description\n.//s;

print $luaHeader;

# convert wiki table rows into Lua table
while ( m/\|-\n\| (.+?)\n\|.+?\n\| (.*?)\n/mg ) {
	next unless $2;
	print "$tab$2 = $1,\n";
}

print $luaFooter;
