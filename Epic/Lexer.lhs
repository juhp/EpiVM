> module Epic.Lexer where

> import Data.Char

> import Epic.Language

> type LineNumber = Int
> type P a = String -> String -> LineNumber -> Result a
 
> getLineNo :: P LineNumber
> getLineNo = \s fn l -> Success l
 
> getFileName :: P String
> getFileName = \s fn l -> Success fn
 
> getContent :: P String
> getContent = \s fn l -> Success s
 
> thenP :: P a -> (a -> P b) -> P b
> m `thenP` k = \s fn l ->
>    case m s fn l of
>        Success a -> k a s fn l
>        Failure e f ln -> Failure e f ln
 
> returnP :: a -> P a
> returnP a = \s fn l -> Success a
> 
> failP :: String -> P a
> failP err = \s fn l -> Failure err fn l
 
> catchP :: P a -> (String -> P a) -> P a
> catchP m k = \s fn l ->
>    case m s fn l of
>       Success a -> Success a
>       Failure e f ln -> k e s fn l
 
> happyError :: P a
> happyError = reportError "Parse error"
 
> reportError :: String -> P a
> reportError err = getFileName `thenP` \fn ->
>                   getLineNo `thenP` \line ->
>                   getContent `thenP` \content ->
>                       failP (fn ++ ":" ++ show line ++ ":" ++ err ++ " at " ++ take 40 content ++ " ...")
 
> data Token 
>       = TokenName Name
>       | TokenString String
>       | TokenInt Int
>       | TokenFloat Double
>       | TokenBigInt Integer
>       | TokenBigFloat Double
>       | TokenChar Char
>       | TokenBool Bool
>       | TokenIntType
>       | TokenBigIntType
>       | TokenCharType
>       | TokenBoolType
>       | TokenFloatType
>       | TokenBigFloatType
>       | TokenStringType
>       | TokenPtrType
>       | TokenUnitType
>       | TokenAnyType
>       | TokenDataType
>       | TokenTyCType
>       | TokenTyLinear
>       | TokenTyEval
>       | TokenFunType
>       | TokenForeign
>       | TokenCInclude
>       | TokenLink
>       | TokenInline
>       | TokenOB
>       | TokenCB
>       | TokenOCB
>       | TokenCCB
>       | TokenOSB
>       | TokenCSB
>       | TokenPlus
>       | TokenMinus
>       | TokenTimes
>       | TokenDivide
>       | TokenMod
>       | TokenFPlus
>       | TokenFMinus
>       | TokenFTimes
>       | TokenFDivide
>       | TokenEquals
>       | TokenEQ
>       | TokenGE
>       | TokenLE
>       | TokenGT
>       | TokenLT
>       | TokenFEQ
>       | TokenFGE
>       | TokenFLE
>       | TokenFGT
>       | TokenFLT
>       | TokenShL
>       | TokenShR
>       | TokenArrow
>       | TokenColon
>       | TokenUnit
>       | TokenCon
>       | TokenDefault
>       | TokenExport
>       | TokenCType
>       | TokenLet
>       | TokenCase
>       | TokenOf
>       | TokenIf
>       | TokenThen
>       | TokenElse
>       | TokenWhile
>       | TokenUnused
>       | TokenIn
>       | TokenLazy
>       | TokenPar
>       | TokenStrict
>       | TokenEffect
>       | TokenError
>       | TokenImpossible
>       | TokenProj
>       | TokenSemi
>       | TokenComma
>       | TokenBar
>       | TokenLam
>       | TokenDot
>       | TokenExtern
>       | TokenMemory
>       | TokenFixed
>       | TokenGrowable
>       | TokenInclude
>       | TokenEOF
>  deriving (Show, Eq)
> 
> 
> lexer :: (Token -> P a) -> P a
> lexer cont [] = cont TokenEOF []
> lexer cont ('\n':cs) = \fn line -> lexer cont cs fn (line+1)
> lexer cont (c:cs)
>       | isSpace c = \fn line -> lexer cont cs fn line
>       | isAlpha c = lexVar cont (c:cs)
>       | isDigit c = lexNum cont (c:cs)
>       | c == '_' = lexVar cont (c:cs)
> lexer cont ('"':cs) = lexString cont cs
> lexer cont ('\'':cs) = lexChar cont cs
> lexer cont ('{':'-':cs) = lexerEatComment 0 cont cs
> lexer cont ('-':'-':cs) = lexerEatToNewline cont cs
> lexer cont ('-':'>':cs) = cont TokenArrow cs
> lexer cont ('(':cs) = cont TokenOB cs
> lexer cont (')':cs) = cont TokenCB cs
> lexer cont ('{':cs) = cont TokenOCB cs
> lexer cont ('}':cs) = cont TokenCCB cs
> lexer cont ('[':cs) = cont TokenOSB cs
> lexer cont (']':cs) = cont TokenCSB cs
> lexer cont ('+':'.':cs) = cont TokenFPlus cs
> lexer cont ('-':'.':cs) = cont TokenFMinus cs
> lexer cont ('*':'.':cs) = cont TokenFTimes cs
> lexer cont ('/':'.':cs) = cont TokenFDivide cs
> lexer cont ('+':cs) = cont TokenPlus cs
> lexer cont ('-':cs) = cont TokenMinus cs
> lexer cont ('*':cs) = cont TokenTimes cs
> lexer cont ('/':cs) = cont TokenDivide cs
> lexer cont ('=':'=':'.':cs) = cont TokenFEQ cs
> lexer cont ('>':'=':'.':cs) = cont TokenFGE cs
> lexer cont ('<':'=':'.':cs) = cont TokenFLE cs
> lexer cont ('>':'.':cs) = cont TokenFGT cs
> lexer cont ('<':'.':cs) = cont TokenFLT cs
> lexer cont ('=':'=':cs) = cont TokenEQ cs
> lexer cont ('>':'=':cs) = cont TokenGE cs
> lexer cont ('<':'=':cs) = cont TokenLE cs
> lexer cont ('<':'<':cs) = cont TokenShL cs
> lexer cont ('>':'>':cs) = cont TokenShR cs
> lexer cont ('>':cs) = cont TokenGT cs
> lexer cont ('<':cs) = cont TokenLT cs
> lexer cont ('=':cs) = cont TokenEquals cs
> lexer cont (':':cs) = cont TokenColon cs
> lexer cont ('!':cs) = cont TokenProj cs
> lexer cont (';':cs) = cont TokenSemi cs
> lexer cont (',':cs) = cont TokenComma cs
> lexer cont ('|':cs) = cont TokenBar cs
> lexer cont ('.':cs) = cont TokenDot cs
> lexer cont ('\\':cs) = cont TokenLam cs
> lexer cont ('%':c:cs) | isAlpha c = lexSpecial cont (c:cs)
> lexer cont ('%':cs) = cont TokenMod cs
> lexer cont (c:cs) = lexError c cs
 
