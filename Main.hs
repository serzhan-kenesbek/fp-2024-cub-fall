module Main where

import Control.Monad (unless)
import Text.Printf (printf)

data Expr
  = Num Double
  | Sqrt Expr
  | Add Expr Expr
  | Sub Expr Expr
  | Mul Expr Expr
  | Div Expr Expr
  | Pow Expr Expr
  deriving (Eq)

instance Show Expr where
  show (Num n) = show n
  show (Sqrt e) = "sqrt(" ++ show e ++ ")"
  show (Add a b) = "(" ++ show a ++ " + " ++ show b ++ ")"
  show (Sub a b) = "(" ++ show a ++ " - " ++ show b ++ ")"
  show (Mul a b) = "(" ++ show a ++ " * " ++ show b ++ ")"
  show (Div a b) = "(" ++ show a ++ " / " ++ show b ++ ")"
  show (Pow a b) = "(" ++ show a ++ " ^ " ++ show b ++ ")"

data Error
  = DivByZero Expr Expr
  | NegativeSqrt Expr

instance Show Error where
  show (DivByZero a b) = "Division by zero: " ++ show a ++ " / " ++ show b
  show (NegativeSqrt e) = "Square root of negative number: " ++ show e

instance Eq Error where
  (DivByZero a1 b1) == (DivByZero a2 b2) = a1 == a2 && b1 == b2
  (NegativeSqrt a) == (NegativeSqrt b) = a == b
  _ == _ = False

eval :: Expr -> Either Error Double
eval (Num n) = Right n

eval (Sqrt e) =
  case eval e of
    Right x | x >= 0    -> Right (sqrt x)
            | otherwise -> Left (NegativeSqrt e)
    Left err -> Left err

eval (Add a b) = (+) <$> eval a <*> eval b
eval (Sub a b) = (-) <$> eval a <*> eval b
eval (Mul a b) = (*) <$> eval a <*> eval b

eval (Div a b) =
  case eval b of
    Right 0  -> Left (DivByZero a b)
    Right x  -> (/ x) <$> eval a
    Left err -> Left err

eval (Pow a b) =
  case (eval a, eval b) of
    (Right base, Right exp)
      | base < 0 && exp < 1 -> Left (NegativeSqrt (Pow a b))
      | otherwise           -> Right (base ** exp)
    (Left err, _) -> Left err
    (_, Left err) -> Left err

cases :: [(Expr, Either Error Double)]
cases =
  [ (Num 5, Right 5)
  , (Add (Num 2) (Num 3), Right 5)
  , (Sub (Num 10) (Num 4), Right 6)
  , (Mul (Num 3) (Num 3), Right 9)
  , (Div (Num 10) (Num 2), Right 5)
  , (Div (Num 1) (Num 0), Left (DivByZero (Num 1) (Num 0)))
  , (Sqrt (Num 16), Right 4)
  , (Sqrt (Num (-4)), Left (NegativeSqrt (Num (-4))))
  , (Pow (Num 2) (Num 3), Right 8)
  ]

test :: Expr -> Either Error Double -> IO ()
test expr expected =
  let result = eval expr in
  unless (result == expected) $ describeFailure result
  where
    describeFailure actual =
      printf "Test failed: eval(%s) should be %s but got %s\n" (show expr) (show expected) (show actual)

main :: IO ()
main = do
  mapM_ (uncurry test) cases
  putStrLn "Done"
