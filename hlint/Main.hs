module Main
  ( main
  ) where

import Control.Monad
import Language.Haskell.HLint3 (hlint)
import System.Exit (exitFailure, exitSuccess)

main :: IO ()
main =
  do
    -- This 'putStrLn' is to format stack test output
    putStrLn ""
    let
      hlintArgs =
        [ "app"
        , "src"
        , "test"
        , "--hint=hlint/hlint.yml"
        ]
    hints <- hlint hlintArgs
    if null hints
    then exitSuccess
    else exitFailure
