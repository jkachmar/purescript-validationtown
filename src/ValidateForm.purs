module ValidateForm where

import Prelude

import Control.Monad.Except (runExcept)
import Data.Array (singleton)
import Data.Bifunctor (bimap, lmap)
import Data.Either (Either(..))
import Data.Foreign (Foreign, MultipleErrors)
import Data.Function.Uncurried (Fn1, mkFn1)
import Data.String (length, null)
import Data.Validation.Semigroup (V, invalid, unV)
import Data.Variant (SProxy(..), Variant, inj)
import Simple.JSON (read)

--------------------------------------------------------------------------------
type FormError = Variant
  ( badEmail :: ValidationErrors
  , badUsername :: ValidationErrors
  , badPassword :: ValidationErrors
  , badAddress :: ValidationErrors
  )

type FormErrors = Array FormError

--------------------------------------------------------------------------------
type ValidationError = Variant
  ( emptyField :: Unit
  , tooShort   :: Unit -- The number of characters it should be greater to or equal than
  )

type ValidationErrors = Array ValidationError

--------------------------------------------------------------------------------
validateNonEmpty :: String -> V ValidationErrors String
validateNonEmpty input
  | null input = invalid [inj (SProxy :: SProxy "emptyField") unit]
  | otherwise  = pure input

validateMinimumLength :: Int -> String -> V ValidationErrors String
validateMinimumLength minLength input
  | length input < minLength = invalid [inj (SProxy :: SProxy "tooShort") unit]
  | otherwise = pure input

type UnvalidatedAddress =
  { address1 :: String
  , address2 :: String -- Maybe there's no second address line
  , city     :: String
  , zipCode  :: String
  , country  :: String
  }

type ValidatedAddress =
  { address1 :: Address1
  , address2 :: Address2
  , city     :: City
  , zipCode  :: ZipCode
  , country  :: Country
  }

newtype Address1 = Address1 String
newtype Address2 = Address2 String
newtype City     = City     String
newtype ZipCode  = ZipCode  String
newtype Country  = Country  String

validateAddress1 :: String -> V ValidationErrors Address1
validateAddress1 input = map Address1 $ validateNonEmpty input

validateAddress2 :: String -> V ValidationErrors Address2
validateAddress2 input = map Address2 $ validateNonEmpty input

validateCity :: String -> V ValidationErrors City
validateCity input = map City $ validateNonEmpty input

validateZipCode :: String -> V ValidationErrors ZipCode
validateZipCode input = map ZipCode $ validateNonEmpty input

validateCountry :: String -> V ValidationErrors Country
validateCountry input = map Country $ validateNonEmpty input

validateAddress :: UnvalidatedAddress -> V FormErrors ValidatedAddress
validateAddress {address1, address2, city, zipCode, country} =
  lmap (singleton <<< (inj $ SProxy :: SProxy "badAddress")) $
  { address1: _
  , address2: _
  , city: _
  , zipCode: _
  , country: _
  }
  <$> validateAddress1 address1
  <*> validateAddress2 address2
  <*> validateCity city
  <*> validateZipCode zipCode
  <*> validateCountry country

--------------------------------------------------------------------------------
type UnvalidatedForm =
  { email    :: String
  , username :: String
  , password :: String
  , address  :: UnvalidatedAddress
  }

type ValidatedForm =
  { email    :: Email
  , username :: Username
  , password :: Password
  , address  :: ValidatedAddress
  }

newtype Email    = Email    String
newtype Username = Username String
newtype Password = Password String

validateEmail :: String -> V FormErrors Email
validateEmail input = bimap (singleton <<< (inj $ SProxy :: SProxy "badEmail")) Email
  $  validateNonEmpty input
  *> validateMinimumLength 3 input

validateUsername :: String -> V FormErrors Username
validateUsername input = bimap (singleton <<< (inj $ SProxy :: SProxy "badUsername")) Username
  $  validateNonEmpty input
  *> validateMinimumLength 3 input

validatePassword :: String -> V FormErrors Password
validatePassword input = bimap (singleton <<< (inj $ SProxy :: SProxy "badPassword")) Password
  $  validateNonEmpty input
  *> validateMinimumLength 8 input

validateForm' :: UnvalidatedForm -> V FormErrors ValidatedForm
validateForm' {email, username, password, address} =
  { email: _
  , username: _
  , password: _
  , address: _
  }
  <$> validateEmail email
  <*> validateUsername username
  <*> validatePassword password
  <*> validateAddress address

--------------------------------------------------------------------------------
type ValidationResultType = Variant
  ( unprocessable :: MultipleErrors
  , formErrors    :: FormErrors
  , form          :: ValidatedForm
  )

newtype ValidationResult = ValidationResult ValidationResultType

validateForm :: Fn1 Foreign ValidationResult
validateForm = mkFn1 impl
  where
    impl :: Foreign -> ValidationResult
    impl jsForm =
      let (eForm :: Either MultipleErrors UnvalidatedForm) = runExcept $ read jsForm
      in case eForm of
        Left err ->
          ValidationResult (inj (SProxy :: SProxy "unprocessable") err)
        Right form ->
          ValidationResult $ unV
            (inj $ SProxy :: SProxy "formErrors")
            (inj $ SProxy :: SProxy "form")
            (validateForm' form)
