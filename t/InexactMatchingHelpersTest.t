use Test;

use InexactMatchingHelpers;

subtest "Test Text Normalization" => {
    {
        my Str $original = "  What is the    airspeed of a fully laden African swallow? ";
        my Str $expected = "what airspeed fully laden african swallow?";
        is normalizeText($original), $expected, "Given Example";
    }
    
    {
        my Str $original = "  It's the    airspeed of a fully laden African swallow! ";
        my Str $expected = "airspeed fully laden african swallow!";
        is normalizeText($original), $expected, "Stop Words with an appostrophe";
    }
}

subtest "Test isDamerauLevenstheinCompatible" => {
    {
        my Str $expectedText = "AABCDE";
        my Str $actualText = "AABCDE";
        is isDamerauLevenshteinCompatible(:$expectedText, :$actualText), True, "Same String";
    }
    
    {
        my Str $expectedText = "A completely different string that actually means something";
        my Str $actualText = "asdljglkmvoiweio;i3emrvio sdjflksdlkv";
        isnt isDamerauLevenshteinCompatible(:$expectedText, :$actualText), True, "completely different String";
    }
    
    {
        my Str $expectedText = "A very similar string to what is expected";
        my Str $actualText = "very similar string to what is expected";
        is isDamerauLevenshteinCompatible(:$expectedText, :$actualText), True, "very similar string";
    }

    {
        my Str $expectedText = "ABCDEFGHIJ";
        my Str $actualText = "ABCDEFGHIj";
        is isDamerauLevenshteinCompatible(:$expectedText, :$actualText), True, "String with exactly 1 distance in 10 chars (10%)";
    }

    {
        my Str $expectedText = "ABCDEFGHIJ";
        my Str $actualText = "ABCDEFGHij";
        isnt isDamerauLevenshteinCompatible(:$expectedText, :$actualText), True, "String with exactly 2 distance in 10 chars (20%)";
    }
}

done-testing;
