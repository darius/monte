{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
module Masque.SyntaxDiagrams where

import Control.Applicative (Applicative(..), Alternative(..),
                            (<$>), (<*), (*>))
import qualified Text.Parsec as P
import qualified Text.Parsec.IndentParsec.Token as IT
import qualified Text.Parsec.IndentParsec.Combinator as IPC

import Masque.ParseUtil
import Masque.FullSyntax

{-
HideExpr ::= Ap('HideExpr',
   Brackets("{", SepBy(NonTerminal('expr'), ';', fun='wrapSequence'), "}"))
-}
hideExpr = HideExpr <$> hideExpr_1
  where
    hideExpr_1 = IPC.betweenBlock (IT.symbol tokP "{") (IT.symbol tokP "}") hideExpr_1_2
    hideExpr_1_2 = (wrapSequence expr (IT.symbol tokP ";"))

{-
NounExpr ::= Ap('NounExpr', NonTerminal('name'))
-}
nounExpr = NounExpr <$> name

{-
name ::= Choice(0, "IDENTIFIER", Sigil("::", P('stringLiteral')))
-}
name = (IT.identifier tokP)
  <|> name_2
  where
    name_2 = ((IT.symbol tokP "::") *> stringLiteral )

{-
IntExpr ::= Ap('IntExpr', Choice(0, P('hexLiteral'), P('decLiteral')))
-}
intExpr = IntExpr <$> intExpr_1
  where
    intExpr_1 = hexLiteral
      <|> decLiteral

{-
decLiteral ::= Ap('(read :: String -> Integer)', P('digits'))
-}
decLiteral = (read :: String -> Integer) <$> digits

{-
digits ::= Ap("filter ((/=) '_')",
  Ap('(:)', P('digit'), Many(Choice(0, P('digit'), Char('_')))))
-}
digits = filter ((/=) '_') <$> digits_1
  where
    digits_1 = (:) <$> digit <*> digits_1_2
    digits_1_2 = P.many digits_1_2_1_1
    digits_1_2_1_1 = digit
      <|> (P.char '_')

{-
digit ::= OneOf('0123456789')
-}
digit = (P.oneOf "0123456789")

{-
hexLiteral ::= Ap('(read :: String -> Integer)',
  Ap('(:)', Char('0'),
    Ap('(:)', Choice(0, Char('x'), Char('X')), P('hexDigits'))))
-}
hexLiteral = (read :: String -> Integer) <$> hexLiteral_1
  where
    hexLiteral_1 = (:) <$> (P.char '0') <*> hexLiteral_1_2
    hexLiteral_1_2 = (:) <$> hexLiteral_1_2_1 <*> hexDigits
    hexLiteral_1_2_1 = (P.char 'x')
      <|> (P.char 'X')

{-
hexDigits ::= Ap("filter ((/=) '_')",
  Ap('(:)', P('hexDigit'), Many(Choice(0, P('hexDigit'), Char('_')))))
-}
hexDigits = filter ((/=) '_') <$> hexDigits_1
  where
    hexDigits_1 = (:) <$> hexDigit <*> hexDigits_1_2
    hexDigits_1_2 = P.many hexDigits_1_2_1_1
    hexDigits_1_2_1_1 = hexDigit
      <|> (P.char '_')

{-
hexDigit ::= OneOf('0123456789abcdefABCDEF')
-}
hexDigit = (P.oneOf "0123456789abcdefABCDEF")

{-
DoubleExpr ::= Ap('DoubleExpr', P('floatLiteral'))
-}
doubleExpr = DoubleExpr <$> floatLiteral

{-
floatLiteral ::= Ap('(read :: String -> Double)',
  Ap('(++)',
    P('digits'),
    Choice(0,
      Ap('(++)',
        Ap('(:)', Char('.'), P('digits')),
        Optional(P('floatExpn'), x='""')),
      P('floatExpn'))))
-}
floatLiteral = (read :: String -> Double) <$> floatLiteral_1
  where
    floatLiteral_1 = (++) <$> digits <*> floatLiteral_1_2
    floatLiteral_1_2 = floatLiteral_1_2_1
      <|> floatExpn
    floatLiteral_1_2_1 = (++) <$> floatLiteral_1_2_1_1 <*> floatLiteral_1_2_1_2
    floatLiteral_1_2_1_1 = (:) <$> (P.char '.') <*> digits
    floatLiteral_1_2_1_2 = P.option "" floatExpn

{-
floatExpn ::= Ap('(:)',
  OneOf("eE"),
  Ap('(++)',
    Optional(Ap('pure', OneOf('-+')), x='""'),
    P('digits')))
-}
floatExpn = (:) <$> floatExpn_1 <*> floatExpn_2
  where
    floatExpn_1 = (P.oneOf "eE")
    floatExpn_2 = (++) <$> floatExpn_2_1 <*> digits
    floatExpn_2_1 = P.option "" floatExpn_2_1_1
    floatExpn_2_1_1 = pure <$> floatExpn_2_1_1_1
    floatExpn_2_1_1_1 = (P.oneOf "-+")

{-
CharExpr ::= Ap('CharExpr',
  Brackets(Char("'"), P('charConstant'), Char("'")))
-}
charExpr = CharExpr <$> charExpr_1
  where
    charExpr_1 = IPC.between (P.char '\'') (P.char '\'') charConstant

{-
charConstant ::= Sigil(Many(String("\\\n")),
  Choice(0,
    NoneOf("'\\\t"),
    Sigil(Char("\\"),
      Choice(0,
        Ap('hexChar', Choice(0,
            Sigil(Char("U"), Count(8, P('hexDigit'))),
            Sigil(Char("u"), Count(4, P('hexDigit'))),
            Sigil(Char("x"), Count(2, P('hexDigit'))))),
        Ap('decodeSpecial', OneOf(r'''btnfr\'"'''))))))
-}
charConstant = (charConstant_1 *> charConstant_2 )
  where
    charConstant_1 = P.many charConstant_1_1_1
    charConstant_1_1_1 = P.string "\\\n"
    charConstant_2 = charConstant_2_1
      <|> charConstant_2_2
    charConstant_2_1 = (P.noneOf "\'\\\t")
    charConstant_2_2 = ((P.char '\\') *> charConstant_2_2_2 )
    charConstant_2_2_2 = charConstant_2_2_2_1
      <|> charConstant_2_2_2_2
    charConstant_2_2_2_1 = hexChar <$> charConstant_2_2_2_1_1
    charConstant_2_2_2_1_1 = charConstant_2_2_2_1_1_1
      <|> charConstant_2_2_2_1_1_2
      <|> charConstant_2_2_2_1_1_3
    charConstant_2_2_2_1_1_1 = ((P.char 'U') *> charConstant_2_2_2_1_1_1_2 )
    charConstant_2_2_2_1_1_1_2 = P.count 8 hexDigit
    charConstant_2_2_2_1_1_2 = ((P.char 'u') *> charConstant_2_2_2_1_1_2_2 )
    charConstant_2_2_2_1_1_2_2 = P.count 4 hexDigit
    charConstant_2_2_2_1_1_3 = ((P.char 'x') *> charConstant_2_2_2_1_1_3_2 )
    charConstant_2_2_2_1_1_3_2 = P.count 2 hexDigit
    charConstant_2_2_2_2 = decodeSpecial <$> charConstant_2_2_2_2_1
    charConstant_2_2_2_2_1 = (P.oneOf "btnfr\\\'\"")

{-
StrExpr ::= Ap('StrExpr', P('stringLiteral'))
-}
strExpr = StrExpr <$> stringLiteral

{-
stringLiteral ::= Sigil(Char('"'), ManyTill(P('charConstant'), Char('"')))
-}
stringLiteral = ((P.char '"') *> stringLiteral_2 )
  where
    stringLiteral_2 = P.manyTill charConstant (P.char '"')

{-
LiteralExpr ::= Choice(0,
       NonTerminal('StrExpr'),
       NonTerminal('IntExpr'),
       NonTerminal('DoubleExpr'),
       NonTerminal('CharExpr'))
-}
literalExpr = strExpr
  <|> intExpr
  <|> doubleExpr
  <|> charExpr
