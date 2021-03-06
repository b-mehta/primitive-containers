{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}

{-# OPTIONS_GHC -O2 #-}
module Data.Diet.Map.Strict.Lifted.Lifted
  ( Map
  , singleton
  , lookup
    -- * List Conversion
  , fromList
  , fromListAppend
  , fromListN
  , fromListAppendN
  ) where

import Prelude hiding (lookup,map)

import Data.Semigroup (Semigroup)
import Data.Functor.Classes (Show2(..))
import Data.Primitive (Array)
import qualified GHC.Exts as E
import qualified Data.Semigroup as SG
import qualified Data.Diet.Map.Strict.Internal as I

newtype Map k v = Map (I.Map Array Array k v)

-- | /O(1)/ Create a diet map with a single element.
singleton :: Ord k
  => k -- ^ inclusive lower bound
  -> k -- ^ inclusive upper bound
  -> v -- ^ value
  -> Map k v
singleton lo hi v = Map (I.singleton lo hi v)

-- | /O(log n)/ Lookup the value at a key in the map.
lookup :: Ord k => k -> Map k v -> Maybe v
lookup a (Map s) = I.lookup a s

instance (Show k, Show v) => Show (Map k v) where
  showsPrec p (Map m) = I.showsPrec p m

instance (Eq k, Eq v) => Eq (Map k v) where
  Map x == Map y = I.equals x y

instance (Ord k, Enum k, Semigroup v, Eq v) => Semigroup (Map k v) where
  Map x <> Map y = Map (I.append x y)

instance (Ord k, Enum k, Semigroup v, Eq v) => Monoid (Map k v) where
  mempty = Map I.empty
  mappend = (SG.<>)
  mconcat = Map . I.concat . E.coerce

instance (Ord k, Enum k, Eq v) => E.IsList (Map k v) where
  type Item (Map k v) = (k,k,v)
  fromListN n = Map . I.fromListN n
  fromList = Map . I.fromList
  toList (Map s) = I.toList s

fromList :: (Ord k, Enum k, Eq v) => [(k,k,v)] -> Map k v
fromList = Map . I.fromList

fromListN :: (Ord k, Enum k, Eq v)
  => Int -- ^ expected size of resulting 'Map'
  -> [(k,k,v)] -- ^ key-value pairs
  -> Map k v
fromListN n = Map . I.fromListN n

fromListAppend :: (Ord k, Enum k, Semigroup v, Eq v) => [(k,k,v)] -> Map k v
fromListAppend = Map . I.fromListAppend

fromListAppendN :: (Ord k, Enum k, Semigroup v, Eq v)
  => Int -- ^ expected size of resulting 'Map'
  -> [(k,k,v)] -- ^ key-value pairs
  -> Map k v
fromListAppendN n = Map . I.fromListAppendN n
