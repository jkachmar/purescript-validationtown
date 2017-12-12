## PureScript Validation from JavaScript

A small demo to show how you can use [purescript-validation][1] from within
JavaScript, with a little help from [purescript-simple-json][2] and 
[purescript-variant][3].

### Setup

Ensure you have `node` and `npm` installed on your machine, then run the 
following from the terminal:

    git clone git@github.com:jkachmar/purescript-validationtown.git
    npm install

This will install the `purescript` compiler, the `pulp` build tool, and the
`psc-package` package manager to a local `node_modules` directory, as well as
fetch the necessary PureScript dependencies and compile the demo.

### What's Going On Here?

Some basic validation logic has been encoded in the 
[`ValidateForm` module](src/ValidateForm.purs) module that we'd like to call
from JavaScript with as little fuss as possible.

In order to safely call this function from JavaScript, we'll need a way to 
marshall the untyped JavaScript record into a typed PureScript record. The
untyped record is represented by `Foreign`, and the typed result of our 
marshalling is represented by the `UnvalidatedForm` type alias for a record with
the form structure we'll be validating.

Using [simple-json][2], this `Foreign` data can be parsed into an 
`UnvalidatedForm`, failing with an `unprocessable` error if the record is 
malformed.

This properly typed, but not necessarily valid, form can then be passed through
a series of validation functions built up using the [purescript-validation][1]
library. Note that the errors are expressed as `Variant`s and are collected in
`Array`s, which both have runtime representations that are relatively comfortable
to work with in JavaScript.

The result of the validation is then unpacked with `unV` and tagged with either
`formError` or `form` to indicate failure or success in validating the form,
respectively.

Finally, the `validateForm` function is uncurried using `mkFn1`, so that it may
be more naturally called from JavaScript. 

The [example JavaScript file](testValidation.js) included in this repository 
shows how the PureScript module can be imported. This example can be run with
`npm run demo`, or directly with `node testValidation.js`, and produces the 
following output:

```
The input form failed to parse with the following errors:

NonEmpty {
  value0: 
   ErrorAtProperty {
     value0: 'address',
     value1: 
      ErrorAtProperty {
        value0: 'address1',
        value1: TypeMismatch { value0: 'String', value1: 'Undefined' } } },
  value1: Nil {} }

The input form failed validation with the following errors:

[ { type: 'badEmail',
    value: 
     [ { type: 'emptyField', value: {} },
       { type: 'tooShort', value: {} } ] },
  { type: 'badUsername',
    value: 
     [ { type: 'emptyField', value: {} },
       { type: 'tooShort', value: {} } ] },
  { type: 'badPassword',
    value: 
     [ { type: 'emptyField', value: {} },
       { type: 'tooShort', value: {} } ] },
  { type: 'badAddress',
    value: 
     [ { type: 'emptyField', value: {} },
       { type: 'emptyField', value: {} },
       { type: 'emptyField', value: {} },
       { type: 'emptyField', value: {} },
       { type: 'emptyField', value: {} } ] } ]

The input form was successfully processed:

{ email: 'example@example.org',
  username: 'example',
  password: 'guest123456',
  address: 
   { address1: 'MyStreet',
     address2: 'MyApt',
     city: 'MyCity',
     zipCode: 'MyZipCode',
     country: 'MyCountry' } }
```

### Why Variant?

Normally errors encountered during Validation would be tagged with a sum type,
so why use a `Variant` here?

Well it turns out that `Variant`'s JavaScript runtime representation is a plain
JavaScript object with a `type` key for the `SProxy` tag, and a `value` key for
the value.

This makes it pretty straightforward to process the result of a validation
performed in PureScript from JavaScript without any encoding/decoding helper
functions.

[1]: https://github.com/purescript/purescript-validation/
[2]: https://github.com/justinwoo/purescript-simple-json
[3]: http://github.com/natefaubion/purescript-variant
