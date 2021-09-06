use Test;
use MasterFileConverter;
use ExamFileParser;
use IO::Glob;

subtest 'General Layout Test' => {
    for glob("t/testResources/OwnFiles/MasterGeneratedExamFilePairs/master-*.txt") -> $masterFile {
        $masterFile.relative ~~ /master'-'$<number>=(\d+)$<optionalNumber>=(['-'\d+]?)'.'txt/;
        createTestsFromMasterFile(masterFileName => $masterFile.relative);
        my $generatedFile = glob("t/testResources/OwnFiles/MasterGeneratedExamFilePairs/generated_exams/*master-$<number>$<optionalNumber>.txt").dir[0];
        my $solutionFile = glob("t/testResources/OwnFiles/MasterGeneratedExamFilePairs/solution-$<number>.txt").dir[0];
        
        is $solutionFile.slurp, $generatedFile.slurp;
        
        $generatedFile.unlink;
    }
    
    "t/testResources/OwnFiles/MasterGeneratedExamFilePairs/generated_exams/".IO.rmdir;
}

subtest 'Parser Test' => {
    my $parsed = EFParser.new(fileName => "t/testResources/OwnFiles/ParserTestFiles/exam-00.txt");

    is $parsed.intro, "This is the intro to the exam file 00\n";

    my QACombo @allQACombos;
    
    my $question;
    my @markedAnswers;
    my @unmarkedAnswers;

    $question = "1. first question";
    @markedAnswers = ("answer 1.1");
    @unmarkedAnswers = ("answer 1.2");
    @allQACombos.append(QACombo.new(:$question, :@markedAnswers, :@unmarkedAnswers));

    $question = "2. second question";
    @markedAnswers = ("answer 2.1");
    @unmarkedAnswers = ("answer 2.2");
    @allQACombos.append(QACombo.new(:$question, :@markedAnswers, :@unmarkedAnswers));
    
    is-deeply $parsed.QACombos, @allQACombos;
}




done-testing;
