const util = require('util');
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
    country: "MyCountry"
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
    country: ""
  }
};

const badForm = {
  address: {}
};


const log = a => { console.log(util.inspect(a, false, null)); };

const handleValidation = (v) => {
  switch(v.type) {
  case 'unprocessable':
    console.log('The input form failed to parse with the following errors:\n');
    break;

  case 'formErrors':
    console.log('The input form failed validation with the following errors:\n');
    break;

  case 'form':
    console.log('The input form was successfully processed:\n');
    break;

  default:
    console.log('The impossible happened!');
    console.log('We didn\'t handle all the potential error cases!');
    return;
  }
  log(v.value);
};

handleValidation(validateForm(badForm));
console.log(''); // drop some newlines in to make things look nice
handleValidation(validateForm(invalidForm));
console.log(''); // drop some newlines in to make things look nice
handleValidation(validateForm(validForm));
