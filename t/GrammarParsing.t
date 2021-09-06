use Test;
use IO::Glob;
use TestHelperMethods;

subtest "Correctly differentiates between Exam Files and Non-ExamFiles" => {
    
    subtest "Parse sample responses" => {
        parseWholeDirectory(dirPath => "t/testResources/SampleResponses/", shouldPass => 1)
    }
    
    subtest "Parse own correct files" => {
        parseWholeDirectory(dirPath => "t/testResources/OwnFiles/ShouldParseWithoutErrorFiles/", shouldPass => 1);
    }
    
    subtest "Fail to parse incorrect files" => {
        parseWholeDirectory(dirPath => "t/testResources/OwnFiles/ShouldNotParseFiles/", shouldPass => 0);
    }
    
}



done-testing;
