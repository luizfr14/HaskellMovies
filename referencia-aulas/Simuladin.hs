module Simuladin where


-- exercicio 1
data Categoria = Livro | Brinquedo | Escritorio deriving (Show, Eq)
data Produto = Produto {nome :: String, valor :: Double, categoria :: Categoria} deriving (Show)

-- lista fixa so pra n ficar criando toda vez que for rodar as funcoes
produtos :: [Produto]
produtos =
    let p1 = Produto "Haskell" 50.0 Livro
        p2 = Produto "Clean Code" 80.0 Livro
        p3 = Produto "Carrinho" 120.0 Brinquedo
        p4 = Produto "Boneca" 75.0 Brinquedo
        p5 = Produto "Caderno" 20.0 Escritorio
        p6 = Produto "Caneta" 5.0 Escritorio
    in [p1, p2, p3, p4, p5, p6]

extrairLivros :: [Produto] -> [Double]
extrairLivros ps = [valor p | p <- ps, categoria p == Livro]

maxValorBrinq :: [Produto] -> Double
maxValorBrinq ps = maximum [valor p | p <- ps, categoria p == Brinquedo]

countEscr :: [Produto] -> Int
countEscr ps = length [p | p <- ps, categoria p == Escritorio]



-- exercicio 2
data DeMorgan = DeMorgan Bool deriving Show

instance Semigroup DeMorgan where
    (DeMorgan a) <> (DeMorgan b) = DeMorgan (not a || b)

-- Náo é um semigrupo, pois quando aplicados o padrao de semigroup (x <> y) <> z = x <> (y <> z)
-- com todos sendo False, essa questao nao se cumpre automaticamente 



-- exercicio 3
data Tupla a = Tupla a a a deriving Show

-- a) 1 K (monomorfico)
-- b) 
instance Functor Tupla where
    fmap f (Tupla x y z) = Tupla (f x) (f y) (f z)

-- c) Tupla Bool
-- d) Tupla Char
-- e)
mostra :: Tupla a -> [a]
mostra (Tupla x y z) = [x,y,z]



-- exercicio 4
-- a)  (\x-> x) 7
--  7

-- b) (\x-> x + 2) 5
-- 7

-- c)  (\f x y-> f y x) k "Haskell" "Java"
-- = k "Java" "Haskell"
-- = (\x -> \y -> x) "Java" "Haskell"
-- = (\y -> "Java") "Haskell"
-- = "Java"

-- d)  (\x-> \y-> x + y) 4 6
-- = (\y -> 4 + x) 6
-- = 4 + 6
--- = 10

-- e) (\f-> \x-> f (f x)) (\x-> x + 1) 3
-- = (\x -> x + 1 ((\x -> x + 1)x) 3
-- = (x + 1) 4
-- = 5

-- f) (\x-> (\y-> x * y) 4) 5
-- =  (\y -> 5 * y) 4
-- = 5 * 4
-- = 20

-- g) i "Lambda"
-- = (\x-> x) "Lambda"
-- = "Lambda"

-- h)  k 10 20
-- = (\x-> \y-> x)10 20
-- = (\y -> 10) 20
-- = 20

-- i) s  k k "Haskell"
-- =  (\f-> \g-> \x-> f x (g x)) k k "Haskell"
-- = (\x-> \y-> x) "Haskell" ((\x-> \y-> x) "Haskell")
-- = "Haskell"

-- j) s (k (\x-> x + 1)) (k 4) 10
-- = (\f-> \g-> \x-> f x (g x))  (k (\x-> x + 1))  (k 4)  10
-- = (\g-> \x-> (k (\x-> x + 1)) x (g x))  (k 4)  10
-- = (k (\x-> x + 1)) 10 ((k 4) 10)
-- = ((\x-> \y-> x) (\x-> x + 1)) 10 (((\x-> \y-> x) 4) 10) 
-- = (\y-> (\x-> x + 1)) 10 (((\x-> \y-> x) 4) 10) 
-- = (\y-> (\x-> x + 1)) 10 ((\y-> 4) 10) 
-- = (\y-> (\x-> x + 1)) 10 4
-- = (\x-> x + 1) 4
-- =5




-- exercicio 5

-- a) a -> b -> a
-- b) Bool
-- c) Num a => a
-- d) (Bool, String, Char, String)
-- e) [Char]
-- f) [a] -> [a]




-- exercicio 6

-- a) f1 :: (a,b,c)-> (c,b,b,a)
--    f1 (x,y,z) = (z,y,y,x)

-- b) f2 :: a -> ((),a,())
--    f2 a = ((),a,())

-- c) f3 :: Maybe a -> Either a ()
--    f3 (Just x) =  Left x
--    f3 Nothig = Rigth ()

-- d) f4 :: (a-> b)-> a -> b
--    f4 x y = x y

-- e) f5 :: (a -> b) -> (c,a,()) -> (c,b,())
-- f5 g = (\(c, a, ()) -> (c, g a, ()))