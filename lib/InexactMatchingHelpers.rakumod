unit module InexactMatchingHelpers;


my Regex @stopWords;
loadStopWords(filePath => "resources/StopWords.txt");

sub loadStopWords(:$filePath) {
    for $filePath.IO.lines -> $line {
        if ($line && $line !~~ /^'#'/) { # ignore empty lines and comment lines
            my Regex $wordRegex = /[^^|\s] $($line.trim) [$$|\s]/;
            @stopWords.append($wordRegex);
        }
    }
}

#| Normalization consists of:
#|   o converting the text to lower-case;
#|   o removing any “stop words” from the text;
#|   o removing any sequence of whitespace characters at the start and/or the end of the text;
#|   o replacing any remaining sequence of whitespace characters within the text with a single space character.
sub normalizeText(:$text) returns Str is export {
    my Str $newText = $text;
    $newText .= lc;
    for @stopWords -> $stopWordRegex {
        $newText .= subst($stopWordRegex," ",:g);
    }
    $newText .= trim;
    $newText .= subst(/\s+/," ",:g);
    return $newText;
}

sub isDamerauLevenstheinCompatible(Str :$expectedText, Str :$actualTest, Int :$maxDifferece) returns Bool {

}