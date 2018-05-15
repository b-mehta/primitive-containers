{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeFamilyDependencies #-}

{-# OPTIONS_GHC -O2 -Wall #-}
module Data.Internal
  ( Contiguous(..)
  ) where

import Prelude
import Control.Monad.ST (ST,runST)
import Data.Kind (Type)
import Data.Primitive
import GHC.Exts (ArrayArray#,Constraint)
import qualified Prelude as P

class Always a

instance Always a

class Contiguous (arr :: Type -> Type) where
  type family Mutable arr = (r :: Type -> Type -> Type) | r -> arr
  type family Element arr :: Type -> Constraint
  -- type family Unlifted arr :: (r :: Type -> TYPE 'UnliftedRep)
  -- type family MutableUnlifted arr :: (r :: Type -> Type -> TYPE 'UnliftedRep)
  empty :: arr a
  new :: Element arr b => Int -> ST s (Mutable arr s b)
  index :: Element arr b => arr b -> Int -> b
  indexM :: (Element arr b, Monad m) => arr b -> Int -> m b
  read :: Element arr b => Mutable arr s b -> Int -> ST s b
  write :: Element arr b => Mutable arr s b -> Int -> b -> ST s ()
  resize :: Element arr b => Mutable arr s b -> Int -> ST s (Mutable arr s b)
  size :: Element arr b => arr b -> Int
  unsafeFreeze :: Mutable arr s b -> ST s (arr b)
  copy :: Element arr b => Mutable arr s b -> Int -> arr b -> Int -> Int -> ST s ()
  foldr :: Element arr b => (b -> c -> c) -> c -> arr b -> c
  equals :: (Element arr b, Eq b) => arr b -> arr b -> Bool
  unlift :: arr b -> ArrayArray#
  lift :: ArrayArray# -> arr b
  map :: (Element arr b, Element arr c) => (b -> c) -> arr b -> arr c

instance Contiguous PrimArray where
  type Mutable PrimArray = MutablePrimArray
  type Element PrimArray = Prim
  empty = mempty
  new = newPrimArray
  index = indexPrimArray
  indexM arr ix = return (indexPrimArray arr ix)
  read = readPrimArray
  write = writePrimArray
  resize = resizeMutablePrimArray
  size = sizeofPrimArray
  unsafeFreeze = unsafeFreezePrimArray
  copy = copyPrimArray
  foldr = foldrPrimArray
  equals = (==)
  unlift = toArrayArray#
  lift = fromArrayArray#
  map = mapPrimArray

instance Contiguous Array where
  type Mutable Array = MutableArray
  type Element Array = Always
  empty = mempty
  new n = newArray n errorThunk
  index = indexArray
  indexM = indexArrayM
  read = readArray
  write = writeArray
  resize = resizeArray
  size = sizeofArray
  unsafeFreeze = unsafeFreezeArray
  copy = copyArray
  foldr = P.foldr
  equals = (==)
  unlift = toArrayArray#
  lift = fromArrayArray#
  map = fmap

instance Contiguous UnliftedArray where
  type Mutable UnliftedArray = MutableUnliftedArray
  type Element UnliftedArray = PrimUnlifted
  empty = emptyUnliftedArray
  new = unsafeNewUnliftedArray
  index = indexUnliftedArray
  indexM arr ix = return (indexUnliftedArray arr ix)
  read = readUnliftedArray
  write = writeUnliftedArray
  resize = resizeUnliftedArray
  size = sizeofUnliftedArray
  unsafeFreeze = unsafeFreezeUnliftedArray
  copy = copyUnliftedArray
  foldr = foldrUnliftedArray
  equals = (==)
  unlift = toArrayArray#
  lift = fromArrayArray#
  map = mapUnliftedArray

errorThunk :: a
errorThunk = error "Contiguous typeclass: unitialized element"

resizeArray :: Always a => MutableArray s a -> Int -> ST s (MutableArray s a)
resizeArray !src !sz = do
  dst <- newArray sz errorThunk
  copyMutableArray dst 0 src 0 (min sz (sizeofMutableArray src))
  return dst

resizeUnliftedArray :: PrimUnlifted a => MutableUnliftedArray s a -> Int -> ST s (MutableUnliftedArray s a)
resizeUnliftedArray !src !sz = do
  dst <- unsafeNewUnliftedArray sz
  copyMutableUnliftedArray dst 0 src 0 (min sz (sizeofMutableUnliftedArray src))
  return dst

emptyUnliftedArray :: UnliftedArray a
emptyUnliftedArray = runST (unsafeNewUnliftedArray 0 >>= unsafeFreezeUnliftedArray)
