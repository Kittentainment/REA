#!/usr/bin/env raku
use ExamFileParser;
use MasterFileConverter;

sub MAIN($command, $masterFileName) {
    if ($command eq "create") {
        createTestsFromMasterFile(:$masterFileName, count => 1);
    }
    elsif($command eq "evaluate") {
        # TODO
    }
    elsif ($command ~~ /'-'h|help/) {
        showHelp();
    }
    
    else {
        say "Invalid Command \"$command\".\n";
        showHelp();
    }
}

sub showHelp() {
    say "rea works with the following commands
\t- create <path/to/masterfile>
\t\tParse a master file and create exams for it. #TODO: Explain how to create a master file.";
}