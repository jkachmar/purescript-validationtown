const { validateForm } = require('./output/ValidateForm');

const validForm = {
  email: "example@example.org",
  username: "example",
  password: "guest123456",
  address: {
    address1: "MyStreet",
    address2: "MyApt",
    city: "MyCity",
    zipCode: "MyZipCode",
    country: "MyCountry",
  }
};

const invalidForm = {
  email: "",
  username: "",
  password: "",
  address: {
    address1: "",
    address2: "",
    city: "",
    zipCode: "",
    country: "",
  }
};

const badForm = { email: false };

console.log(validateForm(validForm));

console.log(validateForm(invalidForm));

console.log(JSON.stringify(validateForm(badForm)));
