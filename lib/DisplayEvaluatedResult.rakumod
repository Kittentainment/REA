unit module DisplayEvaluatedResult;

#enum DisplayMethods <CONSOLE FILE>;

my Int $displayWidth = 120;

my Str $lightSeparator = '-' x $displayWidth;
my Str $strongSeparator = '=' x $displayWidth;
my $symbolForSevereAnswers = '!';
my $lineIndent = "\t";
my $verbose = True;
my $showWarnings = True;


sub handleResults(:@results) is export {
    
    askForWarningsAndErrors();
    askForVerboseOutput();
    
    displayResults(:@results);
    displayWarnings(:@results);
    displayFailures(:@results);
    displaySummary(:@results);
    
}


sub askForWarningsAndErrors() {
    $showWarnings = askYesNoQuestion('Show warnings?');
}

sub askForVerboseOutput() {
    $verbose = askYesNoQuestion('Do you want a verbose report?');
}

sub askYesNoQuestion($question) returns Bool {
    for (1) {
        my $answer = prompt($question ~ " [N/Y]");
        if ($answer ~~ / [Y|y][es]?  /) {
            return True;
        }
        elsif ($answer ~~ /[N|n]o?/) {
            return False;
        } else {
            say "Please answer with Yes or No (or y or n)!";
        }
    }
}



sub displayResults(:@results) {
    say "\nRESULTS:\n";
    
    for @results -> $result {
        say $result.getResultAsString(:$displayWidth);
    }
    
    say "\n$lightSeparator\n";

    say $strongSeparator;
}


sub displayWarnings(:@results) {
    return unless $showWarnings;
    my @allWarnings = getAllWarnings(:@results);
    return unless @allWarnings;
    
    say "\nWARNINGS\n";
    if ($verbose) {
        say "The following files have thrown one or more warnings. Further examination might be necessary.";
        say "Warnings marked with a $symbolForSevereAnswers mean we can't guarantee correct grading for this file. We highly reccommend further examination!\n";
    }
    
    for @allWarnings -> $result {
        say $result.getWarningsAsString(:$symbolForSevereAnswers, :$lineIndent, :$verbose);
    }

    say $strongSeparator;
}

sub getAllWarnings(:@results) {
    gather {
        for @results -> $result {
            next if (!$result.isOk || !$result.hasWarnings);
            take $result;
        }
    }
}



sub displayFailures(:@results) {
    my @allFailures = getAllFailures(:@results);
    return unless (@allFailures);
    
    say "\nERRORS\n";
    if $verbose {
        say "The following files have failed to be evaluated completely:\n";
    }
    
    for @allFailures -> $failedResult {
        say $failedResult.getFailuresAsString();
    }
    
    say "";
    say $strongSeparator;
    
}

sub getAllFailures(:@results) {
    gather {
        for @results -> $result {
            next if ($result.isOk);
            take $result;
        }
    }
}


sub displaySummary(:@results) {
    return unless $verbose;
    
    say "\nSUMMARY\n";
    
    say "Evaluated " ~ @results.elems ~ " files.";
    say "Found " ~ getAllWarnings(:@results).elems ~ " files with warnigns.";
    say "Failed to evaluate " ~ getAllFailures(:@results).elems ~ " files.";
    say "";
    say $strongSeparator;
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
