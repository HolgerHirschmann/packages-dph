-----------------------------------------------------------------------------
-- |
-- Module      : Data.Array.Parallel.Unlifted.Flat.ListLike
-- Copyright   : (c) [2001..2002] Manuel M T Chakravarty & Gabriele Keller
--		 (c) 2006         Manuel M T Chakravarty & Roman Leshchinskiy
-- License     : see libraries/base/LICENSE
-- 
-- Maintainer  : Manuel M T Chakravarty <chak@cse.unsw.edu.au>
-- Stability   : internal
-- Portability : portable
--
-- Description ---------------------------------------------------------------
--
--  Unlifted array versions of flat list-like combinators.
--
-- Todo ----------------------------------------------------------------------
--

module Data.Array.Parallel.Unlifted.Flat.ListLike (
  -- * List-like combinators
  mapU,	(+:+), filterU, nullU, lengthU, (!:),
  foldlU, foldl1U, scanlU, scanl1U, {-foldrU, foldr1U, scanrU, scanr1U,-}
  foldU, fold1U, scanU, scan1U,
  replicateU,
  takeU, dropU,	splitAtU, {-takeWhileU, dropWhileU, spanU, breakU,-}
--  lines, words, unlines, unwords,  -- is string processing really needed
  reverseU, andU, orU, anyU, allU, elemU, notElemU, {-lookupU,-}
  sumU, productU, maximumU, minimumU, 
  zipU, zip3U, zipWithU, zipWith3U, unzipU, unzip3U,
  enumFromToU, enumFromThenToU 
) where

import Data.Array.Parallel.Base (
  (:*:)(..), checkNotEmpty)
import Data.Array.Parallel.Unlifted.Flat.UArr (
  UA, UArr, lengthU, indexU, sliceU, extractU,
  zipU, unzipU) 
import Data.Array.Parallel.Unlifted.Flat.Loop (
  unitsU, replicateU, loopU)
import Data.Array.Parallel.Unlifted.Flat.Fusion (
  noAL, mapEFL, filterEFL, foldEFL, scanEFL,
  loopArr, loopAcc)

infixl 9 !:
infixr 5 +:+
infix  4 `elemU`, `notElemU`

here s = "Data.Array.Parallel.Unlifted.Flat.ListLike." ++ s

-- |List-like combinators
-- ----------------------

