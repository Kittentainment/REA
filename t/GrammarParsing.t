use Test;
use IO::Glob;
use Parsing::ExamFileParser;

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



sub parseWholeDirectory(:$dirPath, :$shouldPass = 1) is export {
    unless ($dirPath ~~ /.*\//) {$dirPath ~ '/'} # directory path should end with a '/'.
    for glob($dirPath ~ "*") -> $file {
        if ($file.d) { next(); }
        parseFile(:$file, :$shouldPass);
    }
}

sub parseFile(:$file, :$shouldPass = 1) is export {
    if ($shouldPass) {
        lives-ok { EFParser.new(fileName => $file.relative) }, "trying to parse $file";
    } else {
        dies-ok { EFParser.new(fileName => $file.relative) }, "trying to fail to parse $file";
    }
}
