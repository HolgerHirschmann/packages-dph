{-# LANGUAGE PArr #-}
module Data.Array.Parallel.Prelude.Base.Int (
  eq, eqV, neq, neqV, le, leV, lt, ltV, ge, geV, gt, gtV,
  plus, plusV,
  minus, minusV,
  mult, multV,
  intDiv, intDivV, 
  intMod, intModV, 
  intSquareRoot, intSquareRootV,
  intSumPA, intSumP,
  enumFromToPA, enumFromToP,
  upToP, upToPA
) where

import Data.Array.Parallel.Prelude.Base.PArr

import Data.Array.Parallel.Lifted.Combinators
import Data.Array.Parallel.Lifted.Instances
import Data.Array.Parallel.Lifted.Prim
import Data.Array.Parallel.Lifted.Closure
import Data.Array.Parallel.Lifted.PArray



eqV, neqV, leV, ltV, geV, gtV :: Int :-> Int :-> Bool
{-# INLINE eqV #-}
{-# INLINE neqV #-}
{-# INLINE leV #-}
{-# INLINE ltV #-}
{-# INLINE geV #-}
{-# INLINE gtV #-}
eqV = closure2 dPA_Int (==) (unsafe_zipWith (==))
neqV = closure2 dPA_Int (/=) (unsafe_zipWith (/=))
leV = closure2 dPA_Int (<=) (unsafe_zipWith (<=))
ltV = closure2 dPA_Int (<) (unsafe_zipWith (<))
geV = closure2 dPA_Int (>=) (unsafe_zipWith (>=))
gtV = closure2 dPA_Int (>) (unsafe_zipWith (>))

eq, neq, le, lt, ge, gt :: Int -> Int -> Bool
eq = (==)
neq = (/=)
le = (<=)
lt = (<)
ge = (>=)
gt = (>)

plusV :: Int :-> Int :-> Int
{-# INLINE plusV #-}
plusV = closure2 dPA_Int (+) (unsafe_zipWith (+))

plus :: Int -> Int -> Int
plus = (+)

minusV :: Int :-> Int :-> Int
{-# INLINE minusV #-}
minusV = closure2 dPA_Int (-) (unsafe_zipWith (-))

minus :: Int -> Int -> Int
minus = (-)

multV :: Int :-> Int :-> Int
{-# INLINE multV #-}
multV = closure2 dPA_Int (*) (unsafe_zipWith (*))

mult :: Int -> Int -> Int
mult = (*)

intDivV :: Int :-> Int :-> Int
{-# INLINE intDivV #-}
intDivV = closure2 dPA_Int div (unsafe_zipWith div)

intDiv :: Int -> Int -> Int
intDiv = div

intModV :: Int :-> (Int :-> Int)
{-# INLINE intModV #-}
intModV = closure2 dPA_Int mod (unsafe_zipWith mod)

intMod :: Int -> Int -> Int
intMod = mod

intSquareRoot ::  Int -> Int
intSquareRoot = floor . sqrt . fromIntegral

intSquareRootV :: Int :-> Int
{-# INLINE intSquareRootV #-}
intSquareRootV = closure1  (intSquareRoot) (unsafe_map intSquareRoot)


intSumPA :: PArray Int :-> Int
{-# INLINE intSumPA #-}
intSumPA = closure1 (unsafe_fold (+) 0) (\_ -> error "Int.sumV lifted")


intSumP :: [:Int:] -> Int
{-# NOINLINE intSumP #-}
intSumP _ = 0

enumFromToPA :: Int :-> Int :->  PArray Int 
{-# INLINE enumFromToPA #-}
enumFromToPA = closure2 dPA_Int unsafe_enumFromTo
                        unsafe_enumFromTos

enumFromToP :: Int -> Int ->  [:Int:]
{-# NOINLINE enumFromToP #-}
enumFromToP n m = replicateP (n-m+1) 0

upToPA :: Int :-> PArray Int
{-# INLINE upToPA #-}
upToPA = closure1 upToPA_Int (\_ -> error "Int.upToPA lifted")

upToP :: Int -> [:Int:]
{-# NOINLINE upToP #-}
upToP n = enumFromToP 0 n