-- |Map a function over an array
--
mapU :: (UA e, UA e') => (e -> e') -> UArr e -> UArr e'
{-# INLINE mapU #-}
mapU f = loopArr . loopU (mapEFL f) noAL

-- |Concatenate two arrays
--
(+:+) :: UA e => UArr e -> UArr e -> UArr e
{-# INLINE (+:+) #-}
a1 +:+ a2 = loopArr $ loopU extract 0 (unitsU len)
  where
    len1 = lengthU a1
    len  = len1 + lengthU a2
    --
    extract i _ = (i + 1 :*: 
		   (Just $ if i < len1 then a1!:i else a2!:(i - len1)))

-- |Extract all elements from an array that meet the given predicate
--
filterU :: UA e => (e -> Bool) -> UArr e -> UArr e 
{-# INLINE filterU #-}
filterU p  = loopArr . loopU (filterEFL p) noAL

-- |Test whether the given array is empty
--
nullU :: UA e => UArr e -> Bool
nullU  = (== 0) . lengthU

-- lengthU is re-exported from UArr

-- |Array indexing
--
(!:) :: UA e => UArr e -> Int -> e
(!:) = indexU

-- |Array reduction proceeding from the left
--
foldlU :: UA a => (b -> a -> b) -> b -> UArr a -> b
{-# INLINE foldlU #-}
foldlU f z = loopAcc . loopU (foldEFL f) z

-- |Array reduction proceeding from the left for non-empty arrays
--
foldl1U :: UA a => (a -> a -> a) -> UArr a -> a
foldl1U f arr = checkNotEmpty (here "foldl1U") (lengthU arr) $
                foldlU f (arr !: 0) (sliceU arr 1 (lengthU arr - 1))

-- |Array reduction that requires an associative combination function with its
-- unit
--
foldU :: UA a => (a -> a -> a) -> a -> UArr a -> a
foldU = foldlU

-- |Reduction of a non-empty array which requires an associative combination
-- function
--
fold1U :: UA a => (a -> a -> a) -> UArr a -> a
fold1U = foldl1U

-- |Prefix scan proceedings from left to right
--
scanlU :: (UA a, UA b) => (b -> a -> b) -> b -> UArr a -> UArr b
{-# INLINE scanlU #-}
scanlU f z = loopArr . loopU (scanEFL f) z

-- |Prefix scan of a non-empty array proceeding from left to right
--
scanl1U :: UA a => (a -> a -> a) -> UArr a -> UArr a
scanl1U f arr = checkNotEmpty (here "scanl1U") (lengthU arr) $
                scanlU f (arr !: 0) (sliceU arr 1 (lengthU arr - 1))

-- |Prefix scan proceedings from left to right that needs an associative
-- combination function with its unit
--
scanU :: UA a => (a -> a -> a) -> a -> UArr a -> UArr a
scanU = scanlU

-- |Prefix scan of a non-empty array proceedings from left to right that needs
-- an associative combination function
--
scan1U :: UA a => (a -> a -> a) -> UArr a -> UArr a
scan1U = scanl1U

-- |Extract a prefix of an array
--
takeU :: UA e=> Int -> UArr e -> UArr e
{-# INLINE takeU #-}
takeU n a = extractU a 0 n

-- |Extract a suffix of an array
--
dropU :: UA e => Int -> UArr e -> UArr e
{-# INLINE dropU #-}
dropU n a = let len = lengthU a 
	    in
	    extractU a n (len - n)

-- |Split an array into two halves at the given index
--
splitAtU :: UA e => Int -> UArr e -> (UArr e, UArr e)
{-# INLINE splitAtU #-}
splitAtU n a = (takeU n a, dropU n a)

-- |Reverse the order of elements in an array
--
reverseU :: UA e => UArr e -> UArr e
reverseU a = loopArr $ loopU extract (len - 1) (unitsU len)
	     where
	       len = lengthU a
	       --
	       extract i _ = (i - 1 :*: (Just $ a!:i))

-- |
andU :: UArr Bool -> Bool
andU = foldU (&&) True

-- |
orU :: UArr Bool -> Bool
orU = foldU (||) False


-- |
allU :: UA e => (e -> Bool) -> UArr e -> Bool
{-# INLINE allU #-}
allU p = andU . mapU p

-- |
anyU :: UA e => (e -> Bool) -> UArr e -> Bool
{-# INLINE anyU #-}
anyU p =  orU . mapU p

-- |Determine whether the given element is in an array
--
elemU :: (Eq e, UA e) => e -> UArr e -> Bool
elemU e = anyU (== e)

-- |Negation of `elemU'
--
notElemU :: (Eq e, UA e) => e -> UArr e -> Bool
notElemU e = allU (/= e)

-- |Compute the sum of an array of numerals
--
sumU :: (Num e, UA e) => UArr e -> e
{-# INLINE sumU #-}
sumU = foldU (+) 0

-- |Compute the product of an array of numerals
--
productU :: (Num e, UA e) => UArr e -> e
{-# INLINE productU #-}
productU = foldU (*) 1

-- |Determine the maximum element in an array
--
maximumU :: (Ord e, UA e) => UArr e -> e
{-# INLINE maximumU #-}
maximumU = fold1U max

-- |Determine the minimum element in an array
--
minimumU :: (Ord e, UA e) => UArr e -> e
{-# INLINE minimumU #-}
minimumU = fold1U min

-- zipU is re-exported from UArr

-- |
zip3U :: (UA e1, UA e2, UA e3) 
      => UArr e1 -> UArr e2 -> UArr e3 -> UArr (e1 :*: e2 :*: e3)
{-# INLINE zip3U #-}
zip3U a1 a2 a3 = (a1 `zipU` a2) `zipU` a3

-- |
zipWithU :: (UA a, UA b, UA c) 
	 => (a -> b -> c) -> UArr a -> UArr b -> UArr c
{-# INLINE zipWithU #-}
zipWithU f a1 a2 = 
  loopArr $ loopU (mapEFL (\(x:*:y) -> f x y)) noAL (zipU a1 a2)

-- |
zipWith3U :: (UA a, UA b, UA c, UA d) 
          => (a -> b -> c -> d) -> UArr a -> UArr b -> UArr c -> UArr d
{-# INLINE zipWith3U #-}
zipWith3U f a1 a2 a3 = 
  loopArr $ loopU (mapEFL (\(x:*:y:*:z) -> f x y z)) noAL (zip3U a1 a2 a3)

-- unzipP is re-exported from UArr

-- |
unzip3U :: (UA e1, UA e2, UA e3) 
	=> UArr (e1 :*: e2 :*: e3) -> (UArr e1 :*: UArr e2 :*: UArr e3)
{-# INLINE unzip3U #-}
unzip3U a = let (a12 :*: a3) = unzipU a
		(a1  :*: a2) = unzipU a12
	    in
	    (a1 :*: a2 :*: a3)

-- |Enumeration functions
-- ----------------------

-- |Yield an enumerated array
--
enumFromToU :: (Enum e, UA e) => e -> e -> UArr e
{-# INLINE enumFromToU #-}
enumFromToU start = enumFromThenToU start (succ start)

-- |Yield an enumerated array using a specific step
--
enumFromThenToU :: (Enum e, UA e) => e -> e -> e -> UArr e
{-# INLINE enumFromThenToU #-}
enumFromThenToU start next end = 
  loopArr $ loopU step start' (unitsU len)
  where
    start' = fromEnum start
    next'  = fromEnum next
    end'   = fromEnum end
    delta  = next' - start'
    len    = abs (end' - start' + delta) `div` (abs delta)
    --
    step x _ = (x + delta :*: (Just $ toEnum x))
