{-# LANGUAGE OverloadedStrings #-}

module Data.Morpheus.Error.InputType
  ( expectedTypeAFoundB
  , typeMismatchMetaError
  , expectedEnumFoundB
  ) where

import           Data.Aeson                   (encode)
import           Data.ByteString.Lazy.Char8   (unpack)
import           Data.Morpheus.Error.Utils    (errorMessage)
import           Data.Morpheus.Types.Error    (GQLErrors, MetaError (..), MetaValidation)
import           Data.Morpheus.Types.JSType   (JSType)
import           Data.Morpheus.Types.MetaInfo (MetaInfo (..), Position)
import           Data.Text                    (Text)
import qualified Data.Text                    as T (concat, pack)

typeMismatchMetaError :: Position -> Text -> JSType -> MetaValidation a
typeMismatchMetaError pos expectedType' jsType = Left $ TypeMismatch meta jsType
  where
    meta = MetaInfo {typeName = expectedType', position = pos, key = ""}

expectedTypeAFoundB :: MetaInfo -> JSType -> GQLErrors
expectedTypeAFoundB meta found = errorMessage (position meta) text
  where
    text = T.concat ["Expected type \"", typeName meta, "\" found ", T.pack (unpack $ encode found), "."]

expectedEnumFoundB :: MetaInfo -> GQLErrors
expectedEnumFoundB meta = errorMessage (position meta) text
  where
    text = T.concat ["Expected type ", typeName meta, " found ", key meta, "."]