> lexError c s f l = failP (show l ++ ": Unrecognised token '" ++ [c] ++ "'\n") s f l

> lexerEatComment nls cont ('-':'}':cs)
>     = \fn line -> lexer cont cs fn (line+nls)
> lexerEatComment nls cont ('\n':cs) = lexerEatComment (nls+1) cont cs
> lexerEatComment nls cont (c:cs) = lexerEatComment nls cont cs
> 
> lexerEatToNewline cont ('\n':cs)
>    = \fn line -> lexer cont cs fn (line+1)
> lexerEatToNewline cont (c:cs) = lexerEatToNewline cont cs

> lexNum cont cs = case readNum cs of
>                     (num,'L':rest,isreal) ->
>                         cont (tok True num isreal) rest
>                     (num,rest,isreal) ->
>                         cont (tok False num isreal) rest
>   where tok False num isreal | isreal = TokenFloat (read num)
>                              | otherwise = TokenInt (read num)
>         tok True num isreal | isreal = TokenBigFloat (read num)
>                             | otherwise = TokenBigInt (read num)

> readNum :: String -> (String,String,Bool)
> readNum x = rn' False "" x
>   where rn' dot acc [] = (acc,[],dot)
>         rn' False acc ('.':xs) | head xs /= '.' = rn' True (acc++".") xs
>         rn' dot acc (x:xs) | isDigit x = rn' dot (acc++[x]) xs
>         rn' dot acc ('e':'+':xs) = rn' True (acc++"e+") xs
>         rn' dot acc ('e':'-':xs) = rn' True (acc++"e-") xs
>         rn' dot acc ('e':xs) = rn' True (acc++"e") xs
>         rn' dot acc xs = (acc,xs,dot)

> lexString cont cs =
>    \fn line ->
>    case getstr cs of
>       Just (str,rest,nls) -> cont (TokenString str) rest fn (nls+line)
>       Nothing -> failP (fn++":"++show line++":Unterminated string contant")
>                     cs fn line

> lexChar cont cs =
>    \fn line ->
>    case getchar cs of
>       Just (str,rest) -> cont (TokenChar str) rest fn line
>       Nothing -> 
>           failP (fn++":"++show line++":Unterminated character constant")
>                        cs fn line

> isAllowed c = isAlpha c || isDigit c || c `elem` "_\'?#"

