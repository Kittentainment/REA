unit module MasterFileConverter;

use ExamFileParser;

my Str $endOfExamText =
        "=" x 80 ~ "\n"
                ~ " " x 34 ~ "END OF EXAM" ~ " " x 35 ~ "\n" ~
                "=" x 80 ~ "\n";

my Str $outputDirName = "generated_exams";

sub createTestsFromMasterFile (Str :$masterFileName, Int :$count = 1) is export {
    # TODO test count >= 1;
    
    my EFParser $masterExam = EFParser.new(fileName => $masterFileName);
    
    for 1 .. $count {
        my Str $examText = convertToRandomExamString($masterExam);
        saveAsFile(:$examText, :$masterFileName)
    }
}


sub convertToRandomExamString(EFParser $efParser) {
    my Str $examText = "";
    
    $examText ~= $efParser.intro;
    
    for $efParser.QACombos -> $qaCombo {
        $examText ~= $efParser.separator ~ "\n\n\n";
        
        $examText ~= $qaCombo.question ~ "\n\n";
        my Str @allAnswerTexts = $qaCombo.getAllAnswerTexts;
        for (@allAnswerTexts.pick(*)) -> $answerText {
            $examText ~= "\t[ ] $answerText\n";
        }
        $examText ~= "\n";
    }
    
    $examText ~= $endOfExamText;
    
    return $examText;
}


sub saveAsFile(Str :$examText, Str :$masterFileName) {
    my Str $outputDirPath = $masterFileName.IO.dirname ~ "/" ~ $outputDirName;
    unless ($outputDirPath.IO.e) {
        $outputDirPath.IO.mkdir;
    }
    my DateTime $currDate = DateTime.now;
    my Str $newFileName = $outputDirPath ~ "/testresult.txt";
    
    $newFileName.IO.spurt: $examText;
    
    
#    say "TODO saveAsFile: $examText";
}

    
    
    

