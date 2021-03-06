{-# OPTIONS_GHC -fno-warn-type-defaults #-}
module Minicute.Parser.ParserSpec
  ( spec
  ) where

import Test.Hspec
import Test.Hspec.Megaparsec

import Control.Monad
import Minicute.Data.Tuple ( tupleUnzip2 )
import Minicute.Types.Minicute.Program
import Text.Megaparsec

import qualified Minicute.Parser.Parser as P

spec :: Spec
spec = do
  describe "programL parser" $ do
    forM_ testCases (\(name, content, result) -> programLTest name content result)

programLTest :: String -> String -> MainProgramL -> SpecWith (Arg Expectation)
programLTest name content result = do
  it ("parses " <> name <> " successfully") $ do
    parse P.programL "" content `shouldParse` result

type TestName = String
type TestContent = String
type TestResult = MainProgramL
type TestCase = (TestName, TestContent, TestResult)

testCases :: [TestCase]
testCases
  = simpleTestCases
    <> arithmeticOperatorTestCases
    <> constructorTestCases
    <> applicationTestCases
    <> supercombinatorTestCases
    <> letAndLetrecTestCases
    <> matchTestCases
    <> lambdaTestCases
  where
    simpleTestCases = fmap tupleUnzip2 (zip simpleLabels simpleTestTemplates)
    simpleLabels = fmap (("simple case" <>) . show) [0..]

simpleTestTemplates :: [(TestContent, TestResult)]
simpleTestTemplates
  = [ ( "f = 1"
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        ]
      )
    , ( "f = 1;"
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        ]
      )
    , ( "f=1;"
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        ]
      )
    , ( " f= 1;"
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        ]
      )
    , ( " f= 1 ;  "
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        ]
      )
    , ( "f = 1;\ng = 2"
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        , ( "g"
          , []
          , ELInteger 2
          )
        ]
      )
    , ( "f = 1  ;  \n g=2 ;"
      , ProgramL
        [ ( "f"
          , []
          , ELInteger 1
          )
        , ( "g"
          , []
          , ELInteger 2
          )
        ]
      )
    , ( "f = g;\ng = 2"
      , ProgramL
        [ ( "f"
          , []
          , ELVariable "g"
          )
        , ( "g"
          , []
          , ELInteger 2
          )
        ]
      )
    ]

arithmeticOperatorTestCases :: [TestCase]
arithmeticOperatorTestCases
  = [ ( "addition of two nums"
      , "f = 1 + 1"
      , ProgramL
        [ ( "f"
          , []
          , ELApplication2 (ELVariable "+") (ELInteger 1) (ELInteger 1)
          )
        ]
      )
    , ( "addition of num and var"
      , "f = 1 * g;\ng = 3"
      , ProgramL
        [ ( "f"
          , []
          , ELApplication2 (ELVariable "*") (ELInteger 1) (ELVariable "g")
          )
        , ( "g"
          , []
          , ELInteger 3
          )
        ]
      )
    , ( "operator precedence of + and *"
      , "f = 1 * 2 + 3"
      , ProgramL
        [ ( "f"
          , []
          , ELApplication2
            (ELVariable "+")
            (ELApplication2
              (ELVariable "*")
              (ELInteger 1)
              (ELInteger 2))
            (ELInteger 3)
          )
        ]
      )
    ]

constructorTestCases :: [TestCase]
constructorTestCases
  = [ ( "basic constructor"
      , "f = #C#{1;0};g = #C#{2;2}"
      , ProgramL
        [ ( "f"
          , []
          , ELConstructor 1 0
          )
        , ( "g"
          , []
          , ELConstructor 2 2
          )
        ]
      )
    , ( "constructor with arguments"
      , "f = #C#{1;1} 5;g = #C#{2;3} f"
      , ProgramL
        [ ( "f"
          , []
          , ELApplication (ELConstructor 1 1) (ELInteger 5)
          )
        , ( "g"
          , []
          , ELApplication (ELConstructor 2 3) (ELVariable "f")
          )
        ]
      )
    ]

applicationTestCases :: [TestCase]
applicationTestCases
  = [ ( "application of an integer"
      , "f = g 5"
      , ProgramL
        [ ( "f"
          , []
          , ELApplication (ELVariable "g") (ELInteger 5)
          )
        ]
      )
    , ( "application of a variable"
      , "f = g f"
      , ProgramL
        [ ( "f"
          , []
          , ELApplication (ELVariable "g") (ELVariable "f")
          )
        ]
      )
    ]

supercombinatorTestCases :: [TestCase]
supercombinatorTestCases
  = [ ( "supercombinator with an argument"
      , "f x = x"
      , ProgramL
        [ ( "f"
          , ["x"]
          , ELVariable "x"
          )
        ]
      )
    , ( "supercombinator with two argument"
      , "f x y = x y"
      , ProgramL
        [ ( "f"
          , ["x", "y"]
          , ELApplication (ELVariable "x") (ELVariable "y")
          )
        ]
      )
    ]

