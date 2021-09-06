use IO::Glob;
use ExamFileParser;
use Test;

unit module TestHelperMethods;


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