> lexVar cont cs =
>    case span isAllowed cs of
> -- Keywords
>       ("Default",rest) -> cont TokenDefault rest
> -- Types
>       ("Int",rest) -> cont TokenIntType rest
>       ("Char",rest) -> cont TokenCharType rest
>       ("Bool",rest) -> cont TokenBoolType rest
>       ("Float",rest) -> cont TokenFloatType rest
>       ("BigInt",rest) -> cont TokenBigIntType rest
>       ("BigFloat",rest) -> cont TokenBigFloatType rest
>       ("String",rest) -> cont TokenStringType rest
>       ("Ptr",rest) -> cont TokenPtrType rest
>       ("Unit",rest) -> cont TokenUnitType rest
>       ("Data",rest) -> cont TokenDataType rest
>       ("CType",rest) -> cont TokenTyCType rest
>       ("Linear",rest) -> cont TokenTyLinear rest
>       ("Eval",rest) -> cont TokenTyEval rest
>       ("Fun",rest) -> cont TokenFunType rest
>       ("Any",rest) -> cont TokenAnyType rest
> -- values
>       ("unit",rest) -> cont TokenUnit rest
>       ("Con",rest) -> cont TokenCon rest
>       ("true",rest) -> cont (TokenBool True) rest
>       ("false",rest) -> cont (TokenBool False) rest
> -- expressions
>       ("let",rest) -> cont TokenLet rest
>       ("case",rest) -> cont TokenCase rest
>       ("of",rest) -> cont TokenOf rest
>       ("if",rest) -> cont TokenIf rest
>       ("then",rest) -> cont TokenThen rest
>       ("else",rest) -> cont TokenElse rest
>       ("in",rest) -> cont TokenIn rest
>       ("lazy",rest) -> cont TokenLazy rest
>       ("par",rest) -> cont TokenPar rest
>       ("error",rest) -> cont TokenError rest
>       ("impossible",rest) -> cont TokenImpossible rest
>       ("foreign",rest) -> cont TokenForeign rest
> -- declarations
>       ("export",rest) -> cont TokenExport rest
>       ("ctype",rest) -> cont TokenCType rest
>       ("extern",rest) -> cont TokenExtern rest
>       ("include",rest) -> cont TokenInclude rest
>       (var,rest)   -> cont (mkname var) rest
 
> lexSpecial cont cs =
>     case span isAllowed cs of
>       ("include",rest) -> cont TokenCInclude rest
>       ("link",rest) -> cont TokenLink rest
>       ("inline",rest) -> cont TokenInline rest
>       ("effect",rest) -> cont TokenEffect rest
>       ("strict",rest) -> cont TokenStrict rest
>       ("while",rest) -> cont TokenWhile rest
>       ("memory",rest) -> cont TokenMemory rest
>       ("fixed",rest) -> cont TokenFixed rest
>       ("growable",rest) -> cont TokenGrowable rest
>       ("unused", rest) -> cont TokenUnused rest
>       (thing,rest) -> cont TokenMod (thing++rest)
 
> mkname :: String -> Token
> mkname c = TokenName (UN c)

> getstr :: String -> Maybe (String,String,Int)
> getstr cs = case getstr' "" cs 0 of
>                Just (str,rest,nls) -> Just (reverse str,rest,nls)
>                _ -> Nothing
> getstr' acc ('\"':xs) = \nl -> Just (acc,xs,nl)
> getstr' acc ('\\':'n':xs) = getstr' ('\n':acc) xs -- Newline
> getstr' acc ('\\':'r':xs) = getstr' ('\r':acc) xs -- CR
> getstr' acc ('\\':'t':xs) = getstr' ('\t':acc) xs -- Tab
> getstr' acc ('\\':'b':xs) = getstr' ('\b':acc) xs -- Backspace
> getstr' acc ('\\':'a':xs) = getstr' ('\a':acc) xs -- Alert
> getstr' acc ('\\':'f':xs) = getstr' ('\f':acc) xs -- Formfeed
> getstr' acc ('\\':'0':xs) = getstr' ('\0':acc) xs -- null
> getstr' acc ('\\':x:xs) = getstr' (x:acc) xs -- Literal
> getstr' acc ('\n':xs) = \nl ->getstr' ('\n':acc) xs (nl+1) -- Count the newline
> getstr' acc (x:xs) = getstr' (x:acc) xs
> getstr' _ _ = \nl -> Nothing
 
> getchar :: String -> Maybe (Char,String)
> getchar ('\\':'n':'\'':xs) = Just ('\n',xs) -- Newline
> getchar ('\\':'r':'\'':xs) = Just ('\r',xs) -- CR
> getchar ('\\':'t':'\'':xs) = Just ('\t',xs) -- Tab
> getchar ('\\':'b':'\'':xs) = Just ('\b',xs) -- Backspace
> getchar ('\\':'a':'\'':xs) = Just ('\a',xs) -- Alert
> getchar ('\\':'f':'\'':xs) = Just ('\f',xs) -- Formfeed
> getchar ('\\':'0':'\'':xs) = Just ('\0',xs) -- null
> getchar ('\\':x:'\'':xs) = Just (x,xs) -- Literal
> getchar (x:'\'':xs) = Just (x,xs)
> getchar _ = Nothing
