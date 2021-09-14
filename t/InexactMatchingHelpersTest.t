use Test;

use InexactMatchingHelpers;

subtest "Test Text Normalization" => {
    subtest "Given Example" => {
        my Str $original = "  What is the    airspeed of a fully laden African swallow? ";
        my Str $expected = "what airspeed fully laden african swallow?";
        is normalizeText(text => $original), $expected;
    }
}

done-testing;
