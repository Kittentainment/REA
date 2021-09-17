use Test;
use Output::MasterFileConverter;
use Parsing::ExamFileParser;
use IO::Glob;

subtest 'General Layout Test' => {
    for glob("t/testResources/OwnFiles/MasterGeneratedExamFilePairs/master-*.txt") -> $masterFile {
        $masterFile.relative ~~ /master'-'$<number>=(\d+)$<optionalNumber>=(['-'\d+]?)'.'txt/;
        createTestsFromMasterFile(masterFileName => $masterFile.relative);
        my $generatedFile = glob("t/testResources/OwnFiles/MasterGeneratedExamFilePairs/generated_exams/*master-$<number>$<optionalNumber>.txt").dir[0];
        my $solutionFile = glob("t/testResources/OwnFiles/MasterGeneratedExamFilePairs/solution-$<number>.txt").dir[0];
        
        is $solutionFile.slurp, $generatedFile.slurp, "Compare File Content";
        
        $generatedFile.unlink;
    }
    
    "t/testResources/OwnFiles/MasterGeneratedExamFilePairs/generated_exams/".IO.rmdir;
}





done-testing;
