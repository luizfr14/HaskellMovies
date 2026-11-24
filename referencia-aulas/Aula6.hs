module Aula6 where 

--DRY : DONT REPEAT YOURSELF
-- Problema? Existem arvores que existem para o mesmo proposito, poluindo o codigo! Quebrando o DRY
-- data Arvore  = Nada | Folha | Ramo Arvore Arvore deriving Show

-- Polimorfismo parametrico: Eh a possibilidade de usar funcoes/estruturas parametrizadas por tipo.

-- Arvore a eh um tipo polimorfico (parecido com as listas [a])
-- a eh uma variavel que recebe APENAS TIPOS. (ou valores promovidos mas ignora essa parte!!!)
-- ArrayList<T>  o T eh uma variavel de tipo tal qual o "a" no Arvore a
data Arvore a = Nada | Folha a | Ramo a (Arvore a) (Arvore a) deriving Show

-- Mochila eh mais polimorfico que Arovre por conter 2 variaveis de tipo
data Mochila a b = Mochila a b deriving Show

-- a funcao foo é polimorfica pois sua entrada e saida possuem variaveis de tipo
foo :: (a,b) -> a
foo (x,y) = x


-- Polimorfismo as-hoc: é uma restrição ao polimorfismo parametrico.
-- induz comportamentos das funcoes de acordo com seu tipo 
data Curso = ADS | SI | CD | RH | LOG | GE | GP

--Show eh chamado de typeclass, o typeclass implementa o polimorfismo ad-hoc no haskell
instance Show Curso where 

    show ADS = "Curso de Cobol"
    show SI = "Curso de Designer"
    show CD = "Curso de Excel"
    show GE = "Curso de ..."
    show LOG = "Curso de caminhao"
    show GP = "Curso de navio"
    show RH = "Curso de abraco"

--instance Eq Curso where
--
--      ADS == SI = True
--      SI == CD = True
--      _ == _ = False

class Predicado a where 
    simnao :: a -> Bool

--Ensinando o compilador como o Predicado manipula Strings
instance Predicado String where 
    simnao "" = False
    simnao _ = True

instance Predicado Bool where
    -- funcao id basicamente retorna oq passou 
    simnao  = id

instance Predicado Char where 
    simnao 'L' = False
    simnao _ = True

-- Um tipo (m :: *) (monomorfico) com uma operacao binaria
-- (<>) :: m -> m -> m, eh chamado de Semigrupo se satisfaz a seguinte lei:
-- forall x :: m, y :: m, z :: m
-- (x <> y) <> z = x <> (y <> z)

-- Ex a) 
-- m = Int (<>) = (+)     isso eh obviamente verdade : (3 + 5) + 7 = 15 e 3 + (5 + 7) = 15

newtype Soma = Soma Int deriving Show

instance Semigroup Soma where
    (Soma x) <> (Soma y) = Soma (x+y)

-- Ex b)
-- m = Int  (<>) = (*)         (3*5) * 7 = 105    e    3 * (5*7) = 105

newtype Mult = Mult Int deriving Show

instance Semigroup Mult where
    (Mult x) <> (Mult y) = Mult (x*y)

-- Ex c)
-- m =  String (<>) = (++)      ("FATEC" <> "SANTOS") <> "RLZ" == "FATEC" <> ("SANTOS" <> "RLZ")

newtype Concat = Concat String deriving Show

instance Semigroup Concat where
    (Concat x) <> (Concat y) = Concat (x++y)

-- Ex d)
-- m = Bool (<>) = Xor
-- (Bool, Xor), eh um Semigrupo

newtype Xor = Xor Bool deriving Show

xor :: Bool -> Bool -> Bool
xor False False = False
xor True False = True
xor False True = True
xor True True = False

instance Semigroup Xor where
    (Xor x) <> (Xor y) = Xor (xor x y)

