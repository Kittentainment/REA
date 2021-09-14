use Test;
use EvaluateFilledOutFiles;
use Results;

#
#subtest 'Evaluate Single File' => {
#    my @results = evaluateFilledOutFiles(masterFileName => "t/testResources/OwnFiles/LevenshteinTestFiles/short_exam_master_file.txt", filledOutFileNames => @("t/testResources/OwnFiles/LevenshteinTestFiles/generated_exams/emtpyFile.txt"));
#
#    is @results.elems, 1, 'Num of Elements';
#
#    my @expectedResults = (FailedTestResult.new(FailureInfo.new(PARSING_FAILURE)));
#    is-deeply @results, @expectedResults, 'Correct result';
#};


done-testing;
