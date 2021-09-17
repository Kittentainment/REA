unit module InexactMatchingHelpers;

use Text::Levenshtein::Damerau;


my Regex @stopWords;
loadStopWords(filePath => "lib/Evaluation/StopWords.txt");

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

#| Returns True if the LevenshteinDamerau distance is ≤ than $maxDifference (in %) of the length of the $expectedText.
sub isDamerauLevenshteinCompatible(Str :$expectedText, Str :$actualText, Int :$maxDifference = 10) returns Bool is export {
    my Int $maxDistance = ($expectedText.chars * $maxDifference) div 100;
    my Int $distance = dld($actualText, $expectedText, $maxDistance);
    if ($distance.defined) { # dld returns an undefined Int if it doesn't match until $maxDistance is reached.
        return True;
    } else {
        return False;
    }
}

#| Calculates whether the given LevenshteinDamerau distance is ≤ than $maxDifference (in %) of the length of the $expectedText.
#| Used instead of isDamerauLevenshteinCompatible if the actual distance is also needed
sub isGivenDistanceOK(Int :$distance, Str :$expectedText, Int :$maxDifference = 10) returns Bool is export {
    my Int $maxDistance = ($expectedText.chars * $maxDifference) div 100;
    return $distance > $maxDistance ?? False !! True;
}

#| Normalizes the given strings with normalizeText and calls isDamerauLevenstheinCompatible with the normalized strings.
#| Just for convenience, because those two methods will often be used combined like that.
sub normalizeAndCheckDistance(Str $expectedText, Str $actualText, Int :$maxDifference = 10) returns Bool is export {
    return isDamerauLevenshteinCompatible(expectedText => normalizeText($expectedText), actualText => normalizeText($actualText), :$maxDifference)
}