letAndLetrecTestCases :: [TestCase]
letAndLetrecTestCases
  = [ ( "let with a single definition"
      , "f = let x = 5 in x"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            NonRecursive
            [ ("x", ELInteger 5)
            ]
            (ELVariable "x")
          )
        ]
      )
    , ( "letrec with a single definition"
      , "f = letrec x = 5 in x"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            Recursive
            [ ("x", ELInteger 5)
            ]
            (ELVariable "x")
          )
        ]
      )
    , ( "let with multiple definitions"
      , "f = let x = 5; y = 4 in x + y"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            NonRecursive
            [ ("x", ELInteger 5)
            , ("y", ELInteger 4)
            ]
            (ELApplication2 (ELVariable "+") (ELVariable "x") (ELVariable "y"))
          )
        ]
      )
    , ( "letrec with multiple definitions"
      , "f = letrec x = 5; y = x + x; z = x * y in z"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            Recursive
            [ ("x", ELInteger 5)
            , ("y", ELApplication2 (ELVariable "+") (ELVariable "x") (ELVariable "x"))
            , ("z", ELApplication2 (ELVariable "*") (ELVariable "x") (ELVariable "y"))
            ]
            (ELVariable "z")
          )
        ]
      )
    , ( "let with nested let"
      , "f = let x = let k = 5; in k in x"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            NonRecursive
            [ ("x", ELLet NonRecursive [ ("k", ELInteger 5) ] (ELVariable "k"))
            ]
            (ELVariable "x")
          )
        ]
      )
    , ( "let with nested letrec"
      , "f = let x = letrec k = 5 in k; in x"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            NonRecursive
            [ ("x", ELLet Recursive [ ("k", ELInteger 5) ] (ELVariable "k"))
            ]
            (ELVariable "x")
          )
        ]
      )
    , ( "letrec with nested let"
      , "f = letrec x = let k = 5; in k in x"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            Recursive
            [ ("x", ELLet NonRecursive [ ("k", ELInteger 5) ] (ELVariable "k"))
            ]
            (ELVariable "x")
          )
        ]
      )
    , ( "letrec with nested letrec"
      , "f = letrec x = letrec k = 5; in k in x"
      , ProgramL
        [ ( "f"
          , []
          , ELLet
            Recursive
            [ ("x", ELLet Recursive [ ("k", ELInteger 5) ] (ELVariable "k"))
            ]
            (ELVariable "x")
          )
        ]
      )
    ]

matchTestCases :: [TestCase]
matchTestCases
  = [ ( "match with a single match case"
      , "f = match #C#{1;0} with <1> -> 5"
      , ProgramL
        [ ( "f"
          , []
          , ELMatch
            (ELConstructor 1 0)
            [ (1, [], ELInteger 5)
            ]
          )
        ]
      )
    , ( "match with multiple match cases"
      , "f = match #C#{2;0} with <1> -> 5; <2> -> 3; <4> -> g"
      , ProgramL
        [ ( "f"
          , []
          , ELMatch
            (ELConstructor 2 0)
            [ (1, [], ELInteger 5)
            , (2, [], ELInteger 3)
            , (4, [], ELVariable "g")
            ]
          )
        ]
      )
    , ( "match with arguments"
      , "f = match #C#{2;2} 5 4 with <1> x y -> x; <2> a b -> b"
      , ProgramL
        [ ( "f"
          , []
          , ELMatch
            (ELApplication2 (ELConstructor 2 2) (ELInteger 5) (ELInteger 4))
            [ (1, ["x", "y"], ELVariable "x")
            , (2, ["a", "b"], ELVariable "b")
            ]
          )
        ]
      )
    ]

lambdaTestCases :: [TestCase]
lambdaTestCases
  = [ ( "lambda with a single argument"
      , "f = \\x -> x"
      , ProgramL
        [ ( "f"
          , []
          , ELLambda
            ["x"]
            (ELVariable "x")
          )
        ]
      )
    , ( "lambda with multiple arguments"
      , "f = \\x y -> x + y"
      , ProgramL
        [ ( "f"
          , []
          , ELLambda
            ["x", "y"]
            (ELApplication2 (ELVariable "+") (ELVariable "x") (ELVariable "y"))
          )
        ]
      )
    , ( "lambda with nested lambda"
      , "f = \\x -> \\y -> x + y"
      , ProgramL
        [ ( "f"
          , []
          , ELLambda
            ["x"]
            ( ELLambda
              ["y"]
              (ELApplication2 (ELVariable "+") (ELVariable "x") (ELVariable "y"))
            )
          )
        ]
      )
    ]
