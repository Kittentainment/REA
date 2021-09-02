#!/usr/bin/env raku
use ExamFileParser;

sub MAIN($command, $fileName) {
    if ($command eq "create") {
        
        my EFParser $masterExam = EFParser.new(:$fileName);
        
        say $masterExam.QACombos[0].markedAnswers[0];
        say $masterExam.intro;
        
    }
    
    else {
        say "Invalid Command \"$command\", try any of these:\n\t- create"
    }
}