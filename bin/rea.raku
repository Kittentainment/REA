#!/usr/bin/env raku -Ilib
use Parsing::ExamFileParser;
use Output::MasterFileConverter;
use Evaluation::EvaluateFilledOutFiles;
use Output::DisplayEvaluatedResult;

#| REA (Raku Exam Automation) Takes two arguments:
#| - which command shall be executed
#| - the name of the MasterFile
sub MAIN($command, $masterFileName, *@filledOutFileNames) {
    if ($command ~~ /c[reate]?/) {
        createTestsFromMasterFile(:$masterFileName, count => 1);
    }
    elsif($command ~~ /e[val[uate]?]?/) {
        my @results = evaluateFilledOutFiles(:$masterFileName, :@filledOutFileNames);
        handleResults(:@results);
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