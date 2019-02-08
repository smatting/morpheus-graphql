{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators , ScopedTypeVariables, DefaultSignatures, FlexibleContexts, FlexibleInstances #-}

module Data.GraphqlHS.Generics.GQLArgs
    ( GQLArgs(..)
    )
where

import           Prelude                 hiding ( lookup )
import           Data.Text                      ( Text(..)
                                                , pack
                                                )
import           Data.Map                       ( lookup )
import           GHC.Generics
import           Data.GraphqlHS.Types.Types     ( Object
                                                , GQLValue(..)
                                                , Head(..)
                                                , Eval(..)
                                                , (::->)(Some, None)
                                                , MetaInfo(..)
                                                , Arg(..)
                                                , GQLPrimitive(..)
                                                )
import           Data.Proxy                     ( Proxy(..) )
import           Data.Data                      ( Typeable
                                                , Data
                                                )
import           Data.GraphqlHS.Types.Introspection
                                                ( GQL__InputValue(..)
                                                , createInputValue
                                                )
import           Data.GraphqlHS.Generics.TypeRep
                                                ( ArgsMeta(..) )
import           Data.GraphqlHS.ErrorMessage    ( requiredArgument )

fixProxy :: (a -> f a) -> f a
fixProxy f = f undefined

initMeta = MetaInfo { className = "", cons = "", key = "" }

class InputValue a where
    decode :: GQLPrimitive -> a

instance InputValue Text where
    decode  (JSString x) = x

instance InputValue Bool where
    decode  (JSBool x) = x

class GToArgs f where
    gToArgs :: MetaInfo -> Head -> Eval (f a)

instance GToArgs U1  where
    gToArgs _ _ = pure U1

instance InputValue a => GToArgs  (K1 i a)  where
    gToArgs meta (Head args) =
        case lookup (key meta) args of
            Nothing -> Fail $ requiredArgument meta
            Just (ArgValue x) -> Val $ K1 $ (decode x)

instance (Selector c, GToArgs f ) => GToArgs (M1 S c f) where
    gToArgs meta gql = fixProxy (\x -> M1 <$> gToArgs (meta{ key = pack $ selName x}) gql)

instance (Datatype c, GToArgs f)  => GToArgs (M1 D c f)  where
    gToArgs meta gql  = fixProxy(\x -> M1 <$> gToArgs (meta {className = pack $ datatypeName x}) gql)

instance GToArgs f  => GToArgs (M1 C c f)  where
    gToArgs meta gql  = M1 <$> gToArgs meta gql

instance (GToArgs f , GToArgs g ) => GToArgs (f :*: g)  where
    gToArgs meta gql = (:*:) <$> gToArgs meta gql <*> gToArgs meta gql

class GQLArgs p where
    fromArgs :: Head -> (Maybe p) -> Eval p
    default fromArgs :: ( Show p , Generic p, Data p , GToArgs (Rep p) ) => Head -> (Maybe p) -> Eval p
    fromArgs args _ = to <$> gToArgs initMeta args

    argsMeta :: Proxy p -> [GQL__InputValue]
    default argsMeta :: (Show p, ArgsMeta (Rep p) , Typeable p) => Proxy p -> [GQL__InputValue]
    argsMeta _ = map (\(x,y)-> createInputValue x y) $ getMeta (Proxy :: Proxy (Rep p))

instance  GQLArgs Text where
    fromArgs _ (Just t) = Val t
    fromArgs _ _ = Val "Nothing found"
    argsMeta _ = []

instance  GQLArgs Bool where
    fromArgs _ (Just t) = Val t
    fromArgs _ _ = Val False
    argsMeta _ = [GQL__InputValue { name = "Boolean", description = "", _type = Nothing, defaultValue = "" }]

instance  GQLArgs () where
    fromArgs _ _ = Val ()
    argsMeta _ = []
