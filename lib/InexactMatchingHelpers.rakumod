unit module InexactMatchingHelpers;

use Text::Levenshtein::Damerau;


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

#| Returns the normalized version of the given text.
#| Normalization consists of:
#|   o converting the text to lower-case;
#|   o removing any “stop words” from the text;
#|   o removing any sequence of whitespace characters at the start and/or the end of the text;
#|   o replacing any remaining sequence of whitespace characters within the text with a single space character.
sub normalizeText(Str $text) returns Str is export {
    my Str $newText = $text;
    $newText .= lc;
    for @stopWords -> $stopWordRegex {
        $newText .= subst($stopWordRegex," ",:g);
    }
    $newText .= trim;
    $newText .= subst(/\s+/," ",:g);
    return $newText;
}

#| Returns True if the LevenstheinDamerau distance is ≤ than $maxDifference (in %) of the length of the $expectedText.
sub isDamerauLevenstheinCompatible(Str :$expectedText, Str :$actualText, Int :$maxDifferece = 10) returns Bool is export {
    my Int $maxDistance = ($expectedText.chars * $maxDifferece) div 100;
    my Int $distance = dld($actualText, $expectedText, $maxDistance);
    if ($distance.defined) { # dld returns an undefined Int if it doesn't match until $maxDistance is reached.
        return True;
    } else {
        return False;
    }
}

sub normalizeAndCheckDistance(Str :$expectedText, Str :$actualText, Int :$maxDifferece = 10) returns Bool is export {
    return isDamerauLevenstheinCompatible(expectedText => normalizeText($expectedText), actualText => normalizeText($actualText), :$maxDifferece)
}