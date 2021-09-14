unit module DisplayEvaluatedResult;

#enum DisplayMethods <CONSOLE FILE>;

my Int $displayWidth = 120;

my Str $lightSeparator = '-' x $displayWidth;
my Str $strongSeparator = '=' x $displayWidth;
my $symbolForSevereAnswers = '!';


sub handleResults(:@results) is export {
    
    displayResults(:@results);
    
    say $strongSeparator;
    
    displayWarnings(:@results);
    
    displayFailures(:@results);
    
    say $strongSeparator;
    
}



sub displayResults(:@results) {
    say "\nRESULTS:\n";
    
    for @results -> $result {
        my Str $fileName = $result.fileName;
        
        print $fileName;
        if ($result.isOk) {
            print '.' x ($displayWidth - $fileName.chars - 5);
            printf "%02d/%02d", $result.score, $result.triedToAnswer;
        } else {
            print '.' x ($displayWidth - $fileName.chars - $result.reason.chars);
            print $result.reason
        }
        
        say "";
    }
    
    say "\n$lightSeparator\n";
}


sub displayWarnings(:@results) {
    say "\nWARNINGS\n";
    say "The following files have thrown one or more warnings. Further examination might be necessary.";
    say "Warnings marked with a $symbolForSevereAnswers mean we can't guarantee correct grading for this file. We highly reccommend further examination!\n";
    
    for @results -> $result {
        next if (!$result.isOk || !$result.hasWarnings);
        
        displaySingleFileWarnings(:$result);
        say "";
    }
    
}

sub displaySingleFileWarnings(:$result) {
    say $result.fileName ~ ":";
    for $result.warnings -> $warningInfo {
        print $warningInfo.toExtendedString(:$symbolForSevereAnswers, lineIndent => "\t");
    }
}


sub displayFailures(:@results) {
    my @allFailures = getAllFailures(:@results);
    return unless (@allFailures);

    say $strongSeparator;
    say "\nERRORS\n";
    say "The following files have failed to be evaluated completely:\n";

    for @allFailures -> $failedResult {
        say $failedResult.reason ~ ": " ~ $failedResult.fileName;
    }
    
    say "";
    
}

sub getAllFailures(:@results) {
    gather {
        for @results -> $result {
            next if ($result.isOk);
            take $result;
        }
    }
}




















# Maybe for when we have enough time

#    displayMetaOverview();
#
#    askForFurtherActions();
#
#    my DisplayMethods @displayMethods = askForDisplayMethods();
#
#    for @displayMethods -> $displayMethod {
#        given $displayMethod {
#            when CONSOLE {
#                displayOnConsole(:@results);
#            }
#            when FILE {
#                saveToFile(:@results);
#            }
#        }
#    }
#}
#
#
##| Displays
##| - Evaluated File Number
##| - Warning Count
##| - Error Count
#sub displayMetaOverview() {
#
#}
#
##| Possible Actions
##| - quit
##| - save to file
##|      - save all
##|      - save only ok
##|      - save only warnings / errors
##| - display results on console
##|      - show specific file
##| - investigate
##|      - show all files with warnings
##|          - show specific file
##|      - show all files with errors
##|          - show specific file
##|      - show all possible cheaters
##|
#sub askForFurtherActions(){
#
#}
