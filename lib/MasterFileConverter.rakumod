unit module MasterFileConverter;

use ExamFileParser;

my Str $endOfExamMarker = "=" x 80 ~ "\n";

my Str $outputDirName = "generated_exams";

sub createTestsFromMasterFile (Str :$masterFileName, Int :$count = 1) is export {
    # TODO test count >= 1;
    
    say "Parsing...";
    
    my EFParser $masterExam = EFParser.new(fileName => $masterFileName);
    
    say "Succesfully parsed $masterFileName";
    
    say "Creating $count Exam File{ $count > 1 ?? "s" !! "" }...";
    for 1 .. $count -> $i {
        my Str $examText = convertToRandomExamString($masterExam);
        saveAsFile(:$examText, :$masterFileName, iteration => $count > 1 ?? $i !! -1);
    }
    say "Succesfully created $count Exam File{ $count > 1 ?? "s" !! "" } in folder $outputDirName.";
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
    
    $examText ~= $endOfExamMarker;
    $examText ~= $efParser.endOfExamText ~ "\n";
    $examText ~= $endOfExamMarker;
    
    return $examText;
}

#|{
Saves the file in the form YYYYMMDD-HHMMSS- followed by the name of the original file.
If we process a batch of multiple files, the form is YYYYMMDD-HHMMSS-$iteration- followed by the name of the
original file. If only one file should be generated, don't set $iteration, or set it to a negative number.
}
sub saveAsFile(Str :$examText, Str :$masterFileName, :$iteration = -1) {
    my Str $outputDirPath = $masterFileName.IO.dirname ~ "/" ~ $outputDirName;
    unless ($outputDirPath.IO.e) {
        $outputDirPath.IO.mkdir;
    }
    my DateTime $currDate = DateTime.now;
    my Str $newFileName = $outputDirPath ~ "/";
    $newFileName ~= $currDate.yyyy-mm-dd.subst('-', :g) ~ '-';
    $newFileName ~= $currDate.hh-mm-ss.subst(':', :g) ~ '-';
    if ($iteration >= 0) {
        # If we want to build multiple files in the same batch, they should be numbered. Otherwise they would very likely have the same name, as they were generated in the same second.
        $newFileName ~= $iteration ~ '-';
    }
    $newFileName ~= $masterFileName.IO.basename;
    
    if ($newFileName.IO.e) {
        note "File $newFileName already exists. Did not overwrite.";
        return;
        # Let's the user decide, whether to overwrite or not. Not likely necessary. Could maybe be extracted to a separate component, in case we need it elsewhere too.
        #        say "File $newFileName already exists.\nShould it be overwritten? (y/N)";
        #        my $answer = get();
        #        unless ($answer ~~ /Y|y|Yes/) {
        #            say "Writing stopped!";
        #            return;
        #        }
    }
    
    $newFileName.IO.spurt: $examText;
}

    
    
    

