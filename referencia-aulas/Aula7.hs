module Aula7 where

--um tipo (m :: *) que é um semigrupo e um elemento distinto mempty :: m
-- eh dito monoide, se a operacao (<>) satisfaz a seguinte lei:
-- associativa (nao importa a ordem) e tem um neutro!

-- for all x :: m. x <> mempty = x e mempty <> x = x

-- a) m = Int, (<>) = (+); mempty = 0
-- x + 0 = x 
-- 0 + x = x

-- a) m = Int, (<>) = (*); mempty = 1
-- x * 1 = x 
-- 1 * x = x

newtype Soma = Soma Int deriving Show

{-*
  class Semigroup m where
    (<>) :: m -> m -> m

    class Semigroup m => Monoid m where
        mempty :: m
*-}

instance Semigroup Soma where
    (Soma x) <> (Soma y) = Soma (x+y)

instance Monoid Soma where
    mempty = Soma 0

newtype Mult = Mult Int deriving Show

instance Semigroup Mult where
    (Mult x) <> (Mult y) = Mult (x*y)

instance Monoid Mult where
    mempty = Mult 1


newtype Concat = Concat String deriving Show

instance Semigroup Concat where
    (Concat x) <> (Concat y) = Concat (x++y)


newtype Xor = Xor Bool deriving Show
xor :: Bool -> Bool -> Bool
xor False False = False
xor True False = True
xor False True = True
xor True True = False

instance Semigroup Xor where
    (Xor x) <> (Xor y) = Xor (xor x y)

instance Monoid Xor where
    mempty = Xor False


newtype And =  And Bool deriving Show

instance Semigroup And where
     (And x) <> (And y) = And (x && y)

instance Monoid And where
    mempty = And True


-- como detectar oque nao eh um monoide/semigroup

-- Semigroup :
-- for all x :: m, y :: m, z :: m.   NEGAÇÃO ->      exists x :: m, y :: m, z :: m. 
-- (x <> y) <> z = x <> (y <> z)                     (x <> y) <> z /= x <> (y <> z)

-- 1) m = Int, (<>) = (-)
--   (3 - 5) - 2 = -4
--   3 - (5 - 2) = 0

{-*
-- functor eh um objeto da teoria das categorias
class Functor f where 
    fmap :: (a -> b) -> f a -> f b


Os functores assumem que f :: * -> *

data Maybe a = Nothing / Just a

instance Functor Maybe where 
    fmap f Nothing = Nothing 
    f :: a -> b
    f :: a
    f x :: b
    fmap f (Just x) = Just (f x)
*-}
