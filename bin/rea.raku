#!/usr/bin/env raku
use ExamFileParser;
use MasterFileConverter;

sub MAIN($command, $fileName) {
    if ($command eq "create") {
        
        
        createTestsFromMasterFile(masterFileName => $fileName, count => 1);

#
#        my EFParser $masterExam = EFParser.new(:$fileName);
#
#        say $masterExam.QACombos[0].markedAnswers[0];
#        say $masterExam.intro;
        
    }
    
    else {
        say "Invalid Command \"$command\", try any of these:\n\t- create"
    }
}