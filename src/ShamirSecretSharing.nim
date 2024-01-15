import
  std/[times],
  ../constantine/constantine/math/config/[type_ff, curves],
  ../constantine/constantine/math/arithmetic,
  ../constantine/constantine/math/io/[io_bigints, io_fields],
  ../constantine/constantine/curves_primitives,
  ../constantine/helpers/prng_unsafe

type
  Scalar* = Fr[Banderwagon]
  Polynomial* = object
    coeffs*: seq[Scalar]

  ShamirShare* = object
    id*: int
    value*: Scalar

  Shamir* = object
    threshold*: int
    limit*: int
    shares*: seq[ShamirShare]


var rng: RngState
let seed = uint32(getTime().toUnix() and (1'i64 shl 32 - 1)) # unixTime mod 2^32
rng.seed(seed)

func shamirInit*(s: var Shamir, threshold: int, limit: int) =
  s.threshold = threshold
  s.limit = limit

func polyInit*(poly: var Polynomial, intercept: Scalar, degree: int, rand: var RngState) =
  poly.coeffs.add(intercept)
  for i in 1 ..< degree :
    poly.coeffs.add(rand.random_unsafe(Scalar))

func polyEval*(poly: Polynomial, x: Scalar): Scalar =
  var degree = len(poly.coeffs) - 1
  var eval: Scalar
  eval = poly.coeffs[degree]
  for i in countdown(degree-1, 0) :
    eval.prod(eval, x)
    eval.sum(eval, poly.coeffs[i])
  return eval

func getShares*(s: var Shamir, secret: Scalar, rand: var RngState) =
  var poly: Polynomial
  poly.polyInit(secret, s.threshold, rand)
  for i in 0 ..< s.limit :
    var x: Scalar
    x.fromInt(i+1)
    var ss: ShamirShare
    ss.id = i+1
    ss.value = poly.polyEval(x)
    s.shares.add(ss)

func interpolate*(res: var Scalar, xs, ys: seq[Scalar]) = 
  res.setZero()
  for i, xi in xs:
    var num: Scalar
    num.setOne()
    var den: Scalar
    den.setOne()
    for j, xj in xs:
      if i == j:
        continue
      num.prod(num, xj)
      var xjMinusXi: Scalar
      xjMinusXi.diff(xj, xi)
      den.prod(den, xjMinusXi)

    den.inv()
    var tmp: Scalar
    tmp.prod(num, den)
    tmp.prod(tmp, ys[i])
    res.sum(res, tmp)

func combine*(secret: var Scalar, ss: Shamir) =
  var xs: seq[Scalar]
  var ys: seq[Scalar]
  for i in 0 ..< len(ss.shares) :
    var xi: Scalar
    xi.fromInt(ss.shares[i].id)
    xs.add(xi)
    ys.add(ss.shares[i].value)

  secret.interpolate(xs, ys)


var testShamir: Shamir
testShamir.shamirInit(3, 5)
var mySecret = rng.random_unsafe(Scalar)
echo "My secret: ", mySecret.toHex()

echo testShamir

echo "Splitting Secret"
testShamir.getShares(mySecret, rng)

echo "Splitting Done"
for i in 0 ..< len(testShamir.shares) :
  echo testShamir.shares[i].id, " - ", testShamir.shares[i].value.toHex()

var combinedSecret {.noInit.} : Scalar

echo "Let us combine the shares - all 5"
combinedSecret.combine(testShamir)
echo "Combined Secret: ", combinedSecret.toHex()

echo "Let us combine the shares - any 4"
testShamir.shares.delete(0)
combinedSecret.combine(testShamir)
echo "Combined Secret: ", combinedSecret.toHex()

echo "Let us combine the shares - any 3"
testShamir.shares.delete(0)
combinedSecret.combine(testShamir)
echo "Combined Secret: ", combinedSecret.toHex()

echo "Let us combine the shares - any 2"
testShamir.shares.delete(0)
combinedSecret.combine(testShamir)
echo "Combined Secret: ", combinedSecret.toHex()

echo "Let us combine the shares - any 1"
testShamir.shares.delete(0)
combinedSecret.combine(testShamir)
echo "Combined Secret: ", combinedSecret.toHex()