import unittest

import ShamirSecretSharing

test "Shamir Secret Sharing - Splitting and Recombination":
  proc testSplitAndRecombine() =
    var testShamir: Shamir
    testShamir.shamirInit(3, 5)
    
    var mySecret = rng.random_unsafe(Scalar)
  
  testSplitAndRecombine()
