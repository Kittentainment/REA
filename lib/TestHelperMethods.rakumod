use IO::Glob;
use ExamFileParser;

unit module TestHelperMethods;


sub parseWholeDirectory($dirPath) is export {
    for glob($dirPath ~ "*") -> $file {
        if ($file.d) { next(); }
        parseFile(:$file);
    }
}

sub parseFile(:$file) is export {
    
    my EFParser $parseTree = EFParser.new(fileName => $file.relative);
    
    say $parseTree;
}
