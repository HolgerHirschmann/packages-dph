-----------------------------------------------------------------------------
-- |
-- Module      : Data.Array.Parallel.Unlifted.Flat.Basics
-- Copyright   : (c) [2001..2002] Manuel M T Chakravarty & Gabriele Keller
--		 (c) 2006/2007    Manuel M T Chakravarty & Roman Leshchinskiy
--		 (c) 2008         Manuel M T Chakravarty & Gabriele Keller & Roman Leshchinskiy
-- License     : see libraries/ndp/LICENSE
-- 
-- Maintainer  : Roman Leshchinskiy <rl@cse.unsw.edu.au>
-- Stability   : internal
-- Portability : portable
--
-- Description ---------------------------------------------------------------
--
--  Basic operations on parallel unlifted arrays.
--
-- Todo ----------------------------------------------------------------------
--

{-# LANGUAGE CPP #-}

#include "fusion-phases.h"

module Data.Array.Parallel.Unlifted.Parallel.Basics (
  lengthUP, nullUP, indexedUP,
  replicateUP, replicateEachUP, replicateEachUnbalancedUP, repeatUP
) where

import Data.Array.Parallel.Base (
  (:*:)(..), fstS, sndS, uncurryS)


import Data.Array.Parallel.Unlifted.Sequential (
  UA, UArr, (!:), unitsU, lengthU, newU,
  foldU, mapU, zipU, unzipU,
  indexedU, enumFromToU, replicateU, replicateEachU)
import Data.Array.Parallel.Unlifted.Distributed
import Data.Array.Parallel.Unlifted.Parallel.Combinators ( mapUP )
import Data.Array.Parallel.Unlifted.Parallel.Enum        ( enumFromToUP )
import Data.Array.Parallel.Unlifted.Parallel.Permute     ( bpermuteUP )

-- infixl 9 !:
-- infixr 5 +:+

-- some of the functions are exactly the same as the U version

-- |Test whether the given array is empty
--
nullUP :: UA e => UArr e -> Bool
nullUP  = (== 0) . lengthU

-- |Yield an empty array
--
emptyUP :: UA e => UArr e
emptyUP = newU 0 (const $ return ())

lengthUP :: UA e => UArr e -> Int
lengthUP = lengthU


-- |Yield an array where all elements contain the same value
--
replicateUP :: UA e => Int -> e -> UArr e
{-# INLINE_UP replicateUP #-}
replicateUP n e = joinD theGang balanced
                . mapD theGang (\n ->replicateU n e)
                $ splitLenD theGang n

repeatUP :: UA e => Int -> UArr e -> UArr e
{-# INLINE_UP repeatUP #-}
repeatUP n es = seq m
              . bpermuteUP es
              . mapUP (\i -> i `mod` m)
              $ enumFromToUP 0 (m*n-1)
  where
    m = lengthU es
    
-- | Expand every element in the argument array by the factor given in the 
--   corresponding array. The resulting array is unbalanced. 
--   TODO: do we need a balanced version? Will probably provide no performance benefit
--
replicateEachUnbalancedUP :: UA e => UArr Int -> UArr e -> UArr e
{-# INLINE_UP    replicateEachUnbalancedUP #-}
replicateEachUnbalancedUP  ns es = 
  joinD theGang unbalanced $ 
     mapD theGang ((uncurryS.uncurryS) replicateEachU) $ 
     mapD theGang (\t -> (((foldU (+) 0 $ fstS t) :*: fstS t) :*: sndS t)) $ 
     mapD theGang unzipU $ 
     splitD theGang unbalanced $ zipU ns es

replicateEachUP :: UA e => Int -> UArr Int -> UArr e -> UArr e
{-# INLINE_UP replicateEachUP #-}
replicateEachUP n lens xs = joinD theGang unbalanced
                          . mapD  theGang rep
                          . zipD (sndD dlens)
                          . splitAsD theGang (fstD dlens)
                          $ zipU lens xs
  where
    dlens = splitSegdLengthsD theGang n lens

    rep (n :*: ps) = let lens :*: xs = unzipU ps
                     in replicateEachU n lens xs

-- |Associate each element of the array with its index
--
indexedUP :: (DT e, UA e) => UArr e -> UArr (Int :*: e)
{-# INLINE_U indexedUP #-}
indexedUP = splitJoinD theGang indexedFn 
  where
    sizes  arr   = fstS $ scanD theGang (+) 0 $ lengthD arr
    indexedFn = \arr -> (zipWithD theGang (\o -> mapU (\xy -> (fstS xy + o :*: sndS xy))) (sizes arr) $ 
                        mapD theGang indexedU arr)




