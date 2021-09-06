use Test;
use IO::Glob;
use TestHelperMethods;

subtest "Correctly differentiates between Exam Files and Non-ExamFiles" => {
    
    lives-ok {
        parseWholeDirectory("t/testResources/SampleResponses/")
    };
    
    for glob("t/testResources/OwnFiles/ShouldNotParseFiles/*") -> $file {
        if ($file.d) { next(); }
        dies-ok {
            parseFile(:$file);
        }
    }
    
}



done-testing;
