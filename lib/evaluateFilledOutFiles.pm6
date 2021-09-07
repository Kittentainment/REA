unit module evaluateFilledOutFiles;
use ExamFileParser;

sub evaluateFilledOutFiles(:$masterFileName, :@filledOutFileNames) is export{
    my $parsedMasterFile = EFParser.new(fileName => $masterFileName);
    die unless isMasterFileOk(:$parsedMasterFile);
    #
}
sub isMasterFileOk(EFParser :$parsedMasterFile) {
   for $parsedMasterFile.QACombos -> $QACombo {
       if $QACombo.markedAnswers.elems > 1 {
           die "The MasterFile has multiple correct answers for one of the questions, only one is allowed";
       }
       if $QACombo.markedAnswers.elems = 0 {
           die "The MasterFile contains a question without a correct answer";
       }
       say "isMasterFileOk needs improvement"; # maybe
       return 1;
   } ;